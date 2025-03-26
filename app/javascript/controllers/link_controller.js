import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { isCurrent: Boolean }
  
  connect() {
    // Nothing needed on connect
  }
  
  click(event) {
    if (this.isCurrentValue) {
      event.preventDefault();
      this.element.classList.add("sidebar-not-allowed-shake");
      setTimeout(() => {
        this.element.classList.remove("sidebar-not-allowed-shake");
      }, 750);
    }
  }
} 