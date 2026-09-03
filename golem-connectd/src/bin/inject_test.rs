// Phase-1 proof: can an ordinary Wayland client move the cursor and type on
// Hyprland? Everything golem-connectd does with input rests on this, so it is
// proven standalone before any protocol code exists.
//
// Run inside the Hyprland session:  golem-inject-test

use std::io::Write;
use std::os::fd::AsFd;
use std::time::{SystemTime, UNIX_EPOCH};

use wayland_client::protocol::{wl_registry, wl_seat};
use wayland_client::{delegate_noop, Connection, Dispatch, QueueHandle};
use wayland_protocols_misc::zwp_virtual_keyboard_v1::client::{
    zwp_virtual_keyboard_manager_v1::ZwpVirtualKeyboardManagerV1,
    zwp_virtual_keyboard_v1::ZwpVirtualKeyboardV1,
};
use wayland_protocols_wlr::virtual_pointer::v1::client::{
    zwlr_virtual_pointer_manager_v1::ZwlrVirtualPointerManagerV1,
    zwlr_virtual_pointer_v1::ZwlrVirtualPointerV1,
};

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

fn now_ms() -> u32 {
    SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_millis() as u32
}

fn main() {
    let conn = Connection::connect_to_env().expect("no WAYLAND_DISPLAY — run inside the session");
    let mut queue = conn.new_event_queue();
    let qh = queue.handle();
    conn.display().get_registry(&qh, ());

    let mut state = State::default();
    queue.roundtrip(&mut state).expect("registry roundtrip failed");

    println!(
        "globals: seat={} virtual_pointer={} virtual_keyboard={}",
        state.seat.is_some(),
        state.pointer_mgr.is_some(),
        state.keyboard_mgr.is_some()
    );

    // Keystrokes land in whatever surface has focus, so the two halves are
    // separately runnable: never type into a window that wasn't asked for it.
    let mode = std::env::args().nth(1).unwrap_or_else(|| "pointer".into());
    let do_pointer = mode == "pointer" || mode == "both";
    let do_keyboard = mode == "keyboard" || mode == "both";

    // ── pointer ────────────────────────────────────────────────────────────
    if do_pointer {
    let pointer_mgr = state.pointer_mgr.clone().expect("compositor has no zwlr_virtual_pointer_manager_v1");
    let pointer: ZwlrVirtualPointerV1 =
        pointer_mgr.create_virtual_pointer(state.seat.as_ref(), &qh, ());

    // A single open motion: a closed path would land back on the start
    // pixel and prove nothing to `hyprctl cursorpos`.
    let dx: f64 = std::env::args().nth(2).and_then(|s| s.parse().ok()).unwrap_or(150.0);
    let dy: f64 = std::env::args().nth(3).and_then(|s| s.parse().ok()).unwrap_or(100.0);
    pointer.motion(now_ms(), dx, dy);
    pointer.frame();
    queue.roundtrip(&mut state).expect("pointer motion failed");
        println!("pointer: moved by ({dx}, {dy})");
    }

    // ── keyboard ───────────────────────────────────────────────────────────
    if !do_keyboard {
        return;
    }
    let keyboard_mgr = state.keyboard_mgr.clone().expect("compositor has no zwp_virtual_keyboard_manager_v1");
    let seat = state.seat.clone().expect("no wl_seat");
    let keyboard: ZwpVirtualKeyboardV1 = keyboard_mgr.create_virtual_keyboard(&seat, &qh, ());

    // The virtual keyboard is meaningless without a keymap: the compositor
    // resolves our keycodes through it.
    let keymap = r#"xkb_keymap {
    xkb_keycodes  { include "evdev+aliases(qwerty)" };
    xkb_types     { include "complete" };
    xkb_compat    { include "complete" };
    xkb_symbols   { include "pc+us+inet(evdev)" };
};
"#;
    let mut file = tempfile::tempfile().expect("tempfile for keymap");
    file.write_all(keymap.as_bytes()).unwrap();
    file.write_all(&[0]).unwrap();
    file.flush().unwrap();
    keyboard.keymap(1 /* xkb_v1 */, file.as_fd(), (keymap.len() + 1) as u32);
    queue.roundtrip(&mut state).expect("keymap upload failed");

    // "golem" in evdev keycodes (linux/input-event-codes.h).
    const KEY_G: u32 = 34;
    const KEY_O: u32 = 24;
    const KEY_L: u32 = 38;
    const KEY_E: u32 = 18;
    const KEY_M: u32 = 50;
    const KEY_ENTER: u32 = 28;
    for code in [KEY_G, KEY_O, KEY_L, KEY_E, KEY_M, KEY_ENTER] {
        keyboard.key(now_ms(), code, 1);
        queue.roundtrip(&mut state).unwrap();
        std::thread::sleep(std::time::Duration::from_millis(40));
        keyboard.key(now_ms(), code, 0);
        queue.roundtrip(&mut state).unwrap();
        std::thread::sleep(std::time::Duration::from_millis(40));
    }
    println!("keyboard: typed 'golem'");
}
