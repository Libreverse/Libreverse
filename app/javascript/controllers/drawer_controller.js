import ApplicationController from "./application_controller"

/**
 * Controls the drawer toggle interaction.
 */
export default class extends ApplicationController {
  connect () {
    super.connect()
    // console.log('Drawer controller connected', this.element);
  }

  /**
   * Called when the drawer toggle button is clicked.
   * Triggers the DrawerReflex#toggle action on the server.
   * Reads the current expanded state from the inner drawer element and passes it.
   * @param {Event} event - The click event.
   */
  toggle (event) {
    event.preventDefault()
    console.log('Drawer toggle clicked - Before Reflex HTML:', this.element.outerHTML);

    // Find the inner drawer element that holds the data-expanded attribute
    const drawerElement = this.element.querySelector('.drawer');
    let currentState = 'false'; // Default to false if not found or attribute is missing
    if (drawerElement && drawerElement.dataset.expanded) {
      currentState = drawerElement.dataset.expanded;
    }
    console.log(`Passing current expanded state: ${currentState}`);

    // Pass the current state as a string argument to the reflex
    this.stimulate('DrawerReflex#toggle', currentState).then(() => {
      console.log('Drawer toggle clicked - After Reflex HTML:', this.element.outerHTML);
    }).catch(error => {
      console.error('Drawer toggle error:', error);
    });
  }
}
