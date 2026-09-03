// `golem.mirror` -> a scrcpy window showing the phone's screen.
//
// Mirroring is the one feature where the phone asks the *desktop* to do
// something visible on the desktop, so the phone gets an answer back
// (`golem.mirror.state`) instead of guessing: scrcpy can fail for reasons the
// phone cannot see, above all adb-over-TCP not being enabled on this phone
// boot.
//
// Everything here that decides *what* to run is pure and unit tested; only
// `Mirror` touches processes.

use crate::packet::NetworkPacket;
use serde_json::Value;
use std::process::{Child, Command, Stdio};

/// The default adb TCP port, as set by `adb tcpip 5555`.
pub const ADB_TCP_PORT: u16 = 5555;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MirrorAction {
    Start(MirrorOptions),
    Stop,
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct MirrorOptions {
    /// Blank the phone's screen while mirroring: the desktop window stays
    /// live, which is both a privacy and a battery win.
    pub turn_screen_off: bool,
    /// Keep the phone awake while mirroring, so it does not lock mid-session.
    pub stay_awake: bool,
    /// Window title, so the window is recognisably Golem's.
    pub title: String,
}

/// Decode a `golem.mirror` packet. Anything unrecognised is a stop, because
/// the failure mode of a stray start is a window the user did not ask for.
pub fn action_from(pkt: &NetworkPacket, phone_name: &str) -> MirrorAction {
    let start = matches!(pkt.body.get("action").and_then(Value::as_str), Some("start"));
    if !start {
        return MirrorAction::Stop;
    }
    MirrorAction::Start(MirrorOptions {
        turn_screen_off: pkt
            .body
            .get("turnScreenOff")
            .and_then(Value::as_bool)
            .unwrap_or(false),
        // Opt-out rather than opt-in: a phone that locks itself thirty seconds
        // into a mirroring session is not mirroring.
        stay_awake: pkt
            .body
            .get("stayAwake")
            .and_then(Value::as_bool)
            .unwrap_or(true),
        title: format!("Golem — {phone_name}"),
    })
}

/// The scrcpy command line for a resolved adb serial.
pub fn scrcpy_args(serial: &str, opts: &MirrorOptions) -> Vec<String> {
    let mut args = vec![
        "-s".to_string(),
        serial.to_string(),
        "--window-title".to_string(),
        opts.title.clone(),
    ];
    if opts.stay_awake {
        args.push("--stay-awake".to_string());
    }
    if opts.turn_screen_off {
        args.push("--turn-screen-off".to_string());
    }
    args
}

/// adb serials to try, in order: this link's peer over TCP first, since the
/// phone that asked is the phone to mirror, then whatever is on USB.
pub fn serial_candidates(peer_ip: Option<std::net::IpAddr>, usb_serials: &[String]) -> Vec<String> {
    let mut out = Vec::new();
    if let Some(ip) = peer_ip {
        out.push(format!("{ip}:{ADB_TCP_PORT}"));
    }
    out.extend(usb_serials.iter().cloned());
    out
}

/// USB serials from `adb devices` output: lines are "<serial>\t<state>", and
/// only "device" is usable ("unauthorized" and "offline" are not). Serials
/// containing ':' are network devices, which we add ourselves.
///
/// The "List of devices attached" header needs no special case — it fails the
/// state check like any other non-device line, which is also what protects us
/// from adb's occasional "* daemon started successfully" chatter.
pub fn parse_usb_serials(adb_devices_stdout: &str) -> Vec<String> {
    adb_devices_stdout
        .lines()
        .filter_map(|line| {
            let mut parts = line.split_whitespace();
            let serial = parts.next()?;
            let state = parts.next()?;
            if state == "device" && !serial.contains(':') {
                Some(serial.to_string())
            } else {
                None
            }
        })
        .collect()
}

/// The one-line reason the phone shows when nothing could be reached. The
/// wireless path needs `adb tcpip` once per phone boot, and there is no way
/// to trigger that from here — so say so rather than failing blankly.
pub const NO_DEVICE_HINT: &str =
    "No adb device. Plug in over USB, or run 'golem-mirror --setup' once while plugged in.";

/// A running scrcpy, killed when this link goes away or the phone says stop.
#[derive(Default)]
pub struct Mirror {
    child: Option<Child>,
}

impl Mirror {
    /// True if a previously started scrcpy is still running. Reaps it if not,
    /// so a window the user closed does not block the next start.
    pub fn is_running(&mut self) -> bool {
        match self.child.as_mut() {
            Some(child) => match child.try_wait() {
                Ok(Some(_)) => {
                    self.child = None;
                    false
                }
                Ok(None) => true,
                Err(_) => {
                    self.child = None;
                    false
                }
            },
            None => false,
        }
    }

    pub fn start(&mut self, serial: &str, opts: &MirrorOptions) -> std::io::Result<()> {
        self.stop();
        let child = Command::new("scrcpy")
            .args(scrcpy_args(serial, opts))
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()?;
        self.child = Some(child);
        Ok(())
    }

    pub fn stop(&mut self) {
        if let Some(mut child) = self.child.take() {
            let _ = child.kill();
            let _ = child.wait();
        }
    }
}

impl Drop for Mirror {
    fn drop(&mut self) {
        self.stop();
    }
}

/// Ask adb to attach to the phone over TCP. Returns false when the phone has
/// no adb-over-TCP listener, which is the normal state after a reboot.
pub fn adb_connect(target: &str) -> bool {
    let Ok(out) = Command::new("adb").args(["connect", target]).output() else {
        return false;
    };
    let text = String::from_utf8_lossy(&out.stdout);
    // adb exits 0 even for "failed to connect", so the text is the real answer.
    text.contains("connected to")
}

pub fn adb_state(serial: &str) -> Option<String> {
    let out = Command::new("adb")
        .args(["-s", serial, "get-state"])
        .output()
        .ok()?;
    Some(String::from_utf8_lossy(&out.stdout).trim().to_string())
}

pub fn adb_usb_serials() -> Vec<String> {
    let Ok(out) = Command::new("adb").arg("devices").output() else {
        return Vec::new();
    };
    parse_usb_serials(&String::from_utf8_lossy(&out.stdout))
}

/// Whether this machine can mirror at all. Used to gate the announced
/// capability, so a desktop without scrcpy hides the phone's button instead
/// of offering one that cannot work.
pub fn tools_available() -> bool {
    ["scrcpy", "adb"].iter().all(|tool| {
        Command::new(tool)
            .arg("--version")
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map(|s| s.success())
            .unwrap_or(false)
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::packet::TYPE_MIRROR;

    fn packet(body: &str) -> NetworkPacket {
        NetworkPacket::parse(&format!(
            r#"{{"id":1,"type":"{TYPE_MIRROR}","body":{body}}}"#
        ))
        .unwrap()
    }

    #[test]
    fn start_defaults_to_staying_awake() {
        // A phone that locks itself mid-session is not mirroring, so this is
        // opt-out, not opt-in.
        let MirrorAction::Start(opts) = action_from(&packet(r#"{"action":"start"}"#), "Pixel") else {
            panic!("expected a start");
        };
        assert!(opts.stay_awake);
        assert!(!opts.turn_screen_off);
        assert_eq!(opts.title, "Golem — Pixel");
    }

    #[test]
    fn stay_awake_can_be_turned_off_explicitly() {
        let MirrorAction::Start(opts) =
            action_from(&packet(r#"{"action":"start","stayAwake":false}"#), "Pixel")
        else {
            panic!("expected a start");
        };
        assert!(!opts.stay_awake);
    }

    #[test]
    fn anything_that_is_not_start_is_a_stop() {
        // An unexpected body must not open a window nobody asked for.
        for body in [r#"{"action":"stop"}"#, r#"{}"#, r#"{"action":"wat"}"#] {
            assert_eq!(action_from(&packet(body), "Pixel"), MirrorAction::Stop);
        }
    }

    #[test]
    fn args_carry_the_serial_and_title() {
        let opts = MirrorOptions {
            turn_screen_off: false,
            stay_awake: true,
            title: "Golem — Pixel".to_string(),
        };
        let args = scrcpy_args("192.168.1.199:5555", &opts);
        assert_eq!(args[0], "-s");
        assert_eq!(args[1], "192.168.1.199:5555");
        // The title must be one argv element, or a phone named "My Phone"
        // would be split into extra arguments scrcpy rejects.
        let title_at = args.iter().position(|a| a == "--window-title").unwrap();
        assert_eq!(args[title_at + 1], "Golem — Pixel");
        assert!(args.iter().any(|a| a == "--stay-awake"));
        assert!(!args.iter().any(|a| a == "--turn-screen-off"));
    }

    #[test]
    fn screen_off_is_passed_through_when_asked() {
        let opts = MirrorOptions {
            turn_screen_off: true,
            stay_awake: false,
            title: "t".to_string(),
        };
        let args = scrcpy_args("x", &opts);
        assert!(args.iter().any(|a| a == "--turn-screen-off"));
        assert!(!args.iter().any(|a| a == "--stay-awake"));
    }

    #[test]
    fn the_asking_phone_is_tried_before_usb() {
        // Two phones can be attached; the one that asked is the one to show.
        let candidates = serial_candidates(
            Some("192.168.1.199".parse().unwrap()),
            &["3A301FDJG000UW".to_string()],
        );
        assert_eq!(candidates[0], "192.168.1.199:5555");
        assert_eq!(candidates[1], "3A301FDJG000UW");
    }

    #[test]
    fn usb_parsing_skips_the_header_and_unusable_states() {
        let out = "List of devices attached\n\
                   3A301FDJG000UW\tdevice\n\
                   BADDEVICE\tunauthorized\n\
                   OFFLINE1\toffline\n\
                   192.168.1.199:5555\tdevice\n";
        // Network serials are added from the link's own peer address, not
        // scraped here — scraping them would mirror some other phone.
        assert_eq!(parse_usb_serials(out), vec!["3A301FDJG000UW".to_string()]);
    }

    #[test]
    fn usb_parsing_survives_empty_and_malformed_output() {
        assert!(parse_usb_serials("").is_empty());
        assert!(parse_usb_serials("List of devices attached\n\n").is_empty());
        assert!(parse_usb_serials("List of devices attached\ngarbage\n").is_empty());
    }

    #[test]
    fn adb_chatter_is_rejected_by_the_state_check() {
        // Nothing skips leading lines by position, so the state check is what
        // keeps the header and the daemon notice out of the serial list.
        let out = "* daemon not running; starting now at tcp:5037\n\
                   * daemon started successfully\n\
                   List of devices attached\n\
                   3A301FDJG000UW\tdevice\n";
        assert_eq!(parse_usb_serials(out), vec!["3A301FDJG000UW".to_string()]);
    }
}
