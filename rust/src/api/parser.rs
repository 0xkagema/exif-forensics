use c2pa::{Context, Manifest, Reader, ValidationState, assertions::Actions};
use std::io::Cursor;

use crate::api::{
    detector::resolve_format,
    types::{
        ActionSummary, AiDetails, C2paResponse, IngredientSummary, ManifestSummary,
        SignatureDetails, ValidationEntry, ValidationSummary,
    },
};

/// Known IPTC digital source type URIs and keywords indicating AI generation
const AI_SOURCE_KEYWORDS: &[&str] = &[
    "trainedalgorithmicmedia",
    "algorithmicmedia",
    "compositewithtrainedalgorithmicmedia",
    "syntheticmedia",
    "datadrivenmedia",
    "virtualrecording",
];

/// Known AI model or generator name keywords
const AI_AGENT_KEYWORDS: &[&str] = &[
    "gpt-image",
    "gpt-4",
    "gpt-3",
    "gpt",
    "chatgpt",
    "dall-e",
    "dalle",
    "midjourney",
    "firefly",
    "adobe firefly",
    "stable diffusion",
    "sdxl",
    "stability",
    "flux",
    "imagen",
    "sora",
    "runway",
    "gen-2",
    "gen-3",
    "bing image creator",
    "copilot designer",
    "leonardo.ai",
    "ideogram",
    "craiyon",
    "pika",
    "kling",
    "luma",
];

/// Parse C2PA data from an in-memory byte slice (WASM & Native compatible).
///
/// `bytes`: Raw binary content of the image.
/// `format_hint`: Optional MIME type or file extension (e.g. "image/png", "jpg"). If None, auto-detected.
pub fn parse_c2pa_from_bytes(bytes: &[u8], format_hint: Option<&str>) -> C2paResponse {
    if bytes.is_empty() {
        return C2paResponse::error("Empty image data provided", None);
    }

    let detected_format = resolve_format(bytes, format_hint);
    let format_str = detected_format.as_deref().unwrap_or("image/jpeg"); // default fallback for c2pa reader

    let stream = Cursor::new(bytes);
    let context = Context::default();

    let reader = match Reader::from_context(context).with_stream(format_str, stream) {
        Ok(reader) => reader,
        Err(err) => {
            return handle_c2pa_error(err, detected_format);
        }
    };

    extract_c2pa_response(&reader, detected_format)
}

/// Helper to handle C2PA reader errors gracefully without panicking.
fn handle_c2pa_error(err: c2pa::Error, format: Option<String>) -> C2paResponse {
    match err {
        c2pa::Error::JumbfNotFound
        | c2pa::Error::JumbfBoxNotFound
        | c2pa::Error::NotFound
        | c2pa::Error::ProvenanceMissing => {
            C2paResponse::no_manifest("No C2PA metadata found in image", format)
        }
        _ => {
            let err_msg = err.to_string();
            let err_lower = err_msg.to_lowercase();
            if err_lower.contains("no jumbf")
                || err_lower.contains("not found")
                || err_lower.contains("provenance not found")
            {
                C2paResponse::no_manifest("No C2PA metadata found in image", format)
            } else {
                C2paResponse::error(format!("C2PA parsing error: {err_msg}"), format)
            }
        }
    }
}

