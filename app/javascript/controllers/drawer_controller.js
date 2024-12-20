import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["icon", "content"];

  connect() {
    // Bind the keydown handler to this instance
    this.boundKeydown = this.keydown.bind(this);
    // Add global event listener
    globalThis.addEventListener("keydown", this.boundKeydown);
  }

  disconnect() {
    // Clean up event listener
    globalThis.removeEventListener("keydown", this.boundKeydown);
  }

  keydown(event) {
    if (event.key === "d") {
      event.preventDefault();
      this.toggle();
    }
  }

  toggle() {
    this.element.querySelector(".drawer").classList.toggle("drawer-expanded");
    this.iconTarget.classList.toggle("rotated");
    this.contentTarget.classList.toggle("visible");
  }
}
