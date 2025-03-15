import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["link", "image"];

    connect() {
        const links = this.linkTargets;
        const currentPath = globalThis.location.pathname;

        for (const link of links) {
            const href = link.getAttribute("href");
            if (href === currentPath) {
                this.setImageCurrent(link);
            }
        }
    }

    // Method to mark the current link's image
    setImageCurrent(link) {
        const img = link.querySelector('[data-current-target="image"]');
        if (img) {
            img.classList.add("sidebar-current");
            link.classList.add("sidebar-default-cursor");
        }
    }

    // The method that should be linked to the click action
    handleClick(event) {
        // Ensure we have the correct event object
        const clickedElement = event.currentTarget || event.target;

        const currentPath = globalThis.location.pathname;
        const href = clickedElement.getAttribute("href");
        if (href === currentPath) {
            event.preventDefault();
            clickedElement.classList.add("sidebar-not-allowed-shake");
            setTimeout(() => {
                clickedElement.classList.remove("sidebar-not-allowed-shake");
            }, 750);
        }
    }
}