/// Extract structured fields from a successful `c2pa::Reader`.
fn extract_c2pa_response(reader: &Reader, detected_format: Option<String>) -> C2paResponse {
    let active_manifest = match reader.active_manifest() {
        Some(m) => m,
        None => {
            return C2paResponse::no_manifest(
                "No active C2PA manifest found in image",
                detected_format,
            );
        }
    };

    // Parse the full raw JSON string from reader
    let raw_json_str = reader.json();
    let raw_json_value: Option<serde_json::Value> = serde_json::from_str(&raw_json_str).ok();

    // 1. Active Manifest Summary
    let active_manifest_summary = build_manifest_summary(active_manifest, &detected_format);

    // 2. Validation Status and State
    let validation_state = reader.validation_state();
    let validation_state_str = match validation_state {
        ValidationState::Valid => "Valid".to_string(),
        ValidationState::Trusted => "Trusted".to_string(),
        ValidationState::Invalid => "Invalid".to_string(),
    };

    let is_signature_valid = matches!(
        validation_state,
        ValidationState::Valid | ValidationState::Trusted
    );
    let is_trusted = matches!(validation_state, ValidationState::Trusted);

    let mut successes = Vec::new();
    let mut informational = Vec::new();
    let mut failures = Vec::new();

    if let Some(val_results) = reader.validation_results()
        && let Some(active) = val_results.active_manifest()
    {
        for s in active.success() {
            successes.push(ValidationEntry {
                code: s.code().to_string(),
                explanation: s.explanation().unwrap_or("").to_string(),
                url: s.url().map(ToString::to_string),
            });
        }
        for inf in active.informational() {
            informational.push(ValidationEntry {
                code: inf.code().to_string(),
                explanation: inf.explanation().unwrap_or("").to_string(),
                url: inf.url().map(ToString::to_string),
            });
        }
        for f in active.failure() {
            failures.push(ValidationEntry {
                code: f.code().to_string(),
                explanation: f.explanation().unwrap_or("").to_string(),
                url: f.url().map(ToString::to_string),
            });
        }
    }

    let validation_summary = ValidationSummary {
        state: validation_state_str.clone(),
        is_valid: is_signature_valid,
        is_trusted,
        successes,
        informational,
        failures,
    };

    // 3. Signature Details for active manifest
    let active_sig = active_manifest.signature_info();
    let active_algorithm = active_sig.and_then(|s| s.alg.as_ref().map(|a| a.to_string()));

    let signature_details = SignatureDetails {
        issuer: active_manifest
            .issuer()
            .or_else(|| active_sig.and_then(|s| s.issuer.clone())),
        common_name: active_manifest
            .common_name()
            .or_else(|| active_sig.and_then(|s| s.common_name.clone())),
        algorithm: active_algorithm,
        signing_time: active_manifest
            .time()
            .or_else(|| active_sig.and_then(|s| s.time.clone())),
        cert_serial_number: active_sig.and_then(|s| s.cert_serial_number.clone()),
        validation_state: Some(validation_state_str),
        is_signature_valid,
        is_trusted,
    };

    // 4. Extract Actions & Ingredients across ALL manifests in the store
    let active_label = active_manifest.label().unwrap_or("").to_string();
    let mut all_actions: Vec<ActionSummary> = Vec::new();
    let mut ingredient_summaries: Vec<IngredientSummary> = Vec::new();

    // Check all manifests in reader.manifests()
    let manifests_map = reader.manifests();
    for (label, manifest) in manifests_map {
        let is_active = label == &active_label;
        let manifest_actions = extract_manifest_actions(manifest, label, raw_json_value.as_ref());

        let mut manifest_is_ai = false;
        let mut manifest_ai_model = None;

        for action in &manifest_actions {
            if action.is_ai_action {
                manifest_is_ai = true;
            }
            if manifest_ai_model.is_none() && action.software_agent_name.is_some() {
                manifest_ai_model = action
                    .software_agent
                    .clone()
                    .or_else(|| action.software_agent_name.clone());
            }
        }

        if !is_active {
            let claim_gen = manifest
                .claim_generator()
                .map(ToString::to_string)
                .or_else(|| {
                    manifest
                        .claim_generator_info
                        .as_ref()
                        .and_then(|l| l.first().map(|c| c.name.clone()))
                });

            if !manifest_is_ai
                && let Some(cg) = &claim_gen
                && is_ai_name(cg)
            {
                manifest_is_ai = true;
            }

            ingredient_summaries.push(IngredientSummary {
                label: Some(label.clone()),
                title: manifest.title().map(ToString::to_string),
                format: manifest.format().map(ToString::to_string),
                instance_id: Some(manifest.instance_id().to_string()),
                claim_generator: claim_gen,
                is_ai_generated: manifest_is_ai,
                ai_model: manifest_ai_model,
            });
        }

        all_actions.extend(manifest_actions);
    }

    // If all_actions is still empty, try extracting from active manifest specifically
    if all_actions.is_empty() {
        all_actions =
            extract_manifest_actions(active_manifest, &active_label, raw_json_value.as_ref());
    }

    // 5. Extract AI Details using both active and ingredient manifests
    let ai_details = extract_combined_ai_details(
        &all_actions,
        &signature_details,
        &active_manifest_summary,
        manifests_map,
        raw_json_value.as_ref(),
    );

    let is_ai_generated = ai_details.is_ai_generated;

    C2paResponse {
        success: true,
        has_c2pa: true,
        message: Some("C2PA metadata parsed successfully".to_string()),
        error: None,
        format: detected_format.or_else(|| active_manifest_summary.format.clone()),
        is_ai_generated,
        ai_details: Some(ai_details),
        signature: Some(signature_details),
        manifest: Some(active_manifest_summary),
        ingredients: ingredient_summaries,
        actions: all_actions,
        validation: Some(validation_summary),
        raw_manifest: raw_json_value,
    }
}

