// golem-connectd — the desktop half of Golem.
//
// Speaks KDE Connect protocol v8 directly instead of going through
// kdeconnectd, because remote input on this compositor cannot work through
// kdeconnectd at all: it needs org.freedesktop.portal.RemoteDesktop, and
// xdg-desktop-portal-hyprland does not implement it. Injecting through the
// wlroots virtual-pointer/virtual-keyboard protocols needs no portal and no
// root.
//
// Protocol notes that are easy to get wrong (see Golem's CLAUDE.md):
//   * TLS roles are inverted — whoever RECEIVES the UDP broadcast opens the
//     TCP connection, sends its identity in plaintext, and is the TLS SERVER.
//   * v8 sends a minimal identity pre-TLS and the full one over the encrypted
//     channel immediately after the handshake.
//   * Every identity packet needs a non-empty deviceName, including the UDP
//     one the spec shows without it.

mod crypto;
mod gamepad;
mod input;
mod mirror;
mod mousepad;
mod packet;
mod uinput;

use anyhow::{Context, Result};
use packet::{
    NetworkPacket, TYPE_GAMEPAD, TYPE_IDENTITY, TYPE_MIRROR, TYPE_MIRROR_STATE,
    TYPE_MOUSEPAD_REQUEST, TYPE_PAIR, TYPE_PING,
};
use std::collections::HashMap;
use std::net::SocketAddr;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream, UdpSocket};

const DISCOVERY_PORT: u16 = 1716;
const TCP_PORT_MIN: u16 = 1716;
const TCP_PORT_MAX: u16 = 1764;
const PROTOCOL_VERSION: i64 = 8;

fn state_dir() -> PathBuf {
    std::env::var_os("XDG_DATA_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            PathBuf::from(std::env::var_os("HOME").expect("HOME unset")).join(".local/share")
        })
        .join("golem-connectd")
}

/// v8 requires 32-38 alphanumeric characters: a UUIDv4 with the hyphens removed.
fn generate_device_id() -> String {
    use rand::Rng;
    let mut rng = rand::thread_rng();
    (0..32)
        .map(|_| {
            let n: u8 = rng.gen_range(0..16);
            std::char::from_digit(n as u32, 16).unwrap()
        })
        .collect()
}

fn load_device_id(dir: &std::path::Path) -> Result<String> {
    let path = dir.join("device_id");
    if let Ok(existing) = std::fs::read_to_string(&path) {
        let trimmed = existing.trim().to_string();
        if trimmed.len() >= 32 && trimmed.chars().all(|c| c.is_ascii_alphanumeric()) {
            return Ok(trimmed);
        }
    }
    let id = generate_device_id();
    std::fs::create_dir_all(dir)?;
    std::fs::write(&path, &id)?;
    Ok(id)
}

/// Protocol rule: 1-32 chars, none of `"',;:.!?()[]<>`.
fn sanitize_name(raw: &str) -> String {
    raw.chars()
        .filter(|c| !"\"',;:.!?()[]<>".contains(*c))
        .collect::<String>()
        .trim()
        .chars()
        .take(32)
        .collect()
}

struct Config {
    device_id: String,
    device_name: String,
    identity: crypto::Identity,
    tcp_port: u16,
    trusted: Mutex<HashMap<String, Vec<u8>>>,
    trusted_path: PathBuf,
    input_tx: std::sync::mpsc::Sender<input::InputEvent>,
    /// `None` when /dev/uinput is not writable. The capability is then not
    /// announced at all, so the phone can grey the gamepad out rather than
    /// offering a control that silently goes nowhere.
    gamepad_tx: Option<std::sync::mpsc::Sender<Vec<gamepad::GamepadEvent>>>,
    /// False when scrcpy or adb is missing. The capability is then withheld,
    /// so the phone hides its Mirror button instead of offering one that
    /// cannot work — the same honesty the gamepad applies to /dev/uinput.
    can_mirror: bool,
}

