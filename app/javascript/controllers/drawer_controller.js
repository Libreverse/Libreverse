import ApplicationController from "./application_controller"
import { diffHtml } from "../utils/html_diff"

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
    // Store HTML before reflex with specific focus on emojis
    const beforeHtml = this.element.outerHTML;
    console.log('Drawer toggle clicked - Before Reflex HTML:', beforeHtml);
    
    // Check for emojis in the content before reflex
    const drawerContent = this.element.querySelector('.drawer-content');
    let beforeContentHtml = '';
    if (drawerContent) {
      beforeContentHtml = drawerContent.innerHTML;
      console.log('Drawer content before reflex:', beforeContentHtml);
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
      // Get HTML after reflex
      const afterHtml = this.element.outerHTML;
      console.log('Drawer toggle clicked - After Reflex HTML:', afterHtml);
      
      // Log the diff for the entire drawer
      const wholeDiff = diffHtml(beforeHtml, afterHtml);
      if (wholeDiff.hasDiff) {
        console.log('HTML Differences in drawer:', wholeDiff.message);
        console.table(wholeDiff.attributeDiffs);
        if (wholeDiff.contentDiff.hasChanges) {
          console.log('Content differences at position', wholeDiff.contentDiff.position);
          console.log('Before:', wholeDiff.contentDiff.beforeContext);
          console.log('After:', wholeDiff.contentDiff.afterContext);
        }
      } else {
        console.log('No HTML differences detected in drawer');
      }
      
      // Check for emojis in the content after reflex
      const updatedDrawerContent = this.element.querySelector('.drawer-content');
      if (updatedDrawerContent) {
        const afterContentHtml = updatedDrawerContent.innerHTML;
        console.log('Drawer content after reflex:', afterContentHtml);
        
        // Diff the drawer content specifically
        if (beforeContentHtml) {
          const contentDiff = diffHtml(beforeContentHtml, afterContentHtml);
          if (contentDiff.hasDiff) {
            console.log('Drawer content differences:', contentDiff.message);
            console.table(contentDiff.attributeDiffs);
            if (contentDiff.contentDiff.hasChanges) {
              console.log('Content text differences:');
              console.log('Before:', contentDiff.contentDiff.beforeContext);
              console.log('After:', contentDiff.contentDiff.afterContext);
            }
          }
        }
        
        // Check if emoji image tags exist
        const updatedEmojiImgs = updatedDrawerContent.querySelectorAll('img.emoji');
        console.log(`Found ${updatedEmojiImgs.length} emoji images after reflex`);
        if (updatedEmojiImgs.length > 0) {
          console.log('Sample emoji image after reflex:', updatedEmojiImgs[0].outerHTML);
          
          // Compare emoji images if they exist in both before and after
          const emojiImgs = drawerContent?.querySelectorAll('img.emoji');
          if (emojiImgs?.length > 0 && updatedEmojiImgs.length > 0) {
            const emojiDiff = diffHtml(emojiImgs[0].outerHTML, updatedEmojiImgs[0].outerHTML);
            if (emojiDiff.hasDiff) {
              console.log('Emoji image differences:', emojiDiff.message);
              console.table(emojiDiff.attributeDiffs);
            }
          }
        }
      }
    }).catch(error => {
      console.error('Drawer toggle error:', error);
    });
  }
}
