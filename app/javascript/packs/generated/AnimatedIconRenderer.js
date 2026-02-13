import ReactOnRails from "react-on-rails/client";
import AnimatedIconRenderer from "../../src/iconsV2/ror_components/animated-icon-renderer";

ReactOnRails.register({
    AnimatedIconRenderer,
});

if (!globalThis.ReactOnRails) {
    globalThis.ReactOnRails = ReactOnRails;
}
