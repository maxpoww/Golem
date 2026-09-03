// Newline-terminated JSON packets — the KDE Connect wire format.
//
// One packet per line. `payloadSize`/`payloadTransferInfo` describe an
// out-of-band binary transfer on its own socket; golem-connectd does not
// need payloads yet, but the fields round-trip so nothing is lost.

use anyhow::{bail, Result};
use serde_json::{json, Map, Value};
use std::time::{SystemTime, UNIX_EPOCH};

pub const TYPE_IDENTITY: &str = "kdeconnect.identity";
pub const TYPE_PAIR: &str = "kdeconnect.pair";
pub const TYPE_MOUSEPAD_REQUEST: &str = "kdeconnect.mousepad.request";
pub const TYPE_PING: &str = "kdeconnect.ping";
/// A Golem extension, not a KDE Connect packet — hence the namespace. See
/// `gamepad.rs`.
pub const TYPE_GAMEPAD: &str = "golem.gamepad";
/// A Golem extension: the phone asks for its screen to be mirrored here.
/// See `mirror.rs`.
pub const TYPE_MIRROR: &str = "golem.mirror";
/// The answer to a `golem.mirror` request — scrcpy can fail for reasons the
/// phone cannot see, so it is told rather than left guessing.
pub const TYPE_MIRROR_STATE: &str = "golem.mirror.state";

#[derive(Debug, Clone)]
pub struct NetworkPacket {
    pub id: i64,
    pub packet_type: String,
    pub body: Map<String, Value>,
}

impl NetworkPacket {
    pub fn new(packet_type: &str) -> Self {
        Self {
            id: now_ms(),
            packet_type: packet_type.to_string(),
            body: Map::new(),
        }
    }

    pub fn parse(line: &str) -> Result<Self> {
        let value: Value = serde_json::from_str(line)?;
        let Some(packet_type) = value.get("type").and_then(Value::as_str) else {
            bail!("packet has no type");
        };
        let body = value
            .get("body")
            .and_then(Value::as_object)
            .cloned()
            .unwrap_or_default();
        Ok(Self {
            id: value.get("id").and_then(Value::as_i64).unwrap_or_else(now_ms),
            packet_type: packet_type.to_string(),
            body,
        })
    }

    /// Serialize with the trailing newline the protocol frames on.
    pub fn serialize(&self) -> String {
        let value = json!({
            "id": self.id,
            "type": self.packet_type,
            "body": Value::Object(self.body.clone()),
        });
        format!("{value}\n")
    }

    pub fn put(&mut self, key: &str, value: impl Into<Value>) -> &mut Self {
        self.body.insert(key.to_string(), value.into());
        self
    }

    pub fn get_str(&self, key: &str) -> Option<&str> {
        self.body.get(key).and_then(Value::as_str)
    }

    pub fn get_f64(&self, key: &str) -> Option<f64> {
        self.body.get(key).and_then(Value::as_f64)
    }

    pub fn get_i64(&self, key: &str) -> Option<i64> {
        self.body.get(key).and_then(Value::as_i64)
    }

    pub fn get_bool(&self, key: &str) -> bool {
        self.body.get(key).and_then(Value::as_bool).unwrap_or(false)
    }
}

pub fn now_ms() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0)
}

pub fn now_secs() -> i64 {
    now_ms() / 1000
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn framing_ends_with_exactly_one_newline() {
        let packet = NetworkPacket::new(TYPE_PING);
        let wire = packet.serialize();
        assert!(wire.ends_with('\n'));
        assert_eq!(wire.matches('\n').count(), 1, "one packet is one line");
    }

    #[test]
    fn round_trips_body_fields() {
        let mut packet = NetworkPacket::new(TYPE_MOUSEPAD_REQUEST);
        packet.put("dx", 12.5).put("dy", -3.0).put("scroll", true);
        let parsed = NetworkPacket::parse(packet.serialize().trim_end()).unwrap();
        assert_eq!(parsed.packet_type, TYPE_MOUSEPAD_REQUEST);
        assert_eq!(parsed.get_f64("dx"), Some(12.5));
        assert_eq!(parsed.get_f64("dy"), Some(-3.0));
        assert!(parsed.get_bool("scroll"));
    }

    #[test]
    fn missing_type_is_rejected() {
        assert!(NetworkPacket::parse(r#"{"id":1,"body":{}}"#).is_err());
    }

    #[test]
    fn absent_bool_is_false_not_error() {
        let parsed = NetworkPacket::parse(r#"{"id":1,"type":"x","body":{}}"#).unwrap();
        assert!(!parsed.get_bool("scroll"));
    }
}
