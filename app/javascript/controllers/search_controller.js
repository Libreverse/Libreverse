import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["query", "results"];

  updateSearch(event) {
    const query = this.queryTarget.value.trim(); // Trim any whitespace
    let url;

    if (query === "") {
      url = "/search"; // No query, just use the base path
      history.replaceState({ search: null }, "", url);
    } else {
      const encodedQuery = encodeURIComponent(query).replace(/%20/g, "+");
      url = `/search?query=${encodedQuery}`;
      history.replaceState({ search: query }, "", url);
    }

    this.fetchSearchResults(query); // Here we'll send the unencoded query to the server
  }

  // Fetch search results
  fetchSearchResults(query) {
    let fetchUrl;

    if (query === "") {
      fetchUrl = "/search"; // No query, just fetch the base URL
    } else {
      fetchUrl = `/search?query=${encodeURIComponent(query).replace(/%20/g, "+")}`;
    }

    fetch(fetchUrl, {
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
      // Fetch results without updating history again
      this.fetchSearchResults(event.state.search);
    }
  }
}