impl Config {
    fn incoming_capabilities(&self) -> Vec<&'static str> {
        let mut caps = vec![TYPE_PING, TYPE_MOUSEPAD_REQUEST];
        if self.gamepad_tx.is_some() {
            caps.push(TYPE_GAMEPAD);
        }
        if self.can_mirror {
            caps.push(TYPE_MIRROR);
        }
        caps
    }
    fn outgoing_capabilities(&self) -> Vec<&'static str> {
        let mut caps = vec![TYPE_PING];
        if self.can_mirror {
            caps.push(TYPE_MIRROR_STATE);
        }
        caps
    }

    fn identity_packet(&self, kind: IdentityKind) -> NetworkPacket {
        let mut p = NetworkPacket::new(TYPE_IDENTITY);
        p.put("deviceId", self.device_id.clone())
            // kdeconnectd's isValidIdentityPacket() rejects a nameless identity,
            // including the UDP one the spec shows without a name.
            .put("deviceName", self.device_name.clone())
            .put("protocolVersion", PROTOCOL_VERSION);
        match kind {
            IdentityKind::Udp => {
                p.put("tcpPort", self.tcp_port as i64);
            }
            IdentityKind::Tcp { target_id, target_version } => {
                p.put("targetDeviceId", target_id)
                    .put("targetProtocolVersion", target_version);
            }
            IdentityKind::Secure => {
                p.put("deviceType", "desktop")
                    .put("incomingCapabilities", self.incoming_capabilities())
                    .put("outgoingCapabilities", self.outgoing_capabilities());
            }
        }
        p
    }

    fn is_trusted(&self, device_id: &str) -> bool {
        self.trusted.lock().unwrap().contains_key(device_id)
    }

    fn trust(&self, device_id: &str, cert_der: Vec<u8>) {
        self.trusted.lock().unwrap().insert(device_id.to_string(), cert_der);
        self.save_trusted();
    }

    fn save_trusted(&self) {
        let map = self.trusted.lock().unwrap();
        let encoded: HashMap<&String, String> =
            map.iter().map(|(k, v)| (k, hex_encode(v))).collect();
        if let Ok(json) = serde_json::to_string_pretty(&encoded) {
            let _ = std::fs::write(&self.trusted_path, json);
        }
    }

    fn load_trusted(path: &std::path::Path) -> HashMap<String, Vec<u8>> {
        let Ok(text) = std::fs::read_to_string(path) else {
            return HashMap::new();
        };
        let Ok(raw) = serde_json::from_str::<HashMap<String, String>>(&text) else {
            return HashMap::new();
        };
        raw.into_iter()
            .filter_map(|(k, v)| hex_decode(&v).map(|d| (k, d)))
            .collect()
    }
}

enum IdentityKind {
    Udp,
    Tcp { target_id: String, target_version: i64 },
    Secure,
}

