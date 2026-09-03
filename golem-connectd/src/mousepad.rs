// kdeconnect.mousepad.request -> InputEvent.
//
// Pure translation, no I/O, so the packet-shape rules are unit tested rather
// than discovered by dragging a finger on a phone.

use crate::input::{
    special_key, InputEvent, BTN_LEFT, BTN_MIDDLE, BTN_RIGHT, KEY_LEFTALT, KEY_LEFTCTRL,
    KEY_LEFTMETA, KEY_LEFTSHIFT,
};
use crate::packet::NetworkPacket;

/// A single packet can carry a click, a key, or a motion — never a mix, in
/// practice — but the order matters: a motion packet with `scroll: true` is a
/// scroll, not a move.
pub fn to_events(packet: &NetworkPacket) -> Vec<InputEvent> {
    let mut events = Vec::new();

    if packet.get_bool("singleclick") {
        events.push(InputEvent::PointerButtonClick { button: BTN_LEFT });
    }
    if packet.get_bool("middleclick") {
        events.push(InputEvent::PointerButtonClick { button: BTN_MIDDLE });
    }
    if packet.get_bool("rightclick") {
        events.push(InputEvent::PointerButtonClick { button: BTN_RIGHT });
    }

    if let Some(n) = packet.get_i64("specialKey") {
        if let Some(keycode) = special_key(n) {
            events.push(InputEvent::Key { keycode, modifiers: modifiers(packet) });
        }
    } else if let Some(text) = packet.get_str("key") {
        if !text.is_empty() {
            let mods = modifiers(packet);
            if mods.is_empty() {
                events.push(InputEvent::Text(text.to_string()));
            } else {
                // Ctrl+C and friends: the character is a keystroke, not text.
                if let Some((keycode, _)) = crate::input::char_to_key(
                    text.chars().next().unwrap_or_default(),
                ) {
                    events.push(InputEvent::Key { keycode, modifiers: mods });
                }
            }
        }
    }

    // Motion last: a packet carrying only dx/dy is the common case.
    let dx = packet.get_f64("dx").unwrap_or(0.0);
    let dy = packet.get_f64("dy").unwrap_or(0.0);
    if dx != 0.0 || dy != 0.0 {
        if packet.get_bool("scroll") {
            events.push(InputEvent::Scroll { dx, dy });
        } else {
            events.push(InputEvent::PointerMotion { dx, dy });
        }
    }

    events
}

fn modifiers(packet: &NetworkPacket) -> Vec<u32> {
    let mut mods = Vec::new();
    if packet.get_bool("ctrl") {
        mods.push(KEY_LEFTCTRL);
    }
    if packet.get_bool("alt") {
        mods.push(KEY_LEFTALT);
    }
    if packet.get_bool("shift") {
        mods.push(KEY_LEFTSHIFT);
    }
    if packet.get_bool("super") {
        mods.push(KEY_LEFTMETA);
    }
    mods
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::packet::TYPE_MOUSEPAD_REQUEST;

    fn packet(json_body: &str) -> NetworkPacket {
        NetworkPacket::parse(&format!(
            r#"{{"id":1,"type":"{TYPE_MOUSEPAD_REQUEST}","body":{json_body}}}"#
        ))
        .unwrap()
    }

    #[test]
    fn plain_dx_dy_is_motion() {
        let events = to_events(&packet(r#"{"dx":10.0,"dy":-4.0}"#));
        assert!(matches!(
            events.as_slice(),
            [InputEvent::PointerMotion { dx, dy }] if *dx == 10.0 && *dy == -4.0
        ));
    }

    #[test]
    fn scroll_flag_turns_motion_into_scroll() {
        // The same dx/dy with `scroll` must NOT move the cursor.
        let events = to_events(&packet(r#"{"dx":0.0,"dy":8.0,"scroll":true}"#));
        assert!(matches!(events.as_slice(), [InputEvent::Scroll { .. }]));
    }

    #[test]
    fn zero_motion_emits_nothing() {
        assert!(to_events(&packet(r#"{"dx":0.0,"dy":0.0}"#)).is_empty());
    }

    #[test]
    fn clicks_map_to_distinct_buttons() {
        let left = to_events(&packet(r#"{"singleclick":true}"#));
        let right = to_events(&packet(r#"{"rightclick":true}"#));
        let middle = to_events(&packet(r#"{"middleclick":true}"#));
        assert!(matches!(left.as_slice(), [InputEvent::PointerButtonClick { button }] if *button == BTN_LEFT));
        assert!(matches!(right.as_slice(), [InputEvent::PointerButtonClick { button }] if *button == BTN_RIGHT));
        assert!(matches!(middle.as_slice(), [InputEvent::PointerButtonClick { button }] if *button == BTN_MIDDLE));
    }

    #[test]
    fn printable_key_is_text() {
        let events = to_events(&packet(r#"{"key":"g"}"#));
        assert!(matches!(events.as_slice(), [InputEvent::Text(t)] if t == "g"));
    }

    #[test]
    fn key_with_modifier_becomes_a_keystroke_not_text() {
        // Ctrl+C typed as text would insert the letter "c" instead of copying.
        let events = to_events(&packet(r#"{"key":"c","ctrl":true}"#));
        assert!(matches!(
            events.as_slice(),
            [InputEvent::Key { keycode, modifiers }]
                if *keycode == 46 && modifiers == &vec![KEY_LEFTCTRL]
        ));
    }

    #[test]
    fn special_key_wins_over_key_field() {
        let events = to_events(&packet(r#"{"specialKey":12}"#));
        assert!(matches!(
            events.as_slice(),
            [InputEvent::Key { keycode, .. }] if *keycode == crate::input::KEY_ENTER
        ));
    }

    #[test]
    fn unknown_special_key_is_dropped() {
        assert!(to_events(&packet(r#"{"specialKey":99}"#)).is_empty());
    }
}
