// Ensures ReactOnRails re-scans component mounts on Turbo navigations and initial load.
import ReactOnRails from 'react-on-rails/client';

function fire(label) {
  try {
    ReactOnRails.reactOnRailsPageLoaded();
    // eslint-disable-next-line no-console
    console.debug(`[ReactOnRails Turbo Bridge] Fired reactOnRailsPageLoaded via ${label}`);
  } catch (e) {
    // eslint-disable-next-line no-console
    console.warn('[ReactOnRails Turbo Bridge] Error invoking reactOnRailsPageLoaded', e);
  }
}

// Initial DOM load (non-Turbo or first full load)
document.addEventListener('DOMContentLoaded', () => fire('DOMContentLoaded'));

// Turbo full page restore / navigation
document.addEventListener('turbo:load', () => fire('turbo:load'));
document.addEventListener('turbo:render', () => fire('turbo:render'));

// Optional: if using Turbo Drive cache restore events
document.addEventListener('turbo:before-render', () => {
  // eslint-disable-next-line no-console
  console.debug('[ReactOnRails Turbo Bridge] turbo:before-render');
});
