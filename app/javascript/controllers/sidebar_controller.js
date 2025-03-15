import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    hover() {
        this.element.classList.add("sidebar-hovered");
    }

    unhover() {
        this.element.classList.remove("sidebar-hovered");
    }
}
