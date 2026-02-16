console.log("Renderer process running");

const parameters = new URLSearchParams(globalThis.location.search);
const targetUrl = parameters.get("target");
const iframe = document.querySelector("#content-frame");

if (targetUrl && iframe) {
    console.log(`Loading target URL: ${targetUrl}`);
    iframe.src = targetUrl;
} else {
    console.warn("No target URL provided for iframe");
}
