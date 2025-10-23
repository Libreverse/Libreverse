// Optimized Stimulus controller for Wllama
import { Controller } from "@hotwired/stimulus";
import { Wllama, LoggerWithoutDebug } from "@wllama/wllama/esm/index.js";
import { pipeline, env } from "@xenova/transformers";
import loadToxicityPipelineJS from "../libs/toxicity_classifier";
import snappy from "snappyjs";

const MODEL_PARTS = import.meta.glob(
  "../../client-ai-models/*.gguf.snappy",
  { eager: true, as: "url" }
);

const ONNX_PARTS = import.meta.glob(
  "../../client-ai-models/intel-toxic-prompt-roberta_*.onnx.part.snappy",
  { eager: true, as: "url" }
);

const TOKENIZER_JSON = import.meta.glob(
  "../../client-ai-models/intel-toxic-prompt-roberta_tokenizer.json",
  { eager: true, as: "url" }
);

const TOKENIZER_CONFIG_JSON = import.meta.glob(
  "../../client-ai-models/intel-toxic-prompt-roberta_tokenizer_config.json",
  { eager: true, as: "url" }
);

const MODEL_CONFIG_JSON = import.meta.glob(
  "../../client-ai-models/intel-toxic-prompt-roberta_config.json",
  { eager: true, as: "url" }
);

const snappyUncompress = typeof snappy === "function"
  ? snappy
  : snappy?.uncompress
    ? snappy.uncompress
    : (() => { throw new Error("snappyjs module did not expose an uncompress function"); })();

function resolveModelParts() {
  return Object.keys(MODEL_PARTS)
    .sort()
    .map((key) => {
      const original = key.replace("../../client-ai-models/", "");
      return {
        url: MODEL_PARTS[key],
        name: original.replace(/\.snappy$/i, ""),
      };
    });
}

function resolveOnnxParts() {
  return Object.keys(ONNX_PARTS)
    .sort()
    .map((key) => {
      const original = key.replace("../../client-ai-models/", "");
      return {
        url: ONNX_PARTS[key],
        name: original.replace(/\.snappy$/i, ""),
      };
    });
}

async function loadLocalJsonFile(collection, defaultName, signal) {
  const entries = Object.keys(collection);
  if (entries.length === 0) return Promise.resolve(null);
  const source = collection[entries[0]];
  const response = await fetch(source, { signal });
  if (!response.ok) {
    throw new Error(`Failed to fetch ${source} (status ${response.status})`);
  }
  const text = await response.text();
  if (signal?.aborted) {
    throw new DOMException("Aborted", "AbortError");
  }
  return new File([text], defaultName, { type: "application/json" });
}

export default class extends Controller {
  static targets = ["userInput", "chatDisplay", "sendButton", "loadingIndicator"];

