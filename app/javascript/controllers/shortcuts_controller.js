import { Controller } from "@hotwired/stimulus";
import { visit } from "@hotwired/turbo";

export default class extends Controller {
  static targets = [];

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
    }
  }
}
