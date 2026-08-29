use crate::api::parser::parse_c2pa_from_bytes;

#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}

#[flutter_rust_bridge::frb(sync)]
pub fn parse_c2pa(image_bytes: &[u8], mime_type: Option<String>) -> String {
    let result = parse_c2pa_from_bytes(image_bytes, mime_type.as_deref());
    result.to_json()
}

/// WASM binding returning pretty-printed JSON for inspection and debugging.
pub fn parse_c2pa_pretty(image_bytes: &[u8], mime_type: Option<String>) -> String {
    let result = parse_c2pa_from_bytes(image_bytes, mime_type.as_deref());
    result.to_json_pretty()
}