/// Helper to build a ManifestSummary from a Manifest reference.
fn build_manifest_summary(
    manifest: &Manifest,
    detected_format: &Option<String>,
) -> ManifestSummary {
    let claim_gen_from_info = manifest.claim_generator_info.as_ref().map(|list| {
        list.iter()
            .map(|c| {
                if let Some(v) = &c.version {
                    format!("{} {}", c.name, v)
                } else {
                    c.name.clone()
                }
            })
            .collect::<Vec<_>>()
            .join(", ")
    });

    ManifestSummary {
        label: manifest.label().map(ToString::to_string),
        title: manifest.title().map(ToString::to_string),
        format: manifest
            .format()
            .map(ToString::to_string)
            .or_else(|| detected_format.clone()),
        instance_id: Some(manifest.instance_id().to_string()),
        claim_version: manifest.claim_version(),
        claim_generator: manifest
            .claim_generator()
            .map(ToString::to_string)
            .or(claim_gen_from_info),
    }
}

/// Extract actions from a single Manifest instance.
fn extract_manifest_actions(
    manifest: &Manifest,
    manifest_label: &str,
    raw_json: Option<&serde_json::Value>,
) -> Vec<ActionSummary> {
    let mut actions_list: Vec<ActionSummary> = Vec::new();

    // Try typed Actions assertion first
    if let Ok(actions_assertion) = manifest.find_assertion::<Actions>(Actions::LABEL) {
        for action in actions_assertion.actions {
            let (agent_full, agent_name, agent_version) =
                extract_software_agent(action.software_agent());
            let source_type = action.source_type().map(|s| s.to_string());
            let is_ai = is_ai_action(
                action.action(),
                source_type.as_deref(),
                agent_full.as_deref(),
            );

            actions_list.push(ActionSummary {
                action: action.action().to_string(),
                when: action.when().map(ToString::to_string),
                software_agent: agent_full,
                software_agent_name: agent_name,
                software_agent_version: agent_version,
                digital_source_type: source_type,
                is_ai_action: is_ai,
                manifest_label: Some(manifest_label.to_string()),
                description: action.description().map(ToString::to_string),
            });
        }
    }

    // Fallback to searching JSON for this specific manifest if needed
    if actions_list.is_empty()
        && let Some(json_val) = raw_json
        && let Some(extracted) = extract_actions_for_manifest_from_json(json_val, manifest_label)
    {
        actions_list = extracted;
    }

    actions_list
}

/// Helper to extract software agent strings from c2pa SoftwareAgent enum
fn extract_software_agent(
    agent: Option<&c2pa::assertions::SoftwareAgent>,
) -> (Option<String>, Option<String>, Option<String>) {
    match agent {
        Some(c2pa::assertions::SoftwareAgent::ClaimGeneratorInfo(info)) => {
            let name = info.name.clone();
            let version = info.version.clone();
            let full = match &version {
                Some(v) => format!("{name} {v}"),
                None => name.clone(),
            };
            (Some(full), Some(name), version)
        }
        Some(c2pa::assertions::SoftwareAgent::String(s)) => {
            (Some(s.clone()), Some(s.clone()), None)
        }
        None => (None, None, None),
    }
}

/// Determine whether an agent/model or generator name indicates AI.
fn is_ai_name(name: &str) -> bool {
    let lower = name.to_lowercase();
    AI_AGENT_KEYWORDS.iter().any(|&k| lower.contains(k))
}

/// Determine whether a single action is an AI creation/modification action.
fn is_ai_action(action_name: &str, source_type: Option<&str>, agent_name: Option<&str>) -> bool {
    let action_lower = action_name.to_lowercase();
    if action_lower.contains("trainedalgorithmicmedia") || action_lower.contains("algorithmicmedia")
    {
        return true;
    }

    if let Some(st) = source_type {
        let st_lower = st.to_lowercase();
        if AI_SOURCE_KEYWORDS.iter().any(|&k| st_lower.contains(k)) {
            return true;
        }
    }

    if let Some(agent) = agent_name
        && is_ai_name(agent)
    {
        return true;
    }

    false
}