  connect() {
    console.info("[Wllama] Controller connected");
    this.modelLoaded = false;
    this.isStreaming = false;
    this.toxicPipeline = null;
    this.toxicClassifierLoading = false;
    this.toxicClassifierAbortController = null;
    this.isSendingMessage = false;
  // Regulatory requirement: only allow message sends when an AI toxicity
  // classifier (ML-based) is available. If this is true, we will disable
  // user sending until the ML pipeline is initialized successfully.
  this.requiresToxicPipeline = true;
    this.messages = [
      {
        role: "system",
        content: `
          You are a witty, helpful Libreverse assistant; model is compressed—re-read user input twice, think step-by-step silently (parse words→classify action→craft reply→build API→verify exact match), correct all errors/garbles internally, output ONLY: 1 short witty reply line + (if explicit action) newline + exact API line; nothing else—no echoes, no examples, no extras/inventions. Explicit actions only: create/search/view/update/delete experiences; parse params precisely (e.g., "titled X"→title "X"; "description Y"→desc "Y"; "html <Z>"→html "<Z>"; ID=number/string; query=keywords; limit=number; field/value from context). Actions exact: Search=libreverse_api:search.public_query "query" [limit]; Create=libreverse_api:experiences.create "title" "description" "html_content"; View=libreverse_api:experiences.get ID; Update=libreverse_api:experiences.update ID '{"field": "value"}'; Delete=libreverse_api:experiences.delete ID. Examples (internal only, match outputs exactly): User:"Search for cats, limit 5"→"Pawsitively searching!\nlibreverse_api:search.public_query "cats" 5"; User:"Create experience titled cat with the description cat and the html <h1>cat</h1>"→"Meow-velous creation!\nlibreverse_api:experiences.create "cat" "cat" "<h1>cat</h1>""; User:"Make experience title 'Fun' desc 'Joy' html '<p>Yay</p>'"→"Bringing the joy!\nlibreverse_api:experiences.create "Fun" "Joy" "<p>Yay</p>""; User:"Create titled dog description bark html <h2>Woof</h2>"→"Barking up the right tree!\nlibreverse_api:experiences.create "dog" "bark" "<h2>Woof</h2>""; User:"View 123"→"Peeking!\nlibreverse_api:experiences.get 123"; User:"Update 123 title to NewCat"→"Tweaking!\nlibreverse_api:experiences.update 123 '{"title": "NewCat"}'"; User:"Delete 456"→"Poof!\nlibreverse_api:experiences.delete 456"; User:"Hi"→"Hey, ready to craft experiences?" Stay fun, direct, accurate—end after API if present.
        `,
      },
    ];
    this.heartbeatInterval = setInterval(() => {
      console.debug("[Wllama] heartbeat", { modelLoaded: this.modelLoaded, streaming: this.isStreaming });
    }, 10000);

    // UI initial state
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.textContent = "Loading model, please wait...";
      this.loadingIndicatorTarget.style.display = "block";
    }
    if (this.hasSendButtonTarget) {
      this.sendButtonTarget.disabled = true;
    }

    // Abort controllers for lifecycle/cancelation
    this.loadAbortController = null;
    this.completionAbortController = null;

    // Streaming UI throttle state
    this.lastRenderTime = 0;
    this.streamThrottleMs = 40; // throttle DOM updates to ~25fps

    // Decide parallel downloads & thread defaults adaptively
    const hwConcurrency = navigator.hardwareConcurrency;
    this.parallelDownloads = 11;
    this.preferredThreads = navigator.hardwareConcurrency * 2;

    console.info("[Wllama] hwConcurrency:", hwConcurrency, "parallelDownloads:", this.parallelDownloads, "preferredThreads:", this.preferredThreads);

