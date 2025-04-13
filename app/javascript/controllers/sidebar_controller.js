import ApplicationController from "./application_controller"

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
    console.log('Sidebar toggleHover triggered - Before Reflex HTML:', this.element.outerHTML);
    this.stimulate('SidebarReflex#toggle_hover', this.element).then(() => {
      console.log('Sidebar toggleHover triggered - After Reflex HTML:', this.element.outerHTML);
    }).catch(error => {
      console.error('Sidebar toggleHover error:', error);
    });
  }

  // Note: Explicit expand/collapse toggle is not handled by this controller currently.
  // It would likely be a separate action calling a different reflex method (e.g., set_expanded_state)
  // or potentially handled via data-reflex attribute directly on a toggle button.
}