/// Extract actions for a specific manifest from raw JSON
fn extract_actions_for_manifest_from_json(
    json: &serde_json::Value,
    target_label: &str,
) -> Option<Vec<ActionSummary>> {
    let mut result = Vec::new();
    let manifests = json.get("manifests")?.as_object()?;

    let manifest_obj = manifests.get(target_label)?;
    if let Some(assertions) = manifest_obj.get("assertions").and_then(|a| a.as_array()) {
        for assertion in assertions {
            let label = assertion
                .get("label")
                .and_then(|l| l.as_str())
                .unwrap_or("");
            if label.starts_with("c2pa.actions")
                && let Some(actions) = assertion
                    .get("data")
                    .and_then(|d| d.get("actions"))
                    .and_then(|a| a.as_array())
            {
                for item in actions {
                    let action = item
                        .get("action")
                        .and_then(|a| a.as_str())
                        .unwrap_or("")
                        .to_string();
                    let when = item
                        .get("when")
                        .and_then(|w| w.as_str())
                        .map(ToString::to_string);
                    let source_type = item
                        .get("digitalSourceType")
                        .and_then(|s| s.as_str())
                        .map(ToString::to_string);

                    let (agent_full, agent_name, agent_version) =
                        if let Some(agent_obj) = item.get("softwareAgent") {
                            if let Some(name_str) = agent_obj.get("name").and_then(|n| n.as_str()) {
                                let ver = agent_obj
                                    .get("version")
                                    .and_then(|v| v.as_str())
                                    .map(ToString::to_string);
                                let full = match &ver {
                                    Some(v) => format!("{name_str} {v}"),
                                    None => name_str.to_string(),
                                };
                                (Some(full), Some(name_str.to_string()), ver)
                            } else if let Some(s) = agent_obj.as_str() {
                                (Some(s.to_string()), Some(s.to_string()), None)
                            } else {
                                (None, None, None)
                            }
                        } else {
                            (None, None, None)
                        };

                    let is_ai =
                        is_ai_action(&action, source_type.as_deref(), agent_full.as_deref());

                    result.push(ActionSummary {
                        action,
                        when,
                        software_agent: agent_full,
                        software_agent_name: agent_name,
                        software_agent_version: agent_version,
                        digital_source_type: source_type,
                        is_ai_action: is_ai,
                        manifest_label: Some(target_label.to_string()),
                        description: item
                            .get("description")
                            .and_then(|d| d.as_str())
                            .map(ToString::to_string),
                    });
                }
            }
        }
    }

    if result.is_empty() {
        None
    } else {
        Some(result)
    }
}

