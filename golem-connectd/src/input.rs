// Input injection.
//
// `InputEvent` is the sink-independent vocabulary: the protocol layer speaks
// only this, so a uinput sink (needed for gamepads, which have no Wayland
// protocol) can be added later without touching packet handling.
//
// The Wayland objects are not Send, so the sink owns a dedicated thread and
// receives events over a channel.

use anyhow::{Context, Result};
use std::io::Write;
use std::os::fd::AsFd;
use std::sync::mpsc::{self, Receiver, Sender};
use std::time::{SystemTime, UNIX_EPOCH};

use wayland_client::protocol::{wl_pointer, wl_registry, wl_seat};
use wayland_client::{delegate_noop, Connection, Dispatch, QueueHandle};
use wayland_protocols_misc::zwp_virtual_keyboard_v1::client::{
    zwp_virtual_keyboard_manager_v1::ZwpVirtualKeyboardManagerV1,
    zwp_virtual_keyboard_v1::ZwpVirtualKeyboardV1,
};
use wayland_protocols_wlr::virtual_pointer::v1::client::{
    zwlr_virtual_pointer_manager_v1::ZwlrVirtualPointerManagerV1,
    zwlr_virtual_pointer_v1::ZwlrVirtualPointerV1,
};

// linux/input-event-codes.h
pub const KEY_ESC: u32 = 1;
pub const KEY_BACKSPACE: u32 = 14;
pub const KEY_ENTER: u32 = 28;
pub const KEY_LEFTSHIFT: u32 = 42;
pub const KEY_LEFTCTRL: u32 = 29;
pub const KEY_LEFTALT: u32 = 56;
pub const KEY_LEFTMETA: u32 = 125;
pub const KEY_UP: u32 = 103;
pub const KEY_LEFT: u32 = 105;
pub const KEY_RIGHT: u32 = 106;
pub const KEY_DOWN: u32 = 108;

// BTN_* codes the virtual pointer expects.
pub const BTN_LEFT: u32 = 0x110;
pub const BTN_RIGHT: u32 = 0x111;
pub const BTN_MIDDLE: u32 = 0x112;

#[derive(Debug, Clone)]
pub enum InputEvent {
    PointerMotion { dx: f64, dy: f64 },
    PointerButtonClick { button: u32 },
    Scroll { dx: f64, dy: f64 },
    /// A printable character, resolved to keycode+shift by the sink.
    Text(String),
    /// A raw evdev keycode with optional modifiers held around it.
    Key { keycode: u32, modifiers: Vec<u32> },
}

/// Protocol special-key number -> evdev keycode.
/// Numbers are the protocol's fixed table, mirrored in MousepadPlugin.kt.
pub fn special_key(n: i64) -> Option<u32> {
    Some(match n {
        1 => KEY_BACKSPACE,
        4 => KEY_LEFT,
        5 => KEY_UP,
        6 => KEY_RIGHT,
        7 => KEY_DOWN,
        12 => KEY_ENTER,
        14 => KEY_ESC,
        _ => return None,
    })
}

/// US-layout character -> (keycode, needs shift).
pub fn char_to_key(c: char) -> Option<(u32, bool)> {
    const ROW_DIGITS: [(char, char, u32); 12] = [
        ('1', '!', 2), ('2', '@', 3), ('3', '#', 4), ('4', '$', 5),
        ('5', '%', 6), ('6', '^', 7), ('7', '&', 8), ('8', '*', 9),
        ('9', '(', 10), ('0', ')', 11), ('-', '_', 12), ('=', '+', 13),
    ];
    const PUNCT: [(char, char, u32); 9] = [
        ('[', '{', 26), (']', '}', 27), ('\\', '|', 43), (';', ':', 39),
        ('\'', '"', 40), (',', '<', 51), ('.', '>', 52), ('/', '?', 53),
        ('`', '~', 41),
    ];
    // Letters are laid out by row, not alphabetically.
    const QWERTY: &str = "qwertyuiop";
    const ASDF: &str = "asdfghjkl";
    const ZXCV: &str = "zxcvbnm";

    if c == ' ' {
        return Some((57, false));
    }
    if c == '\n' || c == '\r' {
        return Some((KEY_ENTER, false));
    }
    if c == '\t' {
        return Some((15, false));
    }

    let lower = c.to_ascii_lowercase();
    let shifted = c.is_ascii_uppercase();

    if let Some(i) = QWERTY.find(lower) {
        return Some((16 + i as u32, shifted));
    }
    if let Some(i) = ASDF.find(lower) {
        return Some((30 + i as u32, shifted));
    }
    if let Some(i) = ZXCV.find(lower) {
        return Some((44 + i as u32, shifted));
    }
    for (plain, shift, code) in ROW_DIGITS.iter().chain(PUNCT.iter()) {
        if c == *plain {
            return Some((*code, false));
        }
        if c == *shift {
            return Some((*code, true));
        }
    }
    None
}

