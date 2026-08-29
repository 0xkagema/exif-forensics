use serde::{Deserialize, Serialize};

/// Main response returned by the C2PA parser.
/// Always serializable to JSON for Flutter / WASM consumption.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct C2paResponse {
    /// Whether the parsing process succeeded without unexpected fatal errors.
    pub success: bool,

    /// Whether a C2PA manifest/metadata was found in the image.
    pub has_c2pa: bool,

    /// Human-readable status or error message.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub message: Option<String>,

    /// Specific error details if success is false.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,

    /// Detected or provided MIME type / format of the image.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub format: Option<String>,

    /// Whether the image was determined to be AI generated or modified by AI.
    pub is_ai_generated: bool,

    /// Detailed AI generation information extracted from C2PA actions and metadata.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ai_details: Option<AiDetails>,

    /// Signature and certificate details of the active manifest.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub signature: Option<SignatureDetails>,

    /// Summary of the active manifest.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub manifest: Option<ManifestSummary>,

    /// Summary of ingredient assets in the provenance chain (if any).
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub ingredients: Vec<IngredientSummary>,

    /// List of actions performed on the asset across its provenance history.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub actions: Vec<ActionSummary>,

    /// Detailed validation results (cryptographic signature validity, trust status, etc.).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub validation: Option<ValidationSummary>,

    /// Full raw C2PA manifest JSON.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub raw_manifest: Option<serde_json::Value>,
}

impl C2paResponse {
    /// Helper to construct a response when no C2PA manifest is present in the image.
    pub fn no_manifest(message: impl Into<String>, format: Option<String>) -> Self {
        Self {
            success: true,
            has_c2pa: false,
            message: Some(message.into()),
            error: None,
            format,
            is_ai_generated: false,
            ai_details: None,
            signature: None,
            manifest: None,
            ingredients: Vec::new(),
            actions: Vec::new(),
            validation: None,
            raw_manifest: None,
        }
    }

    /// Helper to construct an error response.
    pub fn error(error_message: impl Into<String>, format: Option<String>) -> Self {
        Self {
            success: false,
            has_c2pa: false,
            message: None,
            error: Some(error_message.into()),
            format,
            is_ai_generated: false,
            ai_details: None,
            signature: None,
            manifest: None,
            ingredients: Vec::new(),
            actions: Vec::new(),
            validation: None,
            raw_manifest: None,
        }
    }

