import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    connect() {
        // Basic auto-resize or future mentions hook
        const textarea = this.element.querySelector("textarea");
        if (textarea) {
            textarea.addEventListener("input", () => {
                textarea.style.height = "auto";
                textarea.style.height = textarea.scrollHeight + "px";
            });
        }
    }
}
