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
    // Log HTML before reflex with specific focus on emojis
    console.log('Drawer toggle clicked - Before Reflex HTML:', this.element.outerHTML);
    
    // Check for emojis in the content before reflex
    const drawerContent = this.element.querySelector('.drawer-content');
    if (drawerContent) {
      console.log('Drawer content before reflex:', drawerContent.innerHTML);
      // Check if emoji image tags exist
      const emojiImgs = drawerContent.querySelectorAll('img.emoji');
      console.log(`Found ${emojiImgs.length} emoji images before reflex`);
      if (emojiImgs.length > 0) {
        console.log('Sample emoji image:', emojiImgs[0].outerHTML);
      }
    }

    // Find the inner drawer element that holds the data-expanded attribute
    const drawerElement = this.element.querySelector('.drawer');
    let currentState = 'false'; // Default to false if not found or attribute is missing
    if (drawerElement && drawerElement.dataset.expanded) {
      currentState = drawerElement.dataset.expanded;
    }
    console.log(`Passing current expanded state: ${currentState}`);

    // Pass the current state as a string argument to the reflex
    this.stimulate('DrawerReflex#toggle', currentState).then(() => {
      // Log HTML after reflex with specific focus on emojis
      console.log('Drawer toggle clicked - After Reflex HTML:', this.element.outerHTML);
      
      // Check for emojis in the content after reflex
      const updatedDrawerContent = this.element.querySelector('.drawer-content');
      if (updatedDrawerContent) {
        console.log('Drawer content after reflex:', updatedDrawerContent.innerHTML);
        // Check if emoji image tags exist
        const updatedEmojiImgs = updatedDrawerContent.querySelectorAll('img.emoji');
        console.log(`Found ${updatedEmojiImgs.length} emoji images after reflex`);
        if (updatedEmojiImgs.length > 0) {
          console.log('Sample emoji image after reflex:', updatedEmojiImgs[0].outerHTML);
        }
      }
    }).catch(error => {
      console.error('Drawer toggle error:', error);
    });
  }
}