/// Extract comprehensive AI details from actions, signatures, and all manifests in the store.
fn extract_combined_ai_details(
    all_actions: &[ActionSummary],
    active_sig: &SignatureDetails,
    active_manifest: &ManifestSummary,
    all_manifests: &std::collections::HashMap<String, Manifest>,
    raw_json: Option<&serde_json::Value>,
) -> AiDetails {
    let mut is_ai = false;
    let mut model_name: Option<String> = None;
    let mut model_version: Option<String> = None;
    let mut digital_source_type: Option<String> = None;
    let mut generation_time: Option<String> = None;
    let mut software_agent_str: Option<String> = None;
    let mut generator_app: Option<String> = None;
    let mut company: Option<String> = None;

    // 1. Scan for explicit AI creation action (e.g. c2pa.created with digitalSourceType = trainedAlgorithmicMedia)
    let ai_creation_action = all_actions
        .iter()
        .find(|a| (a.action == "c2pa.created" || a.action.contains("created")) && a.is_ai_action);

    // If not found, look for ANY c2pa.created action
    let creation_action = ai_creation_action.or_else(|| {
        all_actions
            .iter()
            .find(|a| a.action == "c2pa.created" || a.action.contains("created"))
    });

    if let Some(act) = creation_action {
        if act.is_ai_action {
            is_ai = true;
        }
        if act.software_agent_name.is_some() {
            model_name = act.software_agent_name.clone();
            model_version = act.software_agent_version.clone();
            software_agent_str = act.software_agent.clone();
        }
        if act.digital_source_type.is_some() {
            digital_source_type = act.digital_source_type.clone();
        }
        if act.when.is_some() {
            generation_time = act.when.clone();
        }
    }

    // 2. Scan all other actions for any remaining AI flags, digitalSourceType, models, or dates
    for act in all_actions {
        if act.is_ai_action {
            is_ai = true;
        }
        if digital_source_type.is_none() && act.digital_source_type.is_some() {
            digital_source_type = act.digital_source_type.clone();
        }
        if generation_time.is_none() && act.when.is_some() {
            generation_time = act.when.clone();
        }
        if model_name.is_none() && act.software_agent_name.is_some() {
            model_name = act.software_agent_name.clone();
            model_version = act.software_agent_version.clone();
            software_agent_str = act.software_agent.clone();
        }
    }

    // 3. Scan claim_generator_info across all manifests in the store
    for manifest in all_manifests.values() {
        if let Some(info_list) = &manifest.claim_generator_info {
            for info in info_list {
                if is_ai_name(&info.name) {
                    is_ai = true;
                    if generator_app.is_none() {
                        generator_app = Some(info.name.clone());
                    }
                    if model_name.is_none() {
                        model_name = Some(info.name.clone());
                        model_version = info.version.clone();
                        software_agent_str = Some(match &info.version {
                            Some(v) => format!("{} {}", info.name, v),
                            None => info.name.clone(),
                        });
                    }
                }
            }
        }

        // Also check manifest issuer for company
        if company.is_none() {
            company = manifest.issuer();
        }
    }

    // 4. Check raw JSON for any nested claim_generator_info or creator info if still missing
    if (model_name.is_none() || generator_app.is_none())
        && raw_json.is_some()
        && let Some(manifests_obj) = raw_json
            .and_then(|r| r.get("manifests"))
            .and_then(|m| m.as_object())
    {
        for (_lbl, m_val) in manifests_obj {
            if let Some(cg_info) = m_val.get("claim_generator_info").and_then(|c| c.as_array()) {
                for item in cg_info {
                    if let Some(name_str) = item.get("name").and_then(|n| n.as_str())
                        && is_ai_name(name_str)
                    {
                        is_ai = true;
                        if generator_app.is_none() {
                            generator_app = Some(name_str.to_string());
                        }
                        if model_name.is_none() {
                            model_name = Some(name_str.to_string());
                        }
                    }
                }
            }
        }
    }

    // 5. Fallback company from active signature
    if company.is_none() {
        company = active_sig
            .issuer
            .clone()
            .or_else(|| active_sig.common_name.clone());
    }

    // 6. Check company / generator strings for AI indicators
    if !is_ai {
        if let Some(dst) = &digital_source_type {
            let dst_l = dst.to_lowercase();
            if AI_SOURCE_KEYWORDS.iter().any(|&k| dst_l.contains(k)) {
                is_ai = true;
            }
        }
        if let Some(mn) = &model_name
            && is_ai_name(mn)
        {
            is_ai = true;
        }
        if let Some(cmp) = &company {
            let cmp_l = cmp.to_lowercase();
            if cmp_l.contains("openai")
                || cmp_l.contains("midjourney")
                || cmp_l.contains("stability")
            {
                is_ai = true;
            }
        }
    }

    // 7. Fallback generation time to active signing time
    if generation_time.is_none() {
        generation_time = active_sig.signing_time.clone();
    }

    // 8. Extract clean date string (e.g. "2026-08-25")
    let generation_date = generation_time.as_ref().map(|t| {
        if let Some((d, _)) = t.split_once('T') {
            d.to_string()
        } else if t.len() >= 10 {
            t[..10].to_string()
        } else {
            t.clone()
        }
    });

    let model_display = match (&model_name, &model_version) {
        (Some(name), Some(ver)) => {
            if name.ends_with(ver) {
                Some(name.clone())
            } else {
                Some(format!("{name} {ver}"))
            }
        }
        (Some(name), None) => Some(name.clone()),
        _ => None,
    };

    let claim_generator_str = active_manifest.claim_generator.clone();

    AiDetails {
        is_ai_generated: is_ai,
        model_name,
        model_version,
        model_display,
        company,
        digital_source_type,
        generation_time,
        generation_date,
        software_agent: software_agent_str,
        claim_generator: claim_generator_str,
        generator_app,
    }
}
