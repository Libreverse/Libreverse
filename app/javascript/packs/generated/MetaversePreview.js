const DISABLE_LOGGING = true;

import ReactOnRails from "react-on-rails/client";
import MetaversePreview from "../../src/Metaverse3D/ror_components/MetaversePreview.jsx";

if (!DISABLE_LOGGING) {
    console.info("[MetaverseHydration] pack evaluating", {
        ReactOnRailsImported: typeof ReactOnRails,
    });
}

ReactOnRails.setOptions({
    turbo: false,
});

ReactOnRails.register({ MetaversePreview });

if (!globalThis.ReactOnRails) {
    globalThis.ReactOnRails = ReactOnRails;
}

const recordHydrationEvent = (event, payload = {}) => {
    const entry = { event, timestamp: Date.now(), ...payload };
    if (!DISABLE_LOGGING) {
        (globalThis.__MetaverseHydrationLog ||= []).push(entry);
    }
    if (!DISABLE_LOGGING && process.env.NODE_ENV !== "production") {
        console.debug(`[MetaverseHydration] ${event}`, payload);
    }
};

let hasHydrated = false;

const triggerHydration = (source) => {
    if (hasHydrated) {
        recordHydrationEvent("skip", { source });
        return;
    }

    try {
        recordHydrationEvent("start", { source });
        ReactOnRails.reactOnRailsPageLoaded();
        hasHydrated = true;
        recordHydrationEvent("success", { source });
    } catch (error) {
        recordHydrationEvent("error", { source, error: error?.message });
        console.error("ReactOnRails hydration failed", error);
    }
};

const resetHydration = (source) => {
    hasHydrated = false;
    recordHydrationEvent("reset", { source });
};

if (
    document.readyState === "complete" ||
    document.readyState === "interactive"
) {
    triggerHydration("document-ready");
} else {
    document.addEventListener(
        "DOMContentLoaded",
        () => triggerHydration("domcontentloaded"),
        { once: true },
    );
}

document.addEventListener("turbo:before-render", () =>
    resetHydration("turbo:before-render"),
);
document.addEventListener("turbo:render", () =>
    triggerHydration("turbo:render"),
);
document.addEventListener("turbo:load", () => triggerHydration("turbo:load"));