    this.initWllama();
    this.initToxicClassifier();
    // Worker for toxicity pipeline (ML-only). Will initialize in background.
    this._toxicityWorker = null;
    this._toxicityRequestId = 0;
    this._toxicityCallbacks = new Map();
  }

  updateLoadingStatus(message) {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.textContent = message;
    }
  }

  disconnect() {
    console.info("[Wllama] disconnecting");
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
      this.heartbeatInterval = null;
    }
    // Cancel any inflight operations
    if (this.loadAbortController) {
      try {
        this.loadAbortController.abort();
      } catch (err) {
        console.debug("[Wllama] load abort error", err);
      }
    }
    if (this.completionAbortController) {
      try {
        this.completionAbortController.abort();
      } catch (err) {
        console.debug("[Wllama] completion abort error", err);
      }
    }
    if (this.toxicClassifierAbortController) {
      try {
        this.toxicClassifierAbortController.abort();
      } catch (err) {
        console.debug("[Wllama] toxic abort error", err);
      }
    }
    // Clear instance to free WASM worker if supported
    if (this.instance) {
      try {
        if (this.instance.destroy) {
          this.instance.destroy();
        }
      } catch (err) {
        console.debug("[Wllama] instance destroy failed", err);
      }
    }
  }

  async initWllamaAsync() {
    console.info("[Wllama] Initializing Wllama...");
    const parts = resolveModelParts();

    this.instance = new Wllama(
      {
        "single-thread/wllama.wasm": "https://cdn.jsdelivr.net/npm/@wllama/wllama@1.17.1/esm/single-thread/wllama.wasm",
        "single-thread/wllama.js": "https://cdn.jsdelivr.net/npm/@wllama/wllama@1.17.1/esm/single-thread/wllama.js",
      },
      {
        parallelDownloads: this.parallelDownloads,
        logger: LoggerWithoutDebug,
      }
    );

    // Abort controller to allow canceling load if user navigates away
    this.loadAbortController = new AbortController();
    const signal = this.loadAbortController.signal;

    // Set n_threads adaptively; keep context reasonable to avoid huge memory
    this.n_ctx = 1028; // Further increased context window for very long conversations
    const n_ctx = this.n_ctx;
    const n_threads = this.preferredThreads;

    const start = performance.now();
    var files = null;
    try {
      if (signal?.aborted) {
        throw new DOMException("Aborted", "AbortError");
      }
      files = await this.downloadAndDecompressParts(parts, signal);
      if (signal?.aborted) {
        throw new DOMException("Aborted", "AbortError");
      }
      this.updateLoadingStatus("Finalizing model load…");
      console.info("[Wllama] Passing " + files.length + " files to loadModel:", files.map((f) => ({ name: f.name, size: f.size })));
      await this.instance.loadModel(files, {
        n_ctx: n_ctx,
        n_threads: n_threads,
      });

      const loadTime = Math.round(performance.now() - start);
      console.info(`[Wllama] Model loaded in ${loadTime}ms (n_ctx=${n_ctx}, n_threads=${n_threads})`);
      this.modelLoaded = true;
      if (this.hasLoadingIndicatorTarget) {
        this.loadingIndicatorTarget.style.display = "none";
      }
      if (this.hasSendButtonTarget) {
        if (this.requiresToxicPipeline && !this.toxicPipeline) {
          this.sendButtonTarget.disabled = true;
          if (this.hasLoadingIndicatorTarget) this.loadingIndicatorTarget.textContent = "Waiting for safety classifier..."
        } else {
          this.sendButtonTarget.disabled = false;
        }
      }

      // Warm up KV cache with a very short call to reduce first-response latency
      try {
        await this.instance.createCompletion(" ", { nPredict: 2 });
        console.debug("[Wllama] Warm-up completed");
      } catch (warmErr) {
        console.debug("[Wllama] Warm-up failed, continuing", warmErr);
      }
    } catch (err) {
      console.error("[Wllama] Model load failed:", err);
      if (this.hasLoadingIndicatorTarget) {
        this.loadingIndicatorTarget.textContent = "Failed to load model. Check console for details.";
      }
      this.modelLoaded = false;
    } finally {
      try { files = null } catch (e) {}
    }
  }

  async downloadAndDecompressParts(parts, signal) {
    const total = parts.length;
    const results = new Array(total);
    let index = 0;
    const limit = Math.max(1, Math.min(this.parallelDownloads, total));

    async function worker() {
      if (signal?.aborted) {
        throw new DOMException("Aborted", "AbortError");
      }
      const current = index;
      index += 1;
      if (current >= total) return Promise.resolve();
      const file = await this.fetchAndDecompressPart(parts[current], current, total, signal);
      results[current] = file;
      return worker.call(this);
    }

    const workers = [];
    for (let i = 0; i < limit; i++) {
      workers.push(worker.call(this));
    }

    return Promise.all(workers).then(() => results);
  }

  async initToxicClassifier() {
    if (this.toxicPipeline || this.toxicClassifierLoading) return;

    const parts = resolveOnnxParts();
    if (parts.length === 0) {
      console.warn("[Wllama] No ONNX parts found for toxicity classifier");
      return;
    }

    console.info(`[Wllama] Preparing toxicity classifier (${parts.length} shards)`);
    this.toxicClassifierLoading = true;
    this.toxicClassifierAbortController = new AbortController();
    const signal = this.toxicClassifierAbortController.signal;

    const start = performance.now();
    try {
      const arrays = await this.downloadOnnxShards(parts, signal);
      if (signal?.aborted) return;

      const totalBytes = arrays.reduce((sum, arr) => sum + arr.byteLength, 0);
      const combined = new Uint8Array(totalBytes);
      let offset = 0;
      for (const arr of arrays) {
        combined.set(arr, offset);
        offset += arr.byteLength;
      }

      const baseName = parts[0]?.name?.replace(/_\d+\.onnx\.part$/i, ".onnx") || "model.onnx";
      const onnxFile = new File([combined], baseName, { type: "application/octet-stream" });

      env.allowRemoteModels = true; // Temporarily enable for fallback
      env.allowLocalModels = true;
      env.useBrowserCache = false;
      env.localModelPath = null;

      console.info(`[Wllama] Loading toxicity classifier from local ONNX (${totalBytes} bytes)`);
      const customModel = {
        file: onnxFile,
        format: "onnx",
      };

      const [tokenizerFile, modelConfigFile, tokenizerConfigFile] = await Promise.all([
        loadLocalJsonFile(TOKENIZER_JSON, "tokenizer.json", signal),
        loadLocalJsonFile(MODEL_CONFIG_JSON, "config.json", signal),
        loadLocalJsonFile(TOKENIZER_CONFIG_JSON, "tokenizer_config.json", signal),
      ]);

      // Initialize worker and pass files (use transferable object URLs via postMessage)
      if (this._toxicityWorker) try { this._toxicityWorker.terminate() } catch (e) {}
  this._toxicityWorker = new Worker(new URL("../workers/toxicity_worker.js", import.meta.url), { type: "module" });
      this._toxicityWorker.onmessage = (ev) => this._handleToxicWorkerMessage(ev.data);

      // Send init payload; pass File objects (they are structured-cloneable in modern browsers)
      this._toxicityWorker.postMessage({ action: "init", payload: { tokenizerFile, modelConfigFile, tokenizerConfigFile, onnxFile } });

      // set a 40s timeout to fail-safe ML initialization
      const initTimeout = setTimeout(() => {
        console.warn('[Wllama] Toxicity worker init timed out');
        if (this._toxicityWorker) {
          try { this._toxicityWorker.terminate() } catch (e) {}
          this._toxicityWorker = null;
        }
        // keep ML-only policy: leave toxicPipeline null and disable send
        if (this.hasSendButtonTarget) {
          this.sendButtonTarget.disabled = true;
          if (this.hasLoadingIndicatorTarget) this.loadingIndicatorTarget.textContent = "Safety classifier unavailable - sending disabled"
        }
      }, 40000);

      // store timeout so handler can clear it
      this._toxicityInitTimeout = initTimeout;

      // Worker will either report init-success or init-failed
    } catch (err) {
      if (signal?.aborted) return;
      console.error("[Wllama] Failed to download toxicity classifier parts", err);
      // Try fallback: attempt to initialize remote toxicity pipeline (no customModel)
      try {
        console.info("[Wllama] Attempting remote-only toxicity pipeline fallback")
        const fallbackPipe = await loadToxicityPipelineJS(null, null, null, null)
        if (fallbackPipe) {
          console.info("[Wllama] Remote toxicity pipeline ready (fallback)")
          this.toxicPipeline = fallbackPipe
        } else {
          console.warn("[Wllama] Remote toxicity pipeline not available")
          this.toxicPipeline = createRuleBasedPipeline()
        }
      } catch (fallbackErr) {
        console.error("[Wllama] Remote toxicity pipeline fallback failed", fallbackErr)
        this.toxicPipeline = null
      }

      this.toxicClassifierLoading = false;
      this.toxicClassifierAbortController = null;
    }
  }

  _handleToxicWorkerMessage(msg) {
    const { type } = msg || {};
    if (type === "init-success") {
      if (this._toxicityInitTimeout) { clearTimeout(this._toxicityInitTimeout); this._toxicityInitTimeout = null }
      console.info('[toxicity] Worker init success');
      // mark pipeline as available (worker will be used to classify)
      this.toxicPipeline = (text) => {
        return new Promise((resolve, reject) => {
          const id = ++this._toxicityRequestId;
          this._toxicityCallbacks.set(id, { resolve, reject });
          try {
            this._toxicityWorker.postMessage({ action: 'classify', payload: { id, text } });
          } catch (err) {
            this._toxicityCallbacks.delete(id);
            reject(err);
          }
        });
      };
      this.toxicClassifierLoading = false;
      this.toxicClassifierAbortController = null;
      if (this.hasSendButtonTarget) {
        this.sendButtonTarget.disabled = false;
        if (this.hasLoadingIndicatorTarget) this.loadingIndicatorTarget.style.display = 'none'
      }
    } else if (type === "init-failed") {
      if (this._toxicityInitTimeout) { clearTimeout(this._toxicityInitTimeout); this._toxicityInitTimeout = null }
      console.warn('[toxicity] Worker init failed', msg.error);
      if (this._toxicityWorker) { try { this._toxicityWorker.terminate() } catch (e) {} }
      this._toxicityWorker = null;
      this.toxicPipeline = null; // ML-only enforcement
      this.toxicClassifierLoading = false;
      if (this.hasSendButtonTarget) { this.sendButtonTarget.disabled = true; if (this.hasLoadingIndicatorTarget) this.loadingIndicatorTarget.textContent = 'Safety classifier unavailable - sending disabled' }
    } else if (type === 'result') {
      const { id, result } = msg;
      const cb = this._toxicityCallbacks.get(id);
      if (cb) { cb.resolve(result); this._toxicityCallbacks.delete(id) }
    } else if (type === 'result-error') {
      const { id, error } = msg;
      const cb = this._toxicityCallbacks.get(id);
      if (cb) { cb.reject(new Error(error)); this._toxicityCallbacks.delete(id) }
    } else if (type === 'worker-error') {
      console.error('[toxicity] worker error', msg.error);
    }
  }

  async fetchAndDecompressPart(part, index, total, signal) {
    if (signal?.aborted) {
      throw new DOMException("Aborted", "AbortError");
    }
    const partNumber = index + 1;
    const label = `${partNumber}/${total}`;

    async function retryFetch(retriesLeft) {
      this.updateLoadingStatus(`Downloading part ${label}… (${retriesLeft < 3 ? `retry ${3 - retriesLeft}` : ""})`);
      try {
        const response = await fetch(part.url, { signal, cache: "no-cache" });
        if (!response.ok) {
          throw new Error(`Failed to fetch ${part.url} (status ${response.status})`);
        }
        return await response.arrayBuffer();
      } catch (error) {
        if (retriesLeft > 0 && error.name !== "AbortError") {
          console.warn(`[Wllama] Fetch failed for ${part.name}, retrying... (${retriesLeft} left)`, error);
          await new Promise((resolve) => setTimeout(resolve, 1000));
          return retryFetch.call(this, retriesLeft - 1);
        }
        throw error;
      }
    }

    const compressedBuffer = await retryFetch.call(this, 3);
    if (signal?.aborted) {
      throw new DOMException("Aborted", "AbortError");
    }
    this.updateLoadingStatus(`Decompressing part ${label}…`);
    console.debug(`[Wllama] Compressed size for ${part.name}: ${compressedBuffer.byteLength} bytes`);
    const decompressed = snappyUncompress(new Uint8Array(compressedBuffer));
    console.debug(`[Wllama] Decompressed size for ${part.name}: ${decompressed.length} bytes`);
    const file = new File([decompressed], part.name, { type: "application/octet-stream" });
    console.debug(`[Wllama] Created File: ${file.name}, size: ${file.size} bytes`);
    return file;
  }

  initWllama() {
    // Kick off the load in background; keep UI responsive
    this.initWllamaAsync();
  }

  manageContext() {
    // Keep system message + recent messages, truncate if needed
    if (this.messages.length <= 2) return; // Keep at least system + 1 conversation pair

    // Rough token estimation: ~4 chars per token
    const totalChars = this.messages.reduce((sum, msg) => sum + (msg.content?.length || 0), 0);
    const estimatedTokens = Math.ceil(totalChars / 4);

    // Target: keep under 80% of context to leave room for response
    const maxTokens = Math.floor(this.n_ctx * 0.8);
    console.debug(`[Wllama] Context check: ${estimatedTokens} tokens (max: ${maxTokens})`);

    if (estimatedTokens <= maxTokens) return;

    // Keep system message + last 4 messages (2 conversation turns)
    this.messages = [this.messages[0], ...this.messages.slice(-4)];
    console.info("[Wllama] Context truncated to prevent overflow");
  }

  async downloadOnnxShards(parts, signal) {
    return Promise.all(
      parts.map(async (part, index) => {
        if (signal?.aborted) {
          throw new DOMException("Aborted", "AbortError");
        }
        const label = `${index + 1}/${parts.length}`;
        console.debug(`[Wllama] Downloading ONNX shard ${label}: ${part.name}`);
        const response = await fetch(part.url, { signal });
        if (!response.ok) {
          throw new Error(`Failed to fetch ${part.url} (status ${response.status})`);
        }
        const compressedBuffer = await response.arrayBuffer();
        if (signal?.aborted) {
          throw new DOMException("Aborted", "AbortError");
        }
        const decompressed = snappyUncompress(new Uint8Array(compressedBuffer));
        console.debug(`[Wllama] ONNX shard ${label} decompressed (${decompressed.byteLength} bytes)`);
        return decompressed;
      })
    );
  }

  async sendMessage(ev) {
    console.log(`[Wllama] sendMessage called, modelLoaded: ${this.modelLoaded}, isStreaming: ${this.isStreaming}`);
    ev?.preventDefault();
    if (!this.modelLoaded) {
      console.warn("[Wllama] Model not loaded yet");
      alert("Model is still loading. Please wait a moment.");
      return;
    }
    if (this.isStreaming) {
      console.warn("[Wllama] Already streaming");
      return;
    }
    if (this.isSendingMessage) {
      console.warn("[Wllama] Already sending message");
      return;
    }
    this.isSendingMessage = true;

    const userContent = this.userInputTarget?.value?.trim() || "";
    console.log(`[Wllama] User input: '${userContent}' (length: ${userContent.length})`);
    if (userContent.length === 0) {
      this.isSendingMessage = false;
      return;
    }

    // Add user message to context
    this.messages.push({ role: "user", content: userContent });

    // Update UI: clear input, show loading indicator, disable send button
    this.userInputTarget.value = "";
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.style.display = "block";
      this.loadingIndicatorTarget.textContent = "Thinking...";
    }
    if (this.hasSendButtonTarget) {
      this.sendButtonTarget.disabled = true;
    }

    // Manage context size: trim messages if too large
    this.manageContext();

    const start = performance.now();
    let completion;
    try {
      const prompt = this.messages.map(m => `${m.role}: ${m.content}`).join('\n') + '\nassistant: ';
      // Streaming completion: onProgress will update UI with each chunk
      completion = await this.instance.createCompletion(prompt, {
        stream: true,
        onProgress: (partial) => {
          const content = partial.content || "";
          this.appendChatMessage(content, true);
        },
      });

      // For non-streaming, we would use:
      // completion = await this.instance.createChatCompletion(this.messages, { stream: false });

      console.log("[Wllama] Full completion received:", completion);
      const firstChoice = completion.choices?.[0];
      if (!firstChoice) {
        throw new Error("No choices returned from model");
      }
      const { delta, finish_reason } = firstChoice;
      if (finish_reason !== "stop") {
        console.warn("[Wllama] Stream did not end with 'stop': ", finish_reason);
      }

      // Extract and return the full text response
      const response = delta?.content || "";
      this.messages.push({ role: "assistant", content: response });

      // Log the usage of tokens (if available)
      const totalTokens = completion.usage?.total_tokens || 0;
      console.log(`[Wllama] Token usage: ${totalTokens} tokens`);

      return response;
    } catch (err) {
      console.error("[Wllama] Error during message sending:", err);
      this.showError("Error sending message. Please try again.");
    } finally {
      this.isSendingMessage = false;
      if (this.hasLoadingIndicatorTarget) {
        this.loadingIndicatorTarget.style.display = "none";
      }
      if (this.hasSendButtonTarget) {
        this.sendButtonTarget.disabled = false;
      }
      const duration = Math.round(performance.now() - start);
      console.log(`[Wllama] Message processed in ${duration}ms`);
    }
  }

  appendChatMessage(content, isUserMessage) {
    const div = document.createElement("div");
    div.className = isUserMessage ? "user-message" : "assistant-message";
    div.innerHTML = content.replace(/</g, "&lt;").replace(/>/g, "&gt;");
    this.chatDisplayTarget.appendChild(div);
    this.scrollChatToBottom();
  }

  scrollChatToBottom() {
    const chat = this.chatDisplayTarget;
    chat.scrollTop = chat.scrollHeight;
  }

  showError(message) {
    // Simple error display: prepend to chat as system message
    this.messages.push({ role: "system", content: message });
    const div = document.createElement("div");
    div.className = "system-message error";
    div.textContent = message;
    this.chatDisplayTarget.insertBefore(div, this.chatDisplayTarget.firstChild);
    this.scrollChatToBottom();
  }
}