import { Controller } from "@hotwired/stimulus";
import { useHotkeys } from "stimulus-use/hotkeys";
import { visit } from "@hotwired/turbo";

export default class extends Controller {
  static targets = [];

  connect() {
    useHotkeys(this, {
      hotkeys: {
        h: {
          handler: this.goHome,
        },
        s: {
          handler: this.goSearch,
        },
      },
      filter: (event) => {
        return (
          event.target.tagName !== "INPUT" &&
          event.target.tagName !== "TEXTAREA" &&
          !event.ctrlKey &&
          !event.altKey
        );
      },
    });
  }

  goHome(event) {
    event.preventDefault();
    if (globalThis.location.pathname !== "/") {
      visit("/");
    }
  }

  goSearch(event) {
    event.preventDefault();
    if (globalThis.location.pathname !== "/search") {
      visit("/search");
    }
  }
}
