// `golem.gamepad` -> evdev events.
//
// This packet type is a Golem extension, deliberately NOT in the `kdeconnect.`
// namespace: KDE Connect has no gamepad plugin, so claiming that namespace
// would be a false claim of protocol membership. kdeconnectd ignores it.
//
// The body carries DELTAS — only the controls that changed — because the
// receiving evdev device is itself stateful: a button written as pressed stays
// pressed until it is written as released. That also means this translation
// needs no state of its own.
//
//   {"buttons": {"a": true},  "axes": {"lx": 0.5, "ly": -0.25}}
//   {"releaseAll": true}      // screen backgrounded mid-press
//   {"disconnect": true}      // tear the virtual device down
//
// Sticks are -1.0..1.0 and triggers 0.0..1.0 on the wire — device-independent,
// converted to the device's native ranges here. Same rule the systemvolume
// plugin learned the hard way: normalize on the wire, scale at the sink.
//
// The D-pad travels as the `hat_x`/`hat_y` AXES rather than four buttons.
// As buttons it could not survive being a delta: releasing "left" while
// "right" is held would have to zero the hat, and only the sender knows that
// right is still down.

use crate::packet::NetworkPacket;
use serde_json::Value;

// linux/input-event-codes.h
pub const EV_SYN: u16 = 0x00;
pub const EV_KEY: u16 = 0x01;
pub const EV_ABS: u16 = 0x03;
pub const SYN_REPORT: u16 = 0;

// Face and shoulder buttons. Note the gap: 0x132 is BTN_C, which a modern pad
// does not have, so X is 0x133 and Y is 0x134 — not sequential from A.
pub const BTN_A: u16 = 0x130;
pub const BTN_B: u16 = 0x131;
pub const BTN_X: u16 = 0x133;
pub const BTN_Y: u16 = 0x134;
pub const BTN_TL: u16 = 0x136;
pub const BTN_TR: u16 = 0x137;
pub const BTN_SELECT: u16 = 0x13a;
pub const BTN_START: u16 = 0x13b;
pub const BTN_MODE: u16 = 0x13c;
pub const BTN_THUMBL: u16 = 0x13d;
pub const BTN_THUMBR: u16 = 0x13e;

pub const ABS_X: u16 = 0x00;
pub const ABS_Y: u16 = 0x01;
pub const ABS_Z: u16 = 0x02;
pub const ABS_RX: u16 = 0x03;
pub const ABS_RY: u16 = 0x04;
pub const ABS_RZ: u16 = 0x05;
pub const ABS_HAT0X: u16 = 0x10;
pub const ABS_HAT0Y: u16 = 0x11;

/// Stick deflection, matching what the xpad driver reports for a real 360 pad.
pub const STICK_MAX: i32 = 32767;
/// Triggers are a single byte on a 360 pad; SDL and Steam both expect 0..255.
pub const TRIGGER_MAX: i32 = 255;

/// Every button the virtual device declares, in the order it declares them.
pub const ALL_BUTTONS: [u16; 11] = [
    BTN_A, BTN_B, BTN_X, BTN_Y, BTN_TL, BTN_TR, BTN_SELECT, BTN_START, BTN_MODE, BTN_THUMBL,
    BTN_THUMBR,
];

/// Every axis the virtual device declares. All of them rest at zero, including
/// the triggers, so "release everything" is just zero across the board.
pub const ALL_AXES: [u16; 8] = [
    ABS_X, ABS_Y, ABS_RX, ABS_RY, ABS_Z, ABS_RZ, ABS_HAT0X, ABS_HAT0Y,
];

#[derive(Debug, Clone, PartialEq)]
pub enum GamepadEvent {
    Button { code: u16, pressed: bool },
    Axis { code: u16, value: i32 },
    /// Release every control but keep the virtual device: the phone's gamepad
    /// screen went to the background while something was held down.
    ReleaseAll,
    /// Release everything and destroy the device. A virtual pad that outlived
    /// the connection would sit in every game's controller list forever.
    Disconnect,
}

#[derive(Clone, Copy)]
enum Range {
    Stick,
    Trigger,
    Hat,
}