    /// Convert this response into a pretty JSON string.
    pub fn to_json_pretty(&self) -> String {
        serde_json::to_string_pretty(self).unwrap_or_else(|e| {
            format!(r#"{{"success":false,"has_c2pa":false,"error":"JSON serialization failed: {e}"}}"#)
        })
    }

    /// Convert this response into a compact JSON string.
    pub fn to_json(&self) -> String {
        serde_json::to_string(self).unwrap_or_else(|e| {
            format!(r#"{{"success":false,"has_c2pa":false,"error":"JSON serialization failed: {e}"}}"#)
        })
    }
}

/// Extracted information regarding AI model and generation.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
pub struct AiDetails {
    /// Whether AI indicators were detected.
    pub is_ai_generated: bool,

    /// Name of the AI model (e.g. "gpt-image", "GPT-4o", "DALL-E 3", "Adobe Firefly", "Midjourney").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model_name: Option<String>,

    /// Version of the AI model (e.g. "2.0", "3").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model_version: Option<String>,

    /// Combined display name (e.g. "gpt-image 2.0", "GPT-4o").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model_display: Option<String>,

    /// Company / Organization behind the AI model (e.g. "OpenAI OpCo, LLC", "OpenAI", "Adobe Inc.").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub company: Option<String>,

    /// IPTC digital source type URI or description (e.g. "http://cv.iptc.org/newscodes/digitalsourcetype/trainedAlgorithmicMedia").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub digital_source_type: Option<String>,

    /// The date and time when the image was generated (e.g. ISO 8601 string).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub generation_time: Option<String>,

    /// Just the date part (e.g. "2026-08-25") for easy display.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub generation_date: Option<String>,

    /// Software agent or generator info string.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub software_agent: Option<String>,

    /// Claim generator tool info (e.g. "OpenAI Media Service API", "ChatGPT").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub claim_generator: Option<String>,

    /// Specific generator or application name (e.g. "ChatGPT", "DALL-E", "Photoshop").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub generator_app: Option<String>,
}

/// Signature and cryptographic certificate information.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
pub struct SignatureDetails {
    /// Issuer of the certificate (e.g. "OpenAI OpCo, LLC", "OpenAI").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub issuer: Option<String>,

    /// Common Name (CN) of the certificate subject (e.g. "OpenAI Media Service", "Truepic Lens CLI in Sora").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub common_name: Option<String>,

    /// Cryptographic signing algorithm used (e.g. "Es256", "Ed25519", "Ps256").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub algorithm: Option<String>,

    /// Signing timestamp from the signature.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub signing_time: Option<String>,

    /// Certificate serial number.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cert_serial_number: Option<String>,

    /// Overall validation state (e.g. "Valid", "Trusted", "Invalid").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub validation_state: Option<String>,

    /// Whether the cryptographic signature and assertion hashes are valid.
    pub is_signature_valid: bool,

    /// Whether the certificate chains up to a known trusted root in the trust store.
    pub is_trusted: bool,
}

/// Summary of a C2PA manifest (active or ingredient).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
pub struct ManifestSummary {
    /// Manifest URI/label (e.g. "urn:c2pa:bc7b498a-28c0-4a2c-a79c-96fc7b50f7df").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub label: Option<String>,

    /// Title of the asset (e.g. "image.png").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,

    /// Format MIME type recorded in the manifest.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub format: Option<String>,

    /// Instance ID (e.g. "xmp:iid:599a47c3-9ced-4c4c-bd3a-4fb8d0cc0682").
    #[serde(skip_serializing_if = "Option::is_none")]
    pub instance_id: Option<String>,

    /// Claim version (e.g. 1 or 2).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub claim_version: Option<u8>,

    /// Claim generator application / library string.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub claim_generator: Option<String>,
}

/// Summary of an ingredient in the provenance chain.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
pub struct IngredientSummary {
    /// Manifest URI / label of the ingredient.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub label: Option<String>,

    /// Title of the ingredient asset.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,

    /// Format MIME type of the ingredient.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub format: Option<String>,

    /// Instance ID.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub instance_id: Option<String>,

    /// Generator of the ingredient manifest.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub claim_generator: Option<String>,

    /// Whether this ingredient was generated by AI.
    pub is_ai_generated: bool,

    /// AI model used in this ingredient.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ai_model: Option<String>,
}

/// Description of a single action in the provenance history.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ActionSummary {
    /// Action verb (e.g. "c2pa.created", "c2pa.converted", "c2pa.watermarked.unbound", "c2pa.opened", "c2pa.edited").
    pub action: String,

    /// When the action occurred.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub when: Option<String>,

    /// Software agent that performed the action.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub software_agent: Option<String>,

    /// Software agent name.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub software_agent_name: Option<String>,

    /// Software agent version.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub software_agent_version: Option<String>,

    /// Digital source type URI (e.g. trainedAlgorithmicMedia).
    #[serde(skip_serializing_if = "Option::is_none")]
    pub digital_source_type: Option<String>,

    /// Whether this specific action indicates AI creation or modification.
    pub is_ai_action: bool,

    /// Manifest label this action belongs to.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub manifest_label: Option<String>,

    /// Optional action description or parameters.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
}

/// Detailed validation findings.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
pub struct ValidationSummary {
    /// Validation state ("Valid", "Trusted", "Invalid").
    pub state: String,

    /// Whether cryptographic verification succeeded.
    pub is_valid: bool,

    /// Whether the signer certificate is verified by a trusted root.
    pub is_trusted: bool,

    /// List of validation success messages.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub successes: Vec<ValidationEntry>,

    /// List of validation informational messages (e.g., untrusted cert notices).
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub informational: Vec<ValidationEntry>,

    /// List of validation failure messages.
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub failures: Vec<ValidationEntry>,
}

/// Single validation status log entry.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ValidationEntry {
    pub code: String,
    pub explanation: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,
}
