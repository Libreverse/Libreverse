// See the Electron documentation for details on how to use preload scripts:
// https://www.electronjs.org/docs/latest/tutorial/process-model#preload-scripts

//svgs license
/*

Creative Commons Legal Code

CC0 1.0 Universal

    CREATIVE COMMONS CORPORATION IS NOT A LAW FIRM AND DOES NOT PROVIDE
    LEGAL SERVICES. DISTRIBUTION OF THIS DOCUMENT DOES NOT CREATE AN
    ATTORNEY-CLIENT RELATIONSHIP. CREATIVE COMMONS PROVIDES THIS
    INFORMATION ON AN "AS-IS" BASIS. CREATIVE COMMONS MAKES NO WARRANTIES
    REGARDING THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS
    PROVIDED HEREUNDER, AND DISCLAIMS LIABILITY FOR DAMAGES RESULTING FROM
    THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS PROVIDED
    HEREUNDER.

Statement of Purpose

The laws of most jurisdictions throughout the world automatically confer
exclusive Copyright and Related Rights (defined below) upon the creator
and subsequent owner(s) (each and all, an "owner") of an original work of
authorship and/or a database (each, a "Work").

Certain owners wish to permanently relinquish those rights to a Work for
the purpose of contributing to a commons of creative, cultural and
scientific works ("Commons") that the public can reliably and without fear
of later claims of infringement build upon, modify, incorporate in other
works, reuse and redistribute as freely as possible in any form whatsoever
and for any purposes, including without limitation commercial purposes.
These owners may contribute to the Commons to promote the ideal of a free
culture and the further production of creative, cultural and scientific
works, or to gain reputation or greater distribution for their Work in
part through the use and efforts of others.

For these and/or other purposes and motivations, and without any
expectation of additional consideration or compensation, the person
associating CC0 with a Work (the "Affirmer"), to the extent that he or she
is an owner of Copyright and Related Rights in the Work, voluntarily
elects to apply CC0 to the Work and publicly distribute the Work under its
terms, with knowledge of his or her Copyright and Related Rights in the
Work and the meaning and intended legal effect of CC0 on those rights.

1. Copyright and Related Rights. A Work made available under CC0 may be
protected by copyright and related or neighboring rights ("Copyright and
Related Rights"). Copyright and Related Rights include, but are not
limited to, the following:

  i. the right to reproduce, adapt, distribute, perform, display,
     communicate, and translate a Work;
 ii. moral rights retained by the original author(s) and/or performer(s);
iii. publicity and privacy rights pertaining to a person's image or
     likeness depicted in a Work;
 iv. rights protecting against unfair competition in regards to a Work,
     subject to the limitations in paragraph 4(a), below;
  v. rights protecting the extraction, dissemination, use and reuse of data
     in a Work;
 vi. database rights (such as those arising under Directive 96/9/EC of the
     European Parliament and of the Council of 11 March 1996 on the legal
     protection of databases, and under any national implementation
     thereof, including any amended or successor version of such
     directive); and
vii. other similar, equivalent or corresponding rights throughout the
     world based on applicable law or treaty, and any national
     implementations thereof.

2. Waiver. To the greatest extent permitted by, but not in contravention
of, applicable law, Affirmer hereby overtly, fully, permanently,
irrevocably and unconditionally waives, abandons, and surrenders all of
Affirmer's Copyright and Related Rights and associated claims and causes
of action, whether now known or unknown (including existing as well as
future claims and causes of action), in the Work (i) in all territories
worldwide, (ii) for the maximum duration provided by applicable law or
treaty (including future time extensions), (iii) in any current or future
medium and for any number of copies, and (iv) for any purpose whatsoever,
including without limitation commercial, advertising or promotional
purposes (the "Waiver"). Affirmer makes the Waiver for the benefit of each
member of the public at large and to the detriment of Affirmer's heirs and
successors, fully intending that such Waiver shall not be subject to
revocation, rescission, cancellation, termination, or any other legal or
equitable action to disrupt the quiet enjoyment of the Work by the public
as contemplated by Affirmer's express Statement of Purpose.

3. Public License Fallback. Should any part of the Waiver for any reason
be judged legally invalid or ineffective under applicable law, then the
Waiver shall be preserved to the maximum extent permitted taking into
account Affirmer's express Statement of Purpose. In addition, to the
extent the Waiver is so judged Affirmer hereby grants to each affected
person a royalty-free, non transferable, non sublicensable, non exclusive,
irrevocable and unconditional license to exercise Affirmer's Copyright and
Related Rights in the Work (i) in all territories worldwide, (ii) for the
maximum duration provided by applicable law or treaty (including future
time extensions), (iii) in any current or future medium and for any number
of copies, and (iv) for any purpose whatsoever, including without
limitation commercial, advertising or promotional purposes (the
"License"). The License shall be deemed effective as of the date CC0 was
applied by Affirmer to the Work. Should any part of the License for any
reason be judged legally invalid or ineffective under applicable law, such
partial invalidity or ineffectiveness shall not invalidate the remainder
of the License, and in such case Affirmer hereby affirms that he or she
will not (i) exercise any of his or her remaining Copyright and Related
Rights in the Work or (ii) assert any associated claims and causes of
action with respect to the Work, in either case contrary to Affirmer's
express Statement of Purpose.

4. Limitations and Disclaimers.

 a. No trademark or patent rights held by Affirmer are waived, abandoned,
    surrendered, licensed or otherwise affected by this document.
 b. Affirmer offers the Work as-is and makes no representations or
    warranties of any kind concerning the Work, express, implied,
    statutory or otherwise, including without limitation warranties of
    title, merchantability, fitness for a particular purpose, non
    infringement, or the absence of latent or other defects, accuracy, or
    the present or absence of errors, whether or not discoverable, all to
    the greatest extent permissible under applicable law.
 c. Affirmer disclaims responsibility for clearing rights of other persons
    that may apply to the Work or any use thereof, including without
    limitation any person's Copyright and Related Rights in the Work.
    Further, Affirmer disclaims responsibility for obtaining any necessary
    consents, permissions or other rights required for any use of the
    Work.
 d. Affirmer understands and acknowledges that Creative Commons is not a
    party to this document and has no duty or obligation with respect to
    this CC0 or use of the Work.


*/

