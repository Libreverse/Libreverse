// Use Vite's ?url imports for model assets to ensure correct URLs in all environments
import tokenizerUrl from "~/client-ai-models/intel-toxic-prompt-roberta_tokenizer.json?url";
import tokenizerConfigUrl from "~/client-ai-models/intel-toxic-prompt-roberta_tokenizer_config.json?url";
import modelConfigUrl from "~/client-ai-models/intel-toxic-prompt-roberta_config.json?url";
// Store the current ONNX data/blob URL for remapping
let currentOnnxUrl = null;
// Hack: Remap blob: and /models/blob: URLs to Vite-served URLs for transformers.js
(function () {
    const BLOB_PREFIX = "/models/blob:";
    // Map filename to Vite-served URL
    const FILE_MAP = {
        "tokenizer.json": tokenizerUrl,
        "tokenizer_config.json": tokenizerConfigUrl,
        "config.json": modelConfigUrl,
    };
    function remapUrl(url) {
        if (typeof url !== "string") return url;
        for (const fname in FILE_MAP) {
            if (url.includes(fname)) {
                return FILE_MAP[fname];
            }
        }
        // If transformers.js tries to fetch model_quantized.onnx, return the current data/blob URL if set, else return a safe dummy URL to prevent fetch errors
        if (url.includes("model_quantized.onnx")) {
            if (currentOnnxUrl) {
                return currentOnnxUrl;
            } else {
                // Return a safe dummy data URL to prevent null fetch errors and unwanted network requests
                return "data:application/octet-stream;base64,";
            }
        }
        return url;
    }
    const originalOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function (method, url, ...rest) {
        if (typeof url === "string") {
            url = remapUrl(url);
        }
        return originalOpen.call(this, method, url, ...rest);
    };
    const originalFetch = globalThis.fetch;
    globalThis.fetch = async function (resource, ...rest) {
        if (typeof resource === "string") {
            resource = remapUrl(resource);
        }
        // If resource is an object, do not remap
        return originalFetch(resource, ...rest);
    };
})();

import loadToxicityPipeline from "../libs/toxicity_classifier";

let pipelineInstance = null;

globalThis.onmessage = async (e) => {
    const { action, payload } = e.data || {};
    try {
        if (action === "init") {
            const {
                tokenizerFile,
                modelConfigFile,
                tokenizerConfigFile,
                onnxFile,
            } = payload || {};
            try {
                // If we have a File, create a data/blob URL and store it for remapping
                if (onnxFile) {
                    currentOnnxUrl = URL.createObjectURL(onnxFile);
                }
                const customModel = onnxFile
                    ? { file: onnxFile, format: "onnx" }
                    : null;
                const pipe = await loadToxicityPipeline(
                    tokenizerFile || null,
                    modelConfigFile || null,
                    tokenizerConfigFile || null,
                    customModel,
                );
                if (!pipe) {
                    postMessage({
                        type: "init-failed",
                        error: "pipeline-null",
                    });
                    return;
                }
                pipelineInstance = pipe;
                postMessage({ type: "init-success" });
            } catch (error) {
                postMessage({ type: "init-failed", error: String(error) });
            }
        } else if (action === "classify") {
            const { id, text } = payload || {};
            if (!pipelineInstance) {
                postMessage({
                    type: "result-error",
                    id,
                    error: "pipeline-not-initialized",
                });
                return;
            }
            try {
                const res = await pipelineInstance(text);
                postMessage({ type: "result", id, result: res });
            } catch (error) {
                postMessage({ type: "result-error", id, error: String(error) });
            }
        }
    } catch (error) {
        postMessage({ type: "worker-error", error: String(error) });
    }
};
