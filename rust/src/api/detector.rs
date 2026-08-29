/// Detect MIME type and format from the leading magic bytes of a file/buffer.
/// More on magic bytes => https://tool.lu/en_US/magicbytes/
pub fn detect_mime_type(bytes: &[u8]) -> Option<&'static str> {
    if bytes.len() < 4 {
        return None;
    }

    // JPEG: FF D8 FF
    if bytes.len() >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
        return Some("image/jpeg");
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if bytes.starts_with(&[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
        return Some("image/png");
    }

    // WebP: RIFF ???? WEBP
    if bytes.len() >= 12 && &bytes[0..4] == b"RIFF" && &bytes[8..12] == b"WEBP" {
        return Some("image/webp");
    }

    // GIF: GIF87a or GIF89a
    if bytes.len() >= 6 && (&bytes[0..6] == b"GIF87a" || &bytes[0..6] == b"GIF89a") {
        return Some("image/gif");
    }

    // TIFF: II*\0 (little endian) or MM\0* (big endian)
    if bytes.starts_with(b"II\x2A\x00") || bytes.starts_with(b"MM\x00\x2A") {
        return Some("image/tiff");
    }

    // ISO base media file format (AVIF, HEIC, MP4, etc.)
    // Starts with [size 4 bytes] 'ftyp' [major_brand 4 bytes]
    if bytes.len() >= 12 && &bytes[4..8] == b"ftyp" {
        let brand = &bytes[8..12];
        match brand {
            b"avif" | b"avis" => return Some("image/avif"),
            b"heic" | b"heix" | b"mif1" | b"msf1" | b"hevc" => return Some("image/heic"),
            b"mp41" | b"mp42" | b"isom" | b"iso2" | b"M4V " => return Some("video/mp4"),
            _ => {
                // Check compatible brands if present
                if bytes.len() >= 16 {
                    let chunk = &bytes[12..];
                    if chunk.windows(4).any(|w| w == b"avif") {
                        return Some("image/avif");
                    }
                    if chunk.windows(4).any(|w| w == b"heic" || w == b"mif1") {
                        return Some("image/heic");
                    }
                }
                return Some("application/octet-stream");
            }
        }
    }

    // SVG / XML detection
    let preview_len = bytes.len().min(128);
    if let Ok(text) = std::str::from_utf8(&bytes[..preview_len]) {
        let trimmed = text.trim_start();
        if trimmed.starts_with("<?xml") || trimmed.starts_with("<svg") {
            return Some("image/svg+xml");
        }
    }

    None
}

/// Normalize user provided format / extension or auto-detect from bytes.
pub fn resolve_format(bytes: &[u8], format_hint: Option<&str>) -> Option<String> {
    if let Some(hint) = format_hint {
        let trimmed = hint.trim().to_lowercase();
        if !trimmed.is_empty() && trimmed != "auto" {
            let normalized = match trimmed.as_str() {
                "jpg" | "jpeg" | "image/jpg" | "image/jpeg" => "image/jpeg",
                "png" | "image/png" => "image/png",
                "webp" | "image/webp" => "image/webp",
                "gif" | "image/gif" => "image/gif",
                "avif" | "image/avif" => "image/avif",
                "heic" | "image/heic" => "image/heic",
                "heif" | "image/heif" => "image/heif",
                "tif" | "tiff" | "image/tiff" => "image/tiff",
                "svg" | "image/svg+xml" => "image/svg+xml",
                "mp4" | "video/mp4" => "video/mp4",
                other => {
                    if other.contains('/') {
                        return Some(other.to_string());
                    } else {
                        return Some(format!("image/{other}"));
                    }
                }
            };
            return Some(normalized.to_string());
        }
    }

    detect_mime_type(bytes).map(|s| s.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_jpeg_detection() {
        let sample = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10];
        assert_eq!(detect_mime_type(&sample), Some("image/jpeg"));
    }

    #[test]
    fn test_png_detection() {
        let sample = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00];
        assert_eq!(detect_mime_type(&sample), Some("image/png"));
    }

    #[test]
    fn test_webp_detection() {
        let mut sample = Vec::new();
        sample.extend_from_slice(b"RIFF");
        sample.extend_from_slice(&[0x00, 0x00, 0x00, 0x00]);
        sample.extend_from_slice(b"WEBP");
        assert_eq!(detect_mime_type(&sample), Some("image/webp"));
    }

    #[test]
    fn test_resolve_format_hint() {
        let sample = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
        assert_eq!(
            resolve_format(&sample, Some("jpg")),
            Some("image/jpeg".to_string())
        );
        assert_eq!(resolve_format(&sample, None), Some("image/png".to_string()));
    }
}
