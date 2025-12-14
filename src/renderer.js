console.log("Renderer process running");

const params = new URLSearchParams(window.location.search);
const targetUrl = params.get("target");
const iframe = document.getElementById("content-frame");

if (targetUrl && iframe) {
    console.log(`Loading target URL: ${targetUrl}`);
    iframe.src = targetUrl;
} else {
    console.warn("No target URL provided for iframe");
}