import { ipcRenderer } from "electron";
import process from "node:process";

globalThis.electronAPI = {
    minimize: () => ipcRenderer.invoke("minimize-window"),
    maximize: () => ipcRenderer.invoke("maximize-window"),
    close: () => ipcRenderer.invoke("close-window"),
};

// ---------------------------------------------------------------------------
// UGC sandboxing: allow the Rails UI (running inside the #content-frame iframe)
// to request that Electron opens the experience in a dedicated, sandboxed
// BrowserView.
//
// We intentionally do NOT expose ipcRenderer to web content. Instead, we accept
// a narrowly-scoped postMessage protocol from the trusted Rails iframe.
// ---------------------------------------------------------------------------

const APP_URL = process.env.APP_URL || "https://localhost:3000";
const APP_ORIGIN = (() => {
    try {
        return new URL(APP_URL).origin;
    } catch {
        return;
    }
})();

const resolveAllowedUgcUrl = (rawUrl) => {
    if (!rawUrl || typeof rawUrl !== "string") return;

    let u;
    try {
        u =
            APP_ORIGIN && rawUrl.startsWith("/")
                ? new URL(rawUrl, APP_ORIGIN)
                : new URL(rawUrl);
    } catch {
        return;
    }

    if (!APP_ORIGIN || u.origin !== APP_ORIGIN) return;
    if (!u.pathname.startsWith("/experiences/")) return;
    if (!u.pathname.includes("/electron_sandbox")) return;

    return u.toString();
};

const getRailsIframeWindow = () => {
    const iframe = document.querySelector("#content-frame");
    return iframe && iframe.contentWindow ? iframe.contentWindow : undefined;
};

window.addEventListener("message", async (event) => {
    try {
        // Only accept commands from the Rails app iframe.
        const railsWin = getRailsIframeWindow();
        if (!railsWin || event.source !== railsWin) return;

        // Origin allowlist (defense-in-depth).
        if (APP_ORIGIN && event.origin !== APP_ORIGIN) return;

        const data = event.data;
        if (!data || typeof data !== "object") return;

        if (data.type === "libreverse.ugc.open") {
            const resolved = resolveAllowedUgcUrl(data.url);
            if (!resolved) return;
            await ipcRenderer.invoke("ugc:view:open", { url: resolved });
        }

        if (data.type === "libreverse.ugc.close") {
            await ipcRenderer.invoke("ugc:view:close");
        }
    } catch {
        // Swallow errors: never crash preload due to untrusted messages.
    }
});