fn now_ms() -> u32 {
    SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_millis() as u32
}

#[derive(Default)]
struct State {
    seat: Option<wl_seat::WlSeat>,
    pointer_mgr: Option<ZwlrVirtualPointerManagerV1>,
    keyboard_mgr: Option<ZwpVirtualKeyboardManagerV1>,
}

impl Dispatch<wl_registry::WlRegistry, ()> for State {
    fn event(
        state: &mut Self,
        registry: &wl_registry::WlRegistry,
        event: wl_registry::Event,
        _: &(),
        _: &Connection,
        qh: &QueueHandle<Self>,
    ) {
        let wl_registry::Event::Global { name, interface, version } = event else {
            return;
        };
        match interface.as_str() {
            "wl_seat" => state.seat = Some(registry.bind(name, version.min(7), qh, ())),
            "zwlr_virtual_pointer_manager_v1" => {
                state.pointer_mgr = Some(registry.bind(name, version.min(2), qh, ()))
            }
            "zwp_virtual_keyboard_manager_v1" => {
                state.keyboard_mgr = Some(registry.bind(name, version.min(1), qh, ()))
            }
            _ => {}
        }
    }
}

delegate_noop!(State: ignore wl_seat::WlSeat);
delegate_noop!(State: ignore ZwlrVirtualPointerManagerV1);
delegate_noop!(State: ignore ZwlrVirtualPointerV1);
delegate_noop!(State: ignore ZwpVirtualKeyboardManagerV1);
delegate_noop!(State: ignore ZwpVirtualKeyboardV1);

/// Start the Wayland sink thread. Returns the channel the protocol layer
/// pushes events into.
pub fn spawn_wayland_sink() -> Result<Sender<InputEvent>> {
    let (tx, rx) = mpsc::channel::<InputEvent>();
    let (ready_tx, ready_rx) = mpsc::channel::<Result<(), String>>();

    std::thread::spawn(move || {
        match run_sink(rx, &ready_tx) {
            Ok(()) => {}
            Err(e) => {
                // If setup failed, report it; if it failed later, log it.
                let _ = ready_tx.send(Err(e.to_string()));
                eprintln!("wayland sink stopped: {e}");
            }
        }
    });

    match ready_rx.recv() {
        Ok(Ok(())) => Ok(tx),
        Ok(Err(e)) => anyhow::bail!("wayland sink failed to start: {e}"),
        Err(_) => anyhow::bail!("wayland sink thread died during startup"),
    }
}