fn hex_encode(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

fn hex_decode(s: &str) -> Option<Vec<u8>> {
    if s.len() % 2 != 0 {
        return None;
    }
    (0..s.len())
        .step_by(2)
        .map(|i| u8::from_str_radix(&s[i..i + 2], 16).ok())
        .collect()
}

#[tokio::main]
async fn main() -> Result<()> {
    rustls::crypto::ring::default_provider()
        .install_default()
        .ok();

    let dir = state_dir();
    let device_id = load_device_id(&dir)?;
    let identity = crypto::load_or_create_identity(&dir, &device_id)?;
    let device_name = sanitize_name(
        &std::env::var("GOLEM_DEVICE_NAME").unwrap_or_else(|_| {
            std::fs::read_to_string("/etc/hostname")
                .map(|s| s.trim().to_string())
                .unwrap_or_else(|_| "Golem Desktop".into())
        }),
    );

    let input_tx = input::spawn_wayland_sink().context("starting input sink")?;
    println!("input sink ready (wayland virtual pointer + keyboard)");

    // A missing gamepad must not cost us the touchpad: the pointer and
    // keyboard go through Wayland and need no privileges, while the gamepad
    // needs /dev/uinput. Degrade, do not refuse to start.
    let gamepad_tx = match uinput::probe() {
        Ok(()) => {
            println!("gamepad sink ready (uinput, created on first use)");
            Some(uinput::spawn_gamepad_sink())
        }
        Err(e) => {
            println!("gamepad unavailable: {e:#}");
            None
        }
    };

    let can_mirror = mirror::tools_available();
    if can_mirror {
        println!("mirror ready (scrcpy + adb on PATH)");
    } else {
        println!("mirror unavailable: scrcpy or adb missing from PATH");
    }

    // Bind the TCP listener first: our UDP identity must advertise a real port.
    let (listener, tcp_port) = bind_tcp().await?;
    let trusted_path = dir.join("trusted.json");

    let config = Arc::new(Config {
        device_id: device_id.clone(),
        device_name: device_name.clone(),
        identity,
        tcp_port,
        trusted: Mutex::new(Config::load_trusted(&trusted_path)),
        trusted_path,
        input_tx,
        gamepad_tx,
        can_mirror,
    });

    println!("golem-connectd");
    println!("  device: {device_name} ({device_id})");
    println!("  tcp: {tcp_port}  udp: {DISCOVERY_PORT}");
    println!("  paired: {:?}", config.trusted.lock().unwrap().keys().collect::<Vec<_>>());

    // kdeconnectd may already own :1716. That only costs us the ability to
    // *hear* broadcasts — we can still announce ourselves from an ephemeral
    // port, and the phone will open the TCP connection to us. So fall back
    // instead of refusing to start, and the two daemons coexist.
    let (udp, can_listen) = match UdpSocket::bind(("0.0.0.0", DISCOVERY_PORT)).await {
        Ok(socket) => (socket, true),
        Err(e) => {
            println!("  udp {DISCOVERY_PORT} unavailable ({e}); announce-only mode");
            (UdpSocket::bind(("0.0.0.0", 0)).await?, false)
        }
    };
    let udp = Arc::new(udp);
    udp.set_broadcast(true)?;

    // Announce ourselves so the phone lists us even before it broadcasts.
    {
        let udp = udp.clone();
        let config = config.clone();
        tokio::spawn(async move {
            loop {
                let wire = config.identity_packet(IdentityKind::Udp).serialize();
                let _ = udp
                    .send_to(wire.as_bytes(), ("255.255.255.255", DISCOVERY_PORT))
                    .await;
                tokio::time::sleep(std::time::Duration::from_secs(30)).await;
            }
        });
    }

    // Incoming TCP: the peer received OUR broadcast, so it is the TLS server
    // and we are the client.
    {
        let config = config.clone();
        tokio::spawn(async move {
            loop {
                match listener.accept().await {
                    Ok((stream, peer)) => {
                        let config = config.clone();
                        tokio::spawn(async move {
                            if let Err(e) = handle_incoming(config, stream, peer).await {
                                eprintln!("incoming {peer}: {e}");
                            }
                        });
                    }
                    Err(e) => eprintln!("accept failed: {e}"),
                }
            }
        });
    }

    if !can_listen {
        // Nothing will arrive on an ephemeral port; just stay alive so the
        // announce task and the TCP listener keep running.
        std::future::pending::<()>().await;
    }

    // UDP discovery: a broadcast we receive means we must connect out.
    let mut buf = vec![0u8; 8192];
    loop {
        let (len, from) = udp.recv_from(&mut buf).await?;
        let Ok(text) = std::str::from_utf8(&buf[..len]) else {
            continue;
        };
        for line in text.lines().filter(|l| !l.trim().is_empty()) {
            let Ok(pkt) = NetworkPacket::parse(line) else {
                continue;
            };
            if pkt.packet_type != TYPE_IDENTITY {
                continue;
            }
            let Some(peer_id) = pkt.get_str("deviceId").map(str::to_string) else {
                continue;
            };
            if peer_id == config.device_id {
                continue; // our own broadcast
            }
            let Some(port) = pkt.get_i64("tcpPort") else {
                continue;
            };
            let peer_version = pkt.get_i64("protocolVersion").unwrap_or(7);
            let name = pkt.get_str("deviceName").unwrap_or("?").to_string();
            let addr = SocketAddr::new(from.ip(), port as u16);

            let config = config.clone();
            tokio::spawn(async move {
                if let Err(e) = connect_out(config, addr, peer_id, peer_version, name).await {
                    eprintln!("connect {addr}: {e}");
                }
            });
        }
    }
}

async fn bind_tcp() -> Result<(TcpListener, u16)> {
    for port in TCP_PORT_MIN..=TCP_PORT_MAX {
        if let Ok(listener) = TcpListener::bind(("0.0.0.0", port)).await {
            return Ok((listener, port));
        }
    }
    anyhow::bail!("no free TCP port in {TCP_PORT_MIN}-{TCP_PORT_MAX}")
}

/// We received their broadcast: connect, send plaintext identity, be TLS server.
async fn connect_out(
    config: Arc<Config>,
    addr: SocketAddr,
    peer_id: String,
    peer_version: i64,
    peer_name: String,
) -> Result<()> {
    let mut stream = TcpStream::connect(addr).await?;
    stream.set_nodelay(true)?;

    let hello = config
        .identity_packet(IdentityKind::Tcp {
            target_id: peer_id.clone(),
            target_version: peer_version,
        })
        .serialize();
    stream.write_all(hello.as_bytes()).await?;
    stream.flush().await?;

    let acceptor = tls_acceptor(&config)?;
    let tls = acceptor.accept(stream).await.context("TLS accept")?;
    let peer_cert = {
        let (_, conn) = tls.get_ref();
        conn.peer_certificates()
            .and_then(|c| c.first())
            .map(|c| c.to_vec())
            .context("peer presented no certificate")?
    };

    println!("connected to {peer_name} ({peer_id}) at {addr} — we are TLS server");
    run_link(config, Box::new(tls), peer_id, peer_name, peer_cert, Some(addr.ip())).await
}

/// They received our broadcast: they send plaintext identity, they are TLS server.
async fn handle_incoming(
    config: Arc<Config>,
    mut stream: TcpStream,
    peer: SocketAddr,
) -> Result<()> {
    stream.set_nodelay(true)?;

    // Byte-by-byte: a buffered reader would swallow TLS handshake bytes that
    // arrive in the same segment as the identity line.
    let mut line = Vec::new();
    let mut byte = [0u8; 1];
    loop {
        let n = stream.read(&mut byte).await?;
        if n == 0 {
            anyhow::bail!("peer closed before sending identity");
        }
        if byte[0] == b'\n' {
            break;
        }
        line.push(byte[0]);
        if line.len() > 16 * 1024 {
            anyhow::bail!("identity line too long");
        }
    }

    let pkt = NetworkPacket::parse(std::str::from_utf8(&line)?)?;
    if pkt.packet_type != TYPE_IDENTITY {
        anyhow::bail!("expected identity, got {}", pkt.packet_type);
    }
    let peer_id = pkt
        .get_str("deviceId")
        .context("identity without deviceId")?
        .to_string();
    let peer_name = pkt.get_str("deviceName").unwrap_or("?").to_string();

    let connector = tls_connector(&config)?;
    let server_name = rustls::pki_types::ServerName::try_from(peer_id.clone())
        .unwrap_or(rustls::pki_types::ServerName::try_from("golem").unwrap());
    let tls = connector.connect(server_name, stream).await.context("TLS connect")?;
    let peer_cert = {
        let (_, conn) = tls.get_ref();
        conn.peer_certificates()
            .and_then(|c| c.first())
            .map(|c| c.to_vec())
            .context("peer presented no certificate")?
    };

    println!("accepted {peer_name} ({peer_id}) from {peer} — we are TLS client");
    run_link(config, Box::new(tls), peer_id, peer_name, peer_cert, Some(peer.ip())).await
}

trait Link: tokio::io::AsyncRead + tokio::io::AsyncWrite + Unpin + Send {}
impl<T: tokio::io::AsyncRead + tokio::io::AsyncWrite + Unpin + Send> Link for T {}

/// However the link ends — clean close, read error, certificate mismatch — the
/// virtual gamepad has to go with it, or whatever was held at the moment the
/// Wi-Fi dropped stays held forever.
///
/// It only fires if this link actually drove the gamepad. A phone that
/// reconnects after a blip leaves the old link's teardown racing the new
/// link's first packet, and an unconditional teardown would destroy the pad
/// the new link had just created.
struct GamepadGuard {
    tx: Option<std::sync::mpsc::Sender<Vec<gamepad::GamepadEvent>>>,
    used: Arc<std::sync::atomic::AtomicBool>,
}

impl Drop for GamepadGuard {
    fn drop(&mut self) {
        if !self.used.load(std::sync::atomic::Ordering::Relaxed) {
            return;
        }
        if let Some(tx) = &self.tx {
            let _ = tx.send(vec![gamepad::GamepadEvent::Disconnect]);
        }
    }
}

/// Find a reachable adb serial for the phone on this link and start scrcpy.
/// Returns the serial used, or the message the phone should show.
fn start_mirror(
    mirror: &mut mirror::Mirror,
    peer_ip: Option<std::net::IpAddr>,
    opts: &mirror::MirrorOptions,
) -> std::result::Result<String, String> {
    for serial in mirror::serial_candidates(peer_ip, &mirror::adb_usb_serials()) {
        // A network serial has to be dialled before it exists; a USB one is
        // already there, so only the former needs connecting.
        if serial.contains(':') && !mirror::adb_connect(&serial) {
            continue;
        }
        if mirror::adb_state(&serial).as_deref() != Some("device") {
            continue;
        }
        return match mirror.start(&serial, opts) {
            Ok(()) => Ok(serial),
            Err(e) => Err(format!("scrcpy failed to start: {e}")),
        };
    }
    Err(mirror::NO_DEVICE_HINT.to_string())
}

async fn run_link(
    config: Arc<Config>,
    mut stream: Box<dyn Link>,
    peer_id: String,
    peer_name: String,
    peer_cert: Vec<u8>,
    peer_ip: Option<std::net::IpAddr>,
) -> Result<()> {
    // A pinned certificate that changed means this is not the device we paired
    // with. Refuse rather than silently re-trusting.
    if let Some(pinned) = config.trusted.lock().unwrap().get(&peer_id).cloned() {
        if pinned != peer_cert {
            anyhow::bail!("certificate mismatch for {peer_id} — refusing link");
        }
    }

    let used_gamepad = Arc::new(std::sync::atomic::AtomicBool::new(false));
    let _gamepad_guard = GamepadGuard {
        tx: config.gamepad_tx.clone(),
        used: used_gamepad.clone(),
    };

    // The mirror belongs to this link: dropping it kills scrcpy, so a phone
    // that walks out of Wi-Fi range does not leave a frozen window behind.
    // Unlike the gamepad this needs no "did we use it" guard, because the
    // process handle is per-link rather than a shared device.
    let mut mirror = mirror::Mirror::default();

    // v8: the full identity goes over the encrypted channel, right after the
    // handshake, in both directions.
    let secure = config.identity_packet(IdentityKind::Secure).serialize();
    stream.write_all(secure.as_bytes()).await?;
    stream.flush().await?;

    let mut buf = vec![0u8; 8192];
    let mut pending = Vec::new();
    loop {
        let n = stream.read(&mut buf).await?;
        if n == 0 {
            println!("{peer_name} disconnected");
            return Ok(());
        }
        pending.extend_from_slice(&buf[..n]);

        while let Some(pos) = pending.iter().position(|b| *b == b'\n') {
            let line: Vec<u8> = pending.drain(..=pos).collect();
            let line = &line[..line.len() - 1];
            if line.is_empty() {
                continue;
            }
            let Ok(text) = std::str::from_utf8(line) else {
                continue;
            };
            let Ok(pkt) = NetworkPacket::parse(text) else {
                eprintln!("unparseable packet from {peer_name}");
                continue;
            };
            handle_packet(
                &config,
                &mut stream,
                &pkt,
                &peer_id,
                &peer_name,
                &peer_cert,
                &used_gamepad,
                &mut mirror,
                peer_ip,
            )
            .await?;
        }
    }
}

async fn handle_packet(
    config: &Arc<Config>,
    stream: &mut Box<dyn Link>,
    pkt: &NetworkPacket,
    peer_id: &str,
    peer_name: &str,
    peer_cert: &[u8],
    used_gamepad: &std::sync::atomic::AtomicBool,
    mirror: &mut mirror::Mirror,
    peer_ip: Option<std::net::IpAddr>,
) -> Result<()> {
    match pkt.packet_type.as_str() {
        TYPE_IDENTITY => {
            // Secure identity; nothing to do beyond noting it arrived.
        }
        TYPE_PAIR => {
            if pkt.get_bool("pair") {
                let timestamp = pkt.get_i64("timestamp").unwrap_or_else(packet::now_secs);
                let own_spki = crypto::spki_der(&config.identity.cert_der)?;
                let peer_spki = crypto::spki_der(peer_cert)?;
                let code = crypto::verification_key(&own_spki, &peer_spki, timestamp);
                println!("\n  PAIR REQUEST from {peer_name} ({peer_id})");
                println!("  verification code: {code}");
                println!("  (compare with the phone's screen)\n");

                config.trust(peer_id, peer_cert.to_vec());
                let mut reply = NetworkPacket::new(TYPE_PAIR);
                reply.put("pair", true);
                stream.write_all(reply.serialize().as_bytes()).await?;
                stream.flush().await?;
                println!("  paired with {peer_name}");
            } else {
                config.trusted.lock().unwrap().remove(peer_id);
                config.save_trusted();
                println!("  unpaired by {peer_name}");
            }
        }
        TYPE_MOUSEPAD_REQUEST => {
            if !config.is_trusted(peer_id) {
                eprintln!("ignoring mousepad from unpaired {peer_id}");
                return Ok(());
            }
            let events = mousepad::to_events(pkt);
            if std::env::var_os("GOLEM_DEBUG").is_some() {
                eprintln!("mousepad {:?} -> {} events", pkt.body, events.len());
            }
            for event in events {
                let _ = config.input_tx.send(event);
            }
        }
        TYPE_GAMEPAD => {
            if !config.is_trusted(peer_id) {
                eprintln!("ignoring gamepad from unpaired {peer_id}");
                return Ok(());
            }
            // Decoded before the sink is looked up, so GOLEM_DEBUG can show
            // what the phone is actually sending even on a machine where
            // /dev/uinput is closed to us — otherwise the wire could only be
            // checked on a box where the whole path already works.
            let events = gamepad::to_events(pkt);
            if std::env::var_os("GOLEM_DEBUG").is_some() {
                eprintln!("gamepad {:?} -> {:?}", pkt.body, events);
            }
            let Some(tx) = config.gamepad_tx.as_ref() else {
                // Only reachable if the phone ignores our announced
                // capabilities, so say so rather than dropping in silence.
                eprintln!("gamepad packet but /dev/uinput is unavailable");
                return Ok(());
            };
            if !events.is_empty() {
                used_gamepad.store(true, std::sync::atomic::Ordering::Relaxed);
                let _ = tx.send(events);
            }
        }
        TYPE_MIRROR => {
            if !config.is_trusted(peer_id) {
                eprintln!("ignoring mirror request from unpaired {peer_id}");
                return Ok(());
            }
            let (running, error) = match mirror::action_from(pkt, peer_name) {
                mirror::MirrorAction::Stop => {
                    mirror.stop();
                    println!("mirror stopped ({peer_name})");
                    (false, None)
                }
                mirror::MirrorAction::Start(opts) => {
                    // A second start while one is running is a no-op rather
                    // than a second window: the phone's button is a toggle and
                    // its idea of the state can be stale.
                    if mirror.is_running() {
                        (true, None)
                    } else {
                        match start_mirror(mirror, peer_ip, &opts) {
                            Ok(serial) => {
                                println!("mirroring {peer_name} via {serial}");
                                (true, None)
                            }
                            Err(e) => {
                                eprintln!("mirror failed: {e}");
                                (false, Some(e))
                            }
                        }
                    }
                }
            };
            let mut reply = NetworkPacket::new(TYPE_MIRROR_STATE);
            reply.put("running", running);
            if let Some(message) = error {
                reply.put("error", message);
            }
            stream.write_all(reply.serialize().as_bytes()).await?;
            stream.flush().await?;
        }
        TYPE_PING => {
            println!("ping from {peer_name}: {}", pkt.get_str("message").unwrap_or(""));
        }
        other => {
            if config.is_trusted(peer_id) {
                println!("(ignoring {other} from {peer_name})");
            }
        }
    }
    Ok(())
}

// ── TLS ────────────────────────────────────────────────────────────────────
// Certificates are self-signed and pinned at the pairing layer (TOFU), so the
// TLS layer itself accepts any peer certificate and records it. Pinning is
// enforced in run_link, not here.

#[derive(Debug)]
struct AcceptAnyClient;

impl rustls::server::danger::ClientCertVerifier for AcceptAnyClient {
    fn root_hint_subjects(&self) -> &[rustls::DistinguishedName] {
        &[]
    }
    fn verify_client_cert(
        &self,
        _: &rustls::pki_types::CertificateDer<'_>,
        _: &[rustls::pki_types::CertificateDer<'_>],
        _: rustls::pki_types::UnixTime,
    ) -> Result<rustls::server::danger::ClientCertVerified, rustls::Error> {
        Ok(rustls::server::danger::ClientCertVerified::assertion())
    }
    fn verify_tls12_signature(
        &self,
        message: &[u8],
        cert: &rustls::pki_types::CertificateDer<'_>,
        dss: &rustls::DigitallySignedStruct,
    ) -> Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        rustls::crypto::verify_tls12_signature(
            message,
            cert,
            dss,
            &rustls::crypto::ring::default_provider().signature_verification_algorithms,
        )
    }
    fn verify_tls13_signature(
        &self,
        message: &[u8],
        cert: &rustls::pki_types::CertificateDer<'_>,
        dss: &rustls::DigitallySignedStruct,
    ) -> Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        rustls::crypto::verify_tls13_signature(
            message,
            cert,
            dss,
            &rustls::crypto::ring::default_provider().signature_verification_algorithms,
        )
    }
    fn supported_verify_schemes(&self) -> Vec<rustls::SignatureScheme> {
        rustls::crypto::ring::default_provider()
            .signature_verification_algorithms
            .supported_schemes()
    }
}

