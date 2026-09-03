// TLS identity and the pairing verification code.
//
// The verification code must match kdeconnect (and Golem Android's
// PairingCrypto) byte for byte, or the two screens show different codes and
// pairing is unverifiable. Kept free of I/O so it can be unit tested.

use anyhow::{Context, Result};
use sha2::{Digest, Sha256};
use std::path::Path;

/// SHA-256 over both SPKI DER public keys — **larger first** by unsigned byte
/// comparison — followed by the pairing timestamp as a decimal string. The
/// code is the first 4 bytes as uppercase hex.
///
/// The spec says the keys are ordered "alphabetically"; the reference
/// implementations put the larger array first. The code interoperates, the
/// prose does not.
pub fn verification_key(own_spki: &[u8], peer_spki: &[u8], timestamp: i64) -> String {
    let mut hasher = Sha256::new();
    let (first, second) = if compare_unsigned(own_spki, peer_spki) < 0 {
        (peer_spki, own_spki)
    } else {
        (own_spki, peer_spki)
    };
    hasher.update(first);
    hasher.update(second);
    hasher.update(timestamp.to_string().as_bytes());
    hasher.finalize()[..4]
        .iter()
        .map(|b| format!("{b:02X}"))
        .collect()
}

/// Java's `Byte` is signed; comparing raw bytes as signed flips ordering for
/// anything >= 0x80 and silently yields a different code on ~half of keys.
pub fn compare_unsigned(a: &[u8], b: &[u8]) -> i32 {
    for i in 0..a.len().min(b.len()) {
        let diff = a[i] as i32 - b[i] as i32;
        if diff != 0 {
            return diff;
        }
    }
    a.len() as i32 - b.len() as i32
}

/// Extract the SubjectPublicKeyInfo DER from a certificate — that, not the
/// whole certificate, is what the verification code hashes.
pub fn spki_der(cert_der: &[u8]) -> Result<Vec<u8>> {
    let (_, cert) = x509_parser::parse_x509_certificate(cert_der)
        .context("peer certificate is not valid X.509")?;
    Ok(cert.tbs_certificate.subject_pki.raw.to_vec())
}

pub struct Identity {
    pub cert_der: Vec<u8>,
    pub key_der: Vec<u8>,
}

/// Load the persisted self-signed certificate, generating it on first run.
/// CN must equal the deviceId — peers check it.
pub fn load_or_create_identity(dir: &Path, device_id: &str) -> Result<Identity> {
    std::fs::create_dir_all(dir).context("creating state dir")?;
    let cert_path = dir.join("certificate.pem");
    let key_path = dir.join("private.pem");

    if cert_path.exists() && key_path.exists() {
        let cert_pem = std::fs::read(&cert_path)?;
        let key_pem = std::fs::read(&key_path)?;
        let cert_der = rustls_pemfile::certs(&mut cert_pem.as_slice())
            .next()
            .context("no certificate in certificate.pem")??
            .to_vec();
        let key_der = rustls_pemfile::private_key(&mut key_pem.as_slice())?
            .context("no private key in private.pem")?
            .secret_der()
            .to_vec();
        return Ok(Identity { cert_der, key_der });
    }

    let mut params = rcgen::CertificateParams::new(vec![device_id.to_string()])?;
    let mut name = rcgen::DistinguishedName::new();
    name.push(rcgen::DnType::CommonName, device_id);
    name.push(rcgen::DnType::OrganizationName, "Golem");
    name.push(rcgen::DnType::OrganizationalUnitName, "Golem");
    params.distinguished_name = name;

    let key_pair = rcgen::KeyPair::generate()?;
    let cert = params.self_signed(&key_pair)?;

    std::fs::write(&cert_path, cert.pem())?;
    std::fs::write(&key_path, key_pair.serialize_pem())?;
    // The private key is exactly as sensitive as it sounds.
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        std::fs::set_permissions(&key_path, std::fs::Permissions::from_mode(0o600))?;
    }

    Ok(Identity {
        cert_der: cert.der().to_vec(),
        key_der: key_pair.serialize_der(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn unsigned_compare_does_not_sign_flip() {
        // 0x80 as a signed byte is negative; as unsigned it outranks 0x7F.
        assert!(compare_unsigned(&[0x80], &[0x7F]) > 0);
        assert!(compare_unsigned(&[0x00], &[0xFF]) < 0);
    }

    #[test]
    fn compare_falls_back_to_length() {
        assert!(compare_unsigned(&[1, 2], &[1, 2, 3]) < 0);
        assert_eq!(compare_unsigned(&[1, 2], &[1, 2]), 0);
    }

    #[test]
    fn verification_key_is_order_independent() {
        // Both devices must derive the same code from opposite viewpoints.
        let a = vec![0x30, 0x81, 0x9F, 0x00];
        let b = vec![0x30, 0x81, 0x8A, 0xFF];
        assert_eq!(
            verification_key(&a, &b, 1788438000),
            verification_key(&b, &a, 1788438000)
        );
    }

    #[test]
    fn verification_key_depends_on_timestamp() {
        let a = vec![0x01];
        let b = vec![0x02];
        assert_ne!(
            verification_key(&a, &b, 1788438000),
            verification_key(&a, &b, 1788438001)
        );
    }

    #[test]
    fn verification_key_is_eight_uppercase_hex() {
        let key = verification_key(&[0xAB, 0xCD], &[0x01], 42);
        assert_eq!(key.len(), 8);
        assert!(key.chars().all(|c| c.is_ascii_digit() || c.is_ascii_uppercase()));
    }
}
