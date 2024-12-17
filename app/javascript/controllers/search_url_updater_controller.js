import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="search-url-updater"
export default class extends Controller {
  connect() {
    // Bind the updateURL method to the class instance
    this.updateURL = this.updateURL.bind(this);
    // Listen to StimulusReflex 'after' event
    this.element.addEventListener("stimulus-reflex:after", this.updateURL);
  }

  disconnect() {
    this.element.removeEventListener("stimulus-reflex:after", this.updateURL);
  }

  updateURL(event) {
    const { reflex, error } = event.detail;
    if (!error && reflex === "SearchReflex#perform") {
      const query = this.element.value.trim();

      const url = new URL(globalThis.location);

      if (query === "") {
        url.searchParams.delete("query");
      } else {
        url.searchParams.set("query", query);
      }

      // Use replaceState to avoid adding a new history entry
      history.replaceState({}, "", url);
    }
  }
}
