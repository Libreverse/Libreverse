import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["form"];

  connect() {
    // Listen for the form submission completion
    this.element.addEventListener(
      "turbo:submit-end",
      this.updateURL.bind(this),
    );
  }

  disconnect() {
    // Clean up the event listener when the controller is disconnected
    this.element.removeEventListener(
      "turbo:submit-end",
      this.updateURL.bind(this),
    );
  }

  updateURL(event) {
    if (event.detail.success) {
      const formData = new FormData(this.element);
      const query = formData.get("query");
      const url = new URL(globalThis.location);

      if (query) {
        url.searchParams.set("query", query);
      } else {
        url.searchParams.delete("query");
      }

      // Update the browser's URL without reloading the page
      history.pushState({}, "", url);
    }
  }
}