fn button_code(name: &str) -> Option<u16> {
    Some(match name {
        "a" => BTN_A,
        "b" => BTN_B,
        "x" => BTN_X,
        "y" => BTN_Y,
        "lb" => BTN_TL,
        "rb" => BTN_TR,
        "back" => BTN_SELECT,
        "start" => BTN_START,
        "guide" => BTN_MODE,
        "thumbl" => BTN_THUMBL,
        "thumbr" => BTN_THUMBR,
        _ => return None,
    })
}

fn axis_spec(name: &str) -> Option<(u16, Range)> {
    Some(match name {
        "lx" => (ABS_X, Range::Stick),
        "ly" => (ABS_Y, Range::Stick),
        "rx" => (ABS_RX, Range::Stick),
        "ry" => (ABS_RY, Range::Stick),
        "lt" => (ABS_Z, Range::Trigger),
        "rt" => (ABS_RZ, Range::Trigger),
        "hat_x" => (ABS_HAT0X, Range::Hat),
        "hat_y" => (ABS_HAT0Y, Range::Hat),
        _ => return None,
    })
}

/// Clamping is not defensive noise: an out-of-range value from a buggy or
/// hostile sender would otherwise be cast to a wrapped i32 and jam the stick.
fn scale(range: Range, value: f64) -> i32 {
    if !value.is_finite() {
        return 0;
    }
    match range {
        Range::Stick => (value.clamp(-1.0, 1.0) * STICK_MAX as f64).round() as i32,
        Range::Trigger => (value.clamp(0.0, 1.0) * TRIGGER_MAX as f64).round() as i32,
        Range::Hat => value.clamp(-1.0, 1.0).round() as i32,
    }
}

