import { Controller } from "@hotwired/stimulus";
import { visit } from "@hotwired/turbo";

// Connects to data-controller="shortcuts"
export default class extends Controller {
  connect() {
    document.addEventListener("keydown", this.handleKeydown.bind(this));
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this));
  }

  handleKeydown(event) {
    if (
      event.target.tagName !== "INPUT" &&
      event.target.tagName !== "TEXTAREA"
    ) {
      switch (event.key) {
        case "h":
          if (!event.ctrlKey && !event.altKey) {
            visit("/");
            event.preventDefault();
          }
          break;
        case "s":
          if (!event.ctrlKey && !event.altKey) {
            visit("/search");
            event.preventDefault();
          }
          break;
      }
    }
  }
}
