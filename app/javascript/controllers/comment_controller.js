import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["replyForm"];

    showReply(event) {
        event.preventDefault();
        if (this.hasReplyFormTarget) {
            this.replyFormTarget.classList.toggle("hidden");
            const ta = this.replyFormTarget.querySelector("textarea");
            if (ta) ta.focus();
        }
    }
}