/// One packet becomes one input frame — the caller writes a single SYN_REPORT
/// after the whole batch, so a diagonal stick move lands atomically.
pub fn to_events(packet: &NetworkPacket) -> Vec<GamepadEvent> {
    if packet.get_bool("disconnect") {
        return vec![GamepadEvent::Disconnect];
    }

    let mut events = Vec::new();

    // Before the new state, never after: a packet may both release a stuck
    // press and set what is held now.
    if packet.get_bool("releaseAll") {
        events.push(GamepadEvent::ReleaseAll);
    }

    if let Some(buttons) = packet.body.get("buttons").and_then(Value::as_object) {
        for (name, value) in buttons {
            let (Some(code), Some(pressed)) = (button_code(name), value.as_bool()) else {
                continue;
            };
            events.push(GamepadEvent::Button { code, pressed });
        }
    }

    if let Some(axes) = packet.body.get("axes").and_then(Value::as_object) {
        for (name, value) in axes {
            let (Some((code, range)), Some(raw)) = (axis_spec(name), value.as_f64()) else {
                continue;
            };
            events.push(GamepadEvent::Axis { code, value: scale(range, raw) });
        }
    }

    events
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::packet::TYPE_GAMEPAD;

    fn packet(json_body: &str) -> NetworkPacket {
        NetworkPacket::parse(&format!(
            r#"{{"id":1,"type":"{TYPE_GAMEPAD}","body":{json_body}}}"#
        ))
        .unwrap()
    }

    fn axis(events: &[GamepadEvent], code: u16) -> Option<i32> {
        events.iter().find_map(|e| match e {
            GamepadEvent::Axis { code: c, value } if *c == code => Some(*value),
            _ => None,
        })
    }

    #[test]
    fn sticks_span_the_full_signed_range() {
        let events = to_events(&packet(r#"{"axes":{"lx":1.0,"ly":-1.0}}"#));
        assert_eq!(axis(&events, ABS_X), Some(32767));
        assert_eq!(axis(&events, ABS_Y), Some(-32767));
    }

    #[test]
    fn out_of_range_axes_are_clamped_not_wrapped() {
        // Without the clamp this becomes a nonsense i32 and the stick jams.
        let events = to_events(&packet(r#"{"axes":{"lx":1e9,"rx":-1e9}}"#));
        assert_eq!(axis(&events, ABS_X), Some(STICK_MAX));
        assert_eq!(axis(&events, ABS_RX), Some(-STICK_MAX));
    }

    #[test]
    fn non_numeric_axis_values_produce_no_event() {
        let events = to_events(&packet(r#"{"axes":{"lx":null,"ly":"half"}}"#));
        assert!(events.is_empty());
    }

    #[test]
    fn non_finite_axes_rest_at_centre() {
        // JSON cannot carry NaN or Infinity, so this can only arrive from a
        // future sender or a hand-rolled client — but `Infinity as i32`
        // saturates to i32::MAX, which would pin the stick permanently.
        assert_eq!(scale(Range::Stick, f64::NAN), 0);
        assert_eq!(scale(Range::Stick, f64::INFINITY), 0);
        assert_eq!(scale(Range::Trigger, f64::NEG_INFINITY), 0);
    }

    #[test]
    fn triggers_use_their_own_byte_range() {
        // A trigger scaled like a stick would report 32767 on a 0..255 axis.
        let events = to_events(&packet(r#"{"axes":{"lt":1.0,"rt":0.5}}"#));
        assert_eq!(axis(&events, ABS_Z), Some(255));
        assert_eq!(axis(&events, ABS_RZ), Some(128));
    }

    #[test]
    fn negative_trigger_rests_at_zero() {
        let events = to_events(&packet(r#"{"axes":{"lt":-0.5}}"#));
        assert_eq!(axis(&events, ABS_Z), Some(0));
    }

    #[test]
    fn dpad_travels_as_an_integral_hat() {
        let events = to_events(&packet(r#"{"axes":{"hat_x":-1.0,"hat_y":1.0}}"#));
        assert_eq!(axis(&events, ABS_HAT0X), Some(-1));
        assert_eq!(axis(&events, ABS_HAT0Y), Some(1));
    }

    #[test]
    fn face_buttons_skip_the_btn_c_gap() {
        // A sequential table would make X 0x132 (BTN_C), which pads do not
        // report and SDL does not map.
        assert_eq!(button_code("a"), Some(0x130));
        assert_eq!(button_code("b"), Some(0x131));
        assert_eq!(button_code("x"), Some(0x133));
        assert_eq!(button_code("y"), Some(0x134));
    }

    #[test]
    fn button_press_and_release_are_distinct_events() {
        let down = to_events(&packet(r#"{"buttons":{"a":true}}"#));
        let up = to_events(&packet(r#"{"buttons":{"a":false}}"#));
        assert_eq!(down, vec![GamepadEvent::Button { code: BTN_A, pressed: true }]);
        assert_eq!(up, vec![GamepadEvent::Button { code: BTN_A, pressed: false }]);
    }

    #[test]
    fn release_all_comes_before_the_state_it_precedes() {
        // Applied after, it would wipe the very press the packet is announcing.
        let events = to_events(&packet(r#"{"releaseAll":true,"buttons":{"a":true}}"#));
        assert_eq!(events[0], GamepadEvent::ReleaseAll);
        assert_eq!(events[1], GamepadEvent::Button { code: BTN_A, pressed: true });
    }

    #[test]
    fn disconnect_supersedes_everything_else_in_the_packet() {
        let events = to_events(&packet(r#"{"disconnect":true,"buttons":{"a":true}}"#));
        assert_eq!(events, vec![GamepadEvent::Disconnect]);
    }

    #[test]
    fn unknown_controls_are_dropped_not_guessed() {
        let events = to_events(&packet(r#"{"buttons":{"turbo":true},"axes":{"gyro":0.5}}"#));
        assert!(events.is_empty());
    }

    #[test]
    fn empty_packet_emits_nothing() {
        assert!(to_events(&packet("{}")).is_empty());
    }

    #[test]
    fn declared_controls_cover_every_name_the_wire_accepts() {
        // The virtual device must declare everything a packet can name, or
        // those events are silently swallowed by the kernel.
        for name in ["a", "b", "x", "y", "lb", "rb", "back", "start", "guide", "thumbl", "thumbr"] {
            let code = button_code(name).expect(name);
            assert!(ALL_BUTTONS.contains(&code), "{name} not declared");
        }
        for name in ["lx", "ly", "rx", "ry", "lt", "rt", "hat_x", "hat_y"] {
            let (code, _) = axis_spec(name).expect(name);
            assert!(ALL_AXES.contains(&code), "{name} not declared");
        }
    }
}
