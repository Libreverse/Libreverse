import ReactOnRails from "react-on-rails/client";
import MetaversePreview from "../../src/Metaverse3D/ror_components/MetaversePreview.jsx";

ReactOnRails.setOptions({
  turbo: true,
});

ReactOnRails.register({ MetaversePreview });

if (!globalThis.ReactOnRails) {
  globalThis.ReactOnRails = ReactOnRails;
}

const triggerHydration = () => {
  try {
    ReactOnRails.reactOnRailsPageLoaded();
  } catch (error) {
    console.error("ReactOnRails hydration failed", error);
  }
};

if (document.readyState === "complete" || document.readyState === "interactive") {
  triggerHydration();
} else {
  document.addEventListener("DOMContentLoaded", triggerHydration, { once: true });
}

document.addEventListener("turbo:render", triggerHydration);
document.addEventListener("turbo:load", triggerHydration);
