// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["query", "results"];

  updateSearch(event) {
    const query = this.queryTarget.value;
    const url = `/search?search=${encodeURIComponent(query)}`;

    history.pushState({ search: query }, "", url); // Updates URL without page reload

    fetch(url, {
      headers: {
        Accept: "text/vnd.turbo-stream.html",
      },
    })
      .then((response) => response.text())
      .then((html) => Turbo.renderStreamMessage(html))
      .catch((error) => console.error("Error:", error));
  }

  // Handle back button
  connect() {
    window.addEventListener("popstate", this.popstateHandler.bind(this));
  }

  disconnect() {
    window.removeEventListener("popstate", this.popstateHandler.bind(this));
  }

  popstateHandler(event) {
    if (event.state && event.state.search) {
      this.queryTarget.value = event.state.search;
      this.updateSearch({ preventDefault: () => {} });
    }
  }
}
