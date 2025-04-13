import ApplicationController from "./application_controller"
import { diffHtml } from "../utils/html_diff"

/**
 * Controls the sidebar hover interactions.
 */
export default class extends ApplicationController {
  connect () {
    super.connect()
    // console.log('Sidebar controller connected', this.element);
  }

  /**
   * Called on mouseenter/mouseleave to trigger the reflex that toggles hover state.
   * Passes the element so the reflex can read data-sidebar-id.
   */
  toggleHover (/* event */) {
    const beforeHtml = this.element.outerHTML;
    console.log('Sidebar toggleHover triggered - Before Reflex HTML:', beforeHtml);
    
    this.stimulate('SidebarReflex#toggle_hover', this.element).then(() => {
      const afterHtml = this.element.outerHTML;
      console.log('Sidebar toggleHover triggered - After Reflex HTML:', afterHtml);
      
      // Log the diff
      const diff = diffHtml(beforeHtml, afterHtml);
      if (diff.hasDiff) {
        console.log('HTML Differences:', diff.message);
        console.table(diff.attributeDiffs);
        if (diff.contentDiff.hasChanges) {
          console.log('Content differences at position', diff.contentDiff.position);
          console.log('Before:', diff.contentDiff.beforeContext);
          console.log('After:', diff.contentDiff.afterContext);
        }
      } else {
        console.log('No HTML differences detected');
      }
    }).catch(error => {
      console.error('Sidebar toggleHover error:', error);
    });
  }

  // Note: Explicit expand/collapse toggle is not handled by this controller currently.
  // It would likely be a separate action calling a different reflex method (e.g., set_expanded_state)
  // or potentially handled via data-reflex attribute directly on a toggle button.
}
