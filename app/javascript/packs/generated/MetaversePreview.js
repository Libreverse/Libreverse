import ReactOnRails from "react-on-rails/client";
import MetaversePreview from "../../src/Metaverse3D/ror_components/MetaversePreview.jsx";

console.info("[MetaversePreview pack] initializing", {
  existingReactOnRails: typeof globalThis.ReactOnRails,
});

ReactOnRails.register({ MetaversePreview });

if (globalThis.ReactOnRails !== ReactOnRails) {
  globalThis.ReactOnRails = ReactOnRails;
}