#[derive(Debug)]
struct AcceptAnyServer;

impl rustls::client::danger::ServerCertVerifier for AcceptAnyServer {
    fn verify_server_cert(
        &self,
        _: &rustls::pki_types::CertificateDer<'_>,
        _: &[rustls::pki_types::CertificateDer<'_>],
        _: &rustls::pki_types::ServerName<'_>,
        _: &[u8],
        _: rustls::pki_types::UnixTime,
    ) -> Result<rustls::client::danger::ServerCertVerified, rustls::Error> {
        Ok(rustls::client::danger::ServerCertVerified::assertion())
    }
    fn verify_tls12_signature(
        &self,
        message: &[u8],
        cert: &rustls::pki_types::CertificateDer<'_>,
        dss: &rustls::DigitallySignedStruct,
    ) -> Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        rustls::crypto::verify_tls12_signature(
            message,
            cert,
            dss,
            &rustls::crypto::ring::default_provider().signature_verification_algorithms,
        )
    }
    fn verify_tls13_signature(
        &self,
        message: &[u8],
        cert: &rustls::pki_types::CertificateDer<'_>,
        dss: &rustls::DigitallySignedStruct,
    ) -> Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        rustls::crypto::verify_tls13_signature(
            message,
            cert,
            dss,
            &rustls::crypto::ring::default_provider().signature_verification_algorithms,
        )
    }
    fn supported_verify_schemes(&self) -> Vec<rustls::SignatureScheme> {
        rustls::crypto::ring::default_provider()
            .signature_verification_algorithms
            .supported_schemes()
    }
}

