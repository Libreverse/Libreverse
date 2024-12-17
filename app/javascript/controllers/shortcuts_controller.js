import { Controller } from "@hotwired/stimulus";
import { visit } from "@hotwired/turbo";

export default class extends Controller {
  static targets = [];

  connect() {
    // Bind the keydown handler to this instance
    this.boundKeydown = this.keydown.bind(this)
    // Add global event listener
    window.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    // Clean up event listener
    window.removeEventListener("keydown", this.boundKeydown)
  }

  keydown(event) {
    if (
      event.target.tagName === "INPUT" ||
      event.target.tagName === "TEXTAREA"
    ) {
      return;
    }

    if (event.ctrlKey || event.altKey) {
      return;
    }

    switch (event.key) {
      case "h": {
        event.preventDefault();
        visit("/");
        break;
      }
      case "s": {
        event.preventDefault();
        visit("/search");
        break;
      }
      default:
        break;
    }
  }
}
