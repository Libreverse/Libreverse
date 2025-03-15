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

    // eslint-disable-next-line no-unused-vars
    singleKeyHandler(event) {
        this.toggleDrawer();
    }

    toggle() {
        this.toggleDrawer();
    }

    toggleDrawer() {
        const drawerElement = this.element.querySelector(".drawer");
        drawerElement.classList.toggle("drawer-expanded");
        this.iconTarget.classList.toggle("rotated");
        this.contentTarget.classList.toggle("visible");

        // Toggle the body class for expanded drawer
        document.body.classList.toggle("drawer-is-expanded");
    }
}