fn cert_and_key(
    config: &Config,
) -> (
    Vec<rustls::pki_types::CertificateDer<'static>>,
    rustls::pki_types::PrivateKeyDer<'static>,
) {
    let cert = rustls::pki_types::CertificateDer::from(config.identity.cert_der.clone());
    let key = rustls::pki_types::PrivateKeyDer::try_from(config.identity.key_der.clone())
        .expect("stored private key is not valid DER");
    (vec![cert], key)
}

fn tls_acceptor(config: &Config) -> Result<tokio_rustls::TlsAcceptor> {
    let (certs, key) = cert_and_key(config);
    let server_config = rustls::ServerConfig::builder()
        .with_client_cert_verifier(Arc::new(AcceptAnyClient))
        .with_single_cert(certs, key)?;
    Ok(tokio_rustls::TlsAcceptor::from(Arc::new(server_config)))
}

fn tls_connector(config: &Config) -> Result<tokio_rustls::TlsConnector> {
    let (certs, key) = cert_and_key(config);
    let client_config = rustls::ClientConfig::builder()
        .dangerous()
        .with_custom_certificate_verifier(Arc::new(AcceptAnyServer))
        .with_client_auth_cert(certs, key)?;
    Ok(tokio_rustls::TlsConnector::from(Arc::new(client_config)))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn device_id_matches_the_v8_rule() {
        let id = generate_device_id();
        assert_eq!(id.len(), 32);
        assert!(id.chars().all(|c| c.is_ascii_alphanumeric()));
    }

    #[test]
    fn name_sanitizer_strips_forbidden_punctuation() {
        assert_eq!(sanitize_name("Max's PC (work)!"), "Maxs PC work");
    }

    #[test]
    fn name_sanitizer_caps_at_32_chars() {
        assert_eq!(sanitize_name(&"a".repeat(60)).len(), 32);
    }

    #[test]
    fn hex_round_trips() {
        let bytes = vec![0x00, 0x7f, 0x80, 0xff];
        assert_eq!(hex_decode(&hex_encode(&bytes)), Some(bytes));
    }

    #[test]
    fn hex_rejects_odd_length() {
        assert_eq!(hex_decode("abc"), None);
    }
}
