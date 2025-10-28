import { pipeline, env } from "@xenova/transformers";

export default async function loadToxicityPipeline(
    tokenizerFile,
    modelConfigFile,
    tokenizerConfigFile,
    customModel,
) {
    // Only allow local models, never remote
    try {
        env.allowLocalModels = true;
        env.allowRemoteModels = false;
        env.useBrowserCache = false;

        // Check for missing files
        if (!customModel || !customModel.file) {
            console.error("[toxicity] Missing ONNX model file");
            return null;
        }
        if (!tokenizerFile) {
            console.error("[toxicity] Missing tokenizer file");
            return null;
        }
        if (!modelConfigFile) {
            console.error("[toxicity] Missing model config file");
            return null;
        }
        if (!tokenizerConfigFile) {
            console.error("[toxicity] Missing tokenizer config file");
            return null;
        }

        const options = {};
        try {
            const text = await modelConfigFile.text();
            options.config = JSON.parse(text);
        } catch (error) {
            console.warn("[toxicity] failed to parse model config", error);
            return null;
        }
        try {
            options.tokenizer = { file: tokenizerFile };
        } catch (error) {
            console.warn("[toxicity] failed to attach tokenizer file", error);
            return null;
        }
        try {
            const text = await tokenizerConfigFile.text();
            options.tokenizer_config = JSON.parse(text);
        } catch (error) {
            console.warn("[toxicity] failed to parse tokenizer_config", error);
            return null;
        }

        // Try local ONNX: blob URL, then data: URL
        try {
            const blobUrl = URL.createObjectURL(customModel.file);
            try {
                const pipe = await pipeline(
                    "text-classification",
                    blobUrl,
                    options,
                );
                try {
                    URL.revokeObjectURL(blobUrl);
                } catch {}
                return pipe;
            } catch (error) {
                console.warn(
                    "[toxicity] Local ONNX pipeline attempt via blob URL failed",
                    error,
                );
                try {
                    URL.revokeObjectURL(blobUrl);
                } catch {}
                // Try data: URL
                try {
                    const arrayBuffer = await customModel.file.arrayBuffer();
                    const uint8 = new Uint8Array(arrayBuffer);
                    let binary = "";
                    for (let index = 0; index < uint8.length; index++)
                        binary += String.fromCharCode(uint8[index]);
                    const base64 = btoa(binary);
                    const dataUrl = `data:application/octet-stream;base64,${base64}`;
                    const pipe = await pipeline(
                        "text-classification",
                        dataUrl,
                        options,
                    );
                    return pipe;
                } catch (error) {
                    console.warn(
                        "[toxicity] Local ONNX pipeline attempt via data: URL failed",
                        error,
                    );
                }
                // Last-ditch: try File object
                try {
                    const pipe = await pipeline(
                        "text-classification",
                        customModel,
                        options,
                    );
                    return pipe;
                } catch (error) {
                    console.warn(
                        "[toxicity] Local ONNX pipeline attempt via File failed",
                        error,
                    );
                }
            }
        } catch (error) {
            console.warn("[toxicity] Local ONNX pipeline failed", error);
        }

        // Never try remote model id
        console.info(
            "[toxicity] ML pipelines failed; returning null to enforce ML-only policy",
        );
        return null;
    } catch (error) {
        console.error(
            "[toxicity] Unexpected error initializing pipeline",
            error,
        );
        return null;
    }
}
