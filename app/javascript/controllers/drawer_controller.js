import { Controller } from "@hotwired/stimulus";
import { useHotkeys } from "stimulus-use/hotkeys";

export default class extends Controller {
  static targets = ["icon", "content"];

  connect() {
    useHotkeys(this, {
      hotkeys: {
        d: {
          handler: this.singleKeyHandler.bind(this),
        },
      },
      filter: this.filter,
    });
  }

  singleKeyHandler(e) {
    this.element.querySelector(".drawer").classList.toggle("drawer-expanded");
    this.iconTarget.classList.toggle("rotated");
    this.contentTarget.classList.toggle("visible");
  }

  toggle() {
    this.element.querySelector(".drawer").classList.toggle("drawer-expanded");
    this.iconTarget.classList.toggle("rotated");
    this.contentTarget.classList.toggle("visible");
  }
}
