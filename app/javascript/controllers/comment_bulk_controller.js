import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = [];
    toggleAll(event) {
        const checked = event.target.checked;
        for (const callback of this.element
            .querySelectorAll("tbody input[type=checkbox]")) {
                callback.checked = checked;
            }
    }
}
