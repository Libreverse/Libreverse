import { Controller } from "@hotwired/stimulus";

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
            Turbo.visit("/");
            event.preventDefault();
          }
          break;
        case "s":
          if (!event.ctrlKey && !event.altKey) {
            Turbo.visit("/search");
            event.preventDefault();
          }
          break;
        case "w":
          if (!event.ctrlKey && !event.altKey) {
            Turbo.visit("/whitepaper");
            event.preventDefault();
          }
          break;
      }
    }
  }
}