fn run_sink(rx: Receiver<InputEvent>, ready: &Sender<Result<(), String>>) -> Result<()> {
    let conn = Connection::connect_to_env()
        .context("no WAYLAND_DISPLAY — golem-connectd must run inside the session")?;
    let mut queue = conn.new_event_queue();
    let qh = queue.handle();
    conn.display().get_registry(&qh, ());

    let mut state = State::default();
    queue.roundtrip(&mut state).context("registry roundtrip")?;

    let pointer_mgr = state
        .pointer_mgr
        .clone()
        .context("compositor lacks zwlr_virtual_pointer_manager_v1")?;
    let keyboard_mgr = state
        .keyboard_mgr
        .clone()
        .context("compositor lacks zwp_virtual_keyboard_manager_v1")?;
    let seat = state.seat.clone().context("no wl_seat")?;

    let pointer = pointer_mgr.create_virtual_pointer(Some(&seat), &qh, ());
    let keyboard = keyboard_mgr.create_virtual_keyboard(&seat, &qh, ());

    // Without a keymap the compositor cannot resolve our keycodes at all.
    let keymap = r#"xkb_keymap {
    xkb_keycodes  { include "evdev+aliases(qwerty)" };
    xkb_types     { include "complete" };
    xkb_compat    { include "complete" };
    xkb_symbols   { include "pc+us+inet(evdev)" };
};
"#;
    let mut file = tempfile::tempfile().context("keymap tempfile")?;
    file.write_all(keymap.as_bytes())?;
    file.write_all(&[0])?;
    file.flush()?;
    keyboard.keymap(1, file.as_fd(), (keymap.len() + 1) as u32);
    queue.roundtrip(&mut state).context("keymap upload")?;

    ready.send(Ok(())).ok();

    for event in rx {
        match event {
            InputEvent::PointerMotion { dx, dy } => {
                pointer.motion(now_ms(), dx, dy);
                pointer.frame();
            }
            InputEvent::PointerButtonClick { button } => {
                pointer.button(now_ms(), button, wl_pointer::ButtonState::Pressed);
                pointer.frame();
                pointer.button(now_ms(), button, wl_pointer::ButtonState::Released);
                pointer.frame();
            }
            InputEvent::Scroll { dx, dy } => {
                // axis 0 = vertical, 1 = horizontal.
                if dy != 0.0 {
                    pointer.axis(now_ms(), wl_pointer::Axis::VerticalScroll, dy);
                }
                if dx != 0.0 {
                    pointer.axis(now_ms(), wl_pointer::Axis::HorizontalScroll, dx);
                }
                pointer.frame();
            }
            InputEvent::Text(text) => {
                if std::env::var_os("GOLEM_DEBUG").is_some() {
                    eprintln!("sink: Text({text:?})");
                }
                for c in text.chars() {
                    let Some((code, shift)) = char_to_key(c) else {
                        eprintln!("sink: no keycode for {c:?}");
                        continue;
                    };
                    if shift {
                        keyboard.key(now_ms(), KEY_LEFTSHIFT, 1);
                    }
                    keyboard.key(now_ms(), code, 1);
                    keyboard.key(now_ms(), code, 0);
                    if shift {
                        keyboard.key(now_ms(), KEY_LEFTSHIFT, 0);
                    }
                }
            }
            InputEvent::Key { keycode, modifiers } => {
                for m in &modifiers {
                    keyboard.key(now_ms(), *m, 1);
                }
                keyboard.key(now_ms(), keycode, 1);
                keyboard.key(now_ms(), keycode, 0);
                for m in modifiers.iter().rev() {
                    keyboard.key(now_ms(), *m, 0);
                }
            }
        }
        queue.flush().ok();
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn letters_map_by_keyboard_row_not_alphabet() {
        // 'a' is 30 and 'q' is 16 only if rows are handled; an alphabetical
        // table would put 'b' next to 'a'.
        assert_eq!(char_to_key('a'), Some((30, false)));
        assert_eq!(char_to_key('q'), Some((16, false)));
        assert_eq!(char_to_key('z'), Some((44, false)));
        assert_eq!(char_to_key('g'), Some((34, false)));
    }

    #[test]
    fn uppercase_requests_shift() {
        assert_eq!(char_to_key('G'), Some((34, true)));
        assert_eq!(char_to_key('g'), Some((34, false)));
    }

    #[test]
    fn shifted_symbols_share_the_unshifted_keycode() {
        let (plain, plain_shift) = char_to_key('1').unwrap();
        let (bang, bang_shift) = char_to_key('!').unwrap();
        assert_eq!(plain, bang);
        assert!(!plain_shift && bang_shift);
    }

    #[test]
    fn special_keys_match_the_protocol_table() {
        assert_eq!(special_key(1), Some(KEY_BACKSPACE));
        assert_eq!(special_key(12), Some(KEY_ENTER));
        assert_eq!(special_key(14), Some(KEY_ESC));
        assert_eq!(special_key(4), Some(KEY_LEFT));
        assert_eq!(special_key(99), None);
    }

    #[test]
    fn unmappable_characters_are_rejected_not_guessed() {
        assert_eq!(char_to_key('€'), None);
    }
}
