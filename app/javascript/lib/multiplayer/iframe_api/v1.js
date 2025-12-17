// Multiplayer iframe protocol (v1)
//
// This file formalizes the CURRENT iframe <-> wrapper message API as "v1".
//
// Back-compat policy:
// - Inbound messages that omit api/api_version are treated as v1.
// - Outbound messages from the wrapper include api/api_version.

export const MULTIPLAYER_IFRAME_API_V1 = "libreverse.multiplayer.v1";
export const MULTIPLAYER_IFRAME_API_V1_NUMBER = 1;

export const V1_INBOUND_TYPES = Object.freeze({
    STATE_SET: "state_set",
    STATE_GET: "state_get",
    STATE_REQUEST_ALL: "state_request_all",
});

export const V1_OUTBOUND_TYPES = Object.freeze({
    CONNECTED: "connected",
    DISCONNECTED: "disconnected",
    STATE_VALUE: "state_value",
    STATE_SNAPSHOT: "state_snapshot",
    STATE_UPDATE: "state_update",
});

export function normalizeV1InboundMessage(data) {
    if (!data || typeof data !== "object") return null;

    // If explicitly tagged, it must match v1.
    if ("api" in data && data.api !== MULTIPLAYER_IFRAME_API_V1) return null;
    if ("api_version" in data && Number(data.api_version) !== MULTIPLAYER_IFRAME_API_V1_NUMBER)
        return null;

    const type = data.type;
    if (
        type !== V1_INBOUND_TYPES.STATE_SET &&
        type !== V1_INBOUND_TYPES.STATE_GET &&
        type !== V1_INBOUND_TYPES.STATE_REQUEST_ALL
    ) {
        return null;
    }

    return {
        type,
        key: data.key,
        value: data.value,
    };
}

export function buildV1OutboundMessage(type, payload = {}) {
    return {
        api: MULTIPLAYER_IFRAME_API_V1,
        api_version: MULTIPLAYER_IFRAME_API_V1_NUMBER,
        type,
        ...payload,
    };
}