// Set up traffic lights (either injected or server-rendered)
const setupTrafficLights = () => {
    const trafficLights = document.querySelector(".traffic-lights");
    if (!trafficLights) {
        return;
    }

    // Check if already set up
    if (trafficLights.dataset.setup === "true") {
        return;
    }
    trafficLights.dataset.setup = "true";

    // Inject CSS for traffic lights
    const style = document.createElement("style");
    style.textContent = `
    .traffic-lights {
      position: absolute;
      z-index: 1000;
      display: flex;
      gap: 8px;
      -webkit-app-region: no-drag;
    }

    .traffic-light {
      width: 12px;
      height: 12px;
      cursor: default;
      outline: none;
    }
  `;
    document.head.append(style);

    // Position the traffic lights based on platform
    let positionStyle;
    positionStyle =
        process.platform === "darwin"
            ? "left: 12px; top: 12px;"
            : "right: 12px; top: 12px;";
    trafficLights.style.cssText += positionStyle;

    let forceGrayscale = process.env.FORCE_GRAYSCALE_TRAFFIC_LIGHTS === "true";

    // Generate data URLs for the appropriate platform
    let closeNormalData, closeHoverData, closePressData;
    let minimizeNormalData, minimizeHoverData, minimizePressData;
    let maximizeNormalData, maximizeHoverData, maximizePressData;

    if (process.platform === "darwin" && !forceGrayscale) {
        // macOS colored buttons
        closeNormalData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#e24b41"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#ed6a5f"/></g></svg>`)}`;
        closeHoverData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#e24b41"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#ed6a5f"/><g fill="#460804"><path d="m22.5 57.8 35.3-35.3c1.4-1.4 3.6-1.4 5 0l.1.1c1.4 1.4 1.4 3.6 0 5l-35.3 35.3c-1.4 1.4-3.6 1.4-5 0l-.1-.1c-1.3-1.4-1.3-3.6 0-5z"/><path d="m27.6 22.5 35.3 35.3c1.4 1.4 1.4 3.6 0 5l-.1.1c-1.4 1.4-3.6 1.4-5 0l-35.3-35.3c-1.4-1.4-1.4-3.6 0-5l.1-.1c1.4-1.3 3.6-1.3 5 0z"/></g></g></svg>`)}`;
        closePressData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#e24b41"/><path d="m42.7 81.7c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#ed6a5f"/><g fill="#170101"><path d="m22.5 57.8 35.3-35.3c1.4-1.4 3.6-1.4 5 0l.1.1c1.4 1.4 1.4 3.6 0 5l-35.3 35.3c-1.4 1.4-3.6 1.4-5 0l-.1-.1c-1.4-1.4-1.4-3.7 0-5z"/><path d="m27.5 22.5 35.3 35.3c1.4 1.4 1.4 3.6 0 5l-.1.1c-1.4 1.4-3.6 1.4-5 0l-35.3-35.3c-1.4-1.4-1.4-3.6 0-5l.1-.1c1.4-1.4 3.7-1.4 5 0z"/></g></g></svg>`)}`;
        minimizeNormalData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#e1a73e"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#f6be50"/></g></svg>`)}`;
        minimizeHoverData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#e1a73e"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#f6be50"/><path d="m17.8 39.1h49.9c1.9 0 3.5 1.6 3.5 3.5v.1c0 1.9-1.6 3.5-3.5 3.5h-49.9c-1.9 0-3.5-1.6-3.5-3.5v-.1c0-1.9 1.5-3.5 3.5-3.5z" fill="#90591d"/></g></svg>`)}`;
        minimizePressData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7c0 23.5 19 42.7 42.7 42.7z" fill="#e1a73e"/><path d="m42.7 81.7c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1c-.1 21.6 17.4 39.1 39.1 39.1z" fill="#f6be50"/><path d="m17.7 39.1h49.9c1.9 0 3.5 1.6 3.5 3.5v.1c0 1.9-1.6 3.5-3.5 3.5h-49.9c-1.9 0-3.5-1.6-3.5-3.5v-.1c0-1.9 1.6-3.5 3.5-3.5z" fill="#532a0a"/></g></svg>`)}`;
        maximizeNormalData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#2dac2f"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#61c555"/></g></svg>`)}`;
        maximizeHoverData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#2dac2f"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1c0 21.5 17.5 39.1 39.1 39.1z" fill="#61c555"/><path d="m31.2 20.8h26.7c3.6 0 6.5 2.9 6.5 6.5v26.7zm23.2 43.7h-26.8c-3.6 0-6.5-2.9-6.5-6.5v-26.8z" fill="#2a6218"/></g></svg>`)}`;
        maximizePressData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#2dac2f"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1c0 21.5 17.5 39.1 39.1 39.1z" fill="#61c555"/><path d="m31.2 20.8h26.7c3.6 0 6.5 2.9 6.5 6.5v26.7zm23.2 43.7h-26.8c-3.6 0-6.5-2.9-6.5-6.5v-26.8z" fill="#113107"/></g></svg>`)}`;
    } else {
        // Gray buttons for Windows/Linux or forced grayscale
        closeNormalData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#888888"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#aaaaaa"/></g></svg>`)}`;
        closeHoverData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#888888"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#aaaaaa"/><g fill="#333333"><path d="m22.5 57.8 35.3-35.3c1.4-1.4 3.6-1.4 5 0l.1.1c1.4 1.4 1.4 3.6 0 5l-35.3 35.3c-1.4 1.4-3.6 1.4-5 0l-.1-.1c-1.3-1.4-1.3-3.6 0-5z"/><path d="m27.6 22.5 35.3 35.3c1.4 1.4 1.4 3.6 0 5l-.1.1c-1.4 1.4-3.6 1.4-5 0l-35.3-35.3c-1.4-1.4-1.4-3.6 0-5l.1-.1c1.4-1.3 3.6-1.3 5 0z"/></g></g></svg>`)}`;
        closePressData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#888888"/><path d="m42.7 81.7c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#aaaaaa"/><g fill="#111111"><path d="m22.5 57.8 35.3-35.3c1.4-1.4 3.6-1.4 5 0l.1.1c1.4 1.4 1.4 3.6 0 5l-35.3 35.3c-1.4 1.4-3.6 1.4-5 0l-.1-.1c-1.4-1.4-1.4-3.7 0-5z"/><path d="m27.5 22.5 35.3 35.3c1.4 1.4 1.4 3.6 0 5l-.1.1c-1.4 1.4-3.6 1.4-5 0l-35.3-35.3c-1.4-1.4-1.4-3.6 0-5l.1-.1c1.4-1.4 3.7-1.4 5 0z"/></g></g></svg>`)}`;
        minimizeNormalData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#888888"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#aaaaaa"/></g></svg>`)}`;
        minimizeHoverData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#888888"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#aaaaaa"/><path d="m17.8 39.1h49.9c1.9 0 3.5 1.6 3.5 3.5v.1c0 1.9-1.6 3.5-3.5 3.5h-49.9c-1.9 0-3.5-1.6-3.5-3.5v-.1c0-1.9 1.5-3.5 3.5-3.5z" fill="#333333"/></g></svg>`)}`;
        minimizePressData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7c0 23.5 19 42.7 42.7 42.7z" fill="#888888"/><path d="m42.7 81.7c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1c-.1 21.6 17.4 39.1 39.1 39.1z" fill="#aaaaaa"/><path d="m17.7 39.1h49.9c1.9 0 3.5 1.6 3.5 3.5v.1c0 1.9-1.6 3.5-3.5 3.5h-49.9c-1.9 0-3.5-1.6-3.5-3.5v-.1c0-1.9 1.6-3.5 3.5-3.5z" fill="#111111"/></g></svg>`)}`;
        maximizeNormalData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#888888"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#aaaaaa"/></g></svg>`)}`;
        maximizeHoverData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#888888"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#aaaaaa"/><path d="m31.2 20.8h26.7c3.6 0 6.5 2.9 6.5 6.5v26.7zm23.2 43.7h-26.8c-3.6 0-6.5-2.9-6.5-6.5v-26.8z" fill="#333333"/></g></svg>`)}`;
        maximizePressData = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#888888"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1c0 21.5 17.5 39.1 39.1 39.1z" fill="#aaaaaa"/><path d="m31.2 20.8h26.7c3.6 0 6.5 2.9 6.5 6.5v26.7zm23.2 43.7h-26.8c-3.6 0-6.5-2.9-6.5-6.5v-26.8z" fill="#111111"/></g></svg>`)}`;
    }

    // Update the existing button images
    const closeButton = document.querySelector("#close");
    const minimizeButton = document.querySelector("#minimize");
    const maximizeButton = document.querySelector("#maximize");

    if (closeButton) closeButton.src = closeNormalData;
    if (minimizeButton) minimizeButton.src = minimizeNormalData;
    if (maximizeButton) maximizeButton.src = maximizeNormalData;

    // Function to update button sources based on focus (for macOS)
    const updateButtonSources = (focused) => {
        if (process.platform === "darwin" && !forceGrayscale) {
            // For macOS, switch between colored and gray versions
            const newCloseNormal = focused
                ? `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#e24b41"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#ed6a5f"/></g></svg>`)}`
                : `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#888888"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#aaaaaa"/></g></svg>`)}`;
            const newMinimizeNormal = focused
                ? `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#e1a73e"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#f6be50"/></g></svg>`)}`
                : `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#888888"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#aaaaaa"/></g></svg>`)}`;
            const newMaximizeNormal = focused
                ? `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#2dac2f"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#61c555"/></g></svg>`)}`
                : `data:image/svg+xml;charset=utf-8,${encodeURIComponent(`<svg enable-background="new 0 0 85.4 85.4" viewBox="0 0 85.4 85.4" xmlns="http://www.w3.org/2000/svg"><g clip-rule="evenodd" fill-rule="evenodd"><path d="m42.7 85.4c23.6 0 42.7-19.1 42.7-42.7s-19.1-42.7-42.7-42.7-42.7 19.1-42.7 42.7 19.1 42.7 42.7 42.7z" fill="#888888"/><path d="m42.7 81.8c21.6 0 39.1-17.5 39.1-39.1s-17.5-39.1-39.1-39.1-39.1 17.5-39.1 39.1 17.5 39.1 39.1 39.1z" fill="#aaaaaa"/></g></svg>`)}`;
            if (closeButton) closeButton.src = newCloseNormal;
            if (minimizeButton) minimizeButton.src = newMinimizeNormal;
            if (maximizeButton) maximizeButton.src = newMaximizeNormal;
        }
    };

    // Global hover state
    let hoverCount = 0;
    const imgs = [closeButton, minimizeButton, maximizeButton].filter(Boolean);
    let normalSrcs = [closeNormalData, minimizeNormalData, maximizeNormalData];
    let hoverSrcs = [closeHoverData, minimizeHoverData, maximizeHoverData];
    let pressSrcs = [closePressData, minimizePressData, maximizePressData];

    // Window focus/blur listeners
    window.addEventListener("focus", () => {
        updateButtonSources(true);
    });
    window.addEventListener("blur", () => {
        updateButtonSources(false);
    });

    for (const [index, img] of imgs.entries()) {
        img.addEventListener("mouseenter", () => {
            hoverCount++;
            for (const [index_, index__] of imgs.entries())
                index__.src = hoverSrcs[index_];
        });
        img.addEventListener("mouseleave", () => {
            hoverCount--;
            if (hoverCount === 0) {
                for (const [index_, index__] of imgs.entries())
                    index__.src = normalSrcs[index_];
            }
        });
        img.addEventListener("mousedown", () => {
            img.src = pressSrcs[index];
        });
        img.addEventListener("mouseup", () => {
            img.src = hoverSrcs[index];
        });
        img.addEventListener("click", () => {
            if (globalThis.electronAPI) {
                switch (img.id) {
                    case "close": {
                        globalThis.electronAPI.close();
                        break;
                    }
                    case "minimize": {
                        globalThis.electronAPI.minimize();
                        break;
                    }
                    case "maximize": {
                        globalThis.electronAPI.maximize();
                        break;
                    }
                }
            }
        });
    }

    // Set initial state based on current window focus
    setTimeout(() => {
        const isFocused = document.hasFocus();
        updateButtonSources(isFocused);
    }, 100);
};

document.addEventListener("DOMContentLoaded", setupTrafficLights);
