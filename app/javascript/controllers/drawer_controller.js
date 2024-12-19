import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["icon", "content"];

  toggle() {
    this.element.querySelector(".drawer").classList.toggle("drawer-expanded");
    this.iconTarget.classList.toggle("rotated");
    this.contentTarget.classList.toggle("visible");
  }
}
