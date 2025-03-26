import { Controller } from "@hotwired/stimulus";
import StimulusReflex from "stimulus_reflex";

export default class extends Controller {
    static values = { id: String };

    connect() {
        StimulusReflex.register(this);

        // Default ID if not provided in the HTML
        if (!this.element.dataset.sidebarId) {
            this.element.dataset.sidebarId = "main";
        }

        // Get sidebar ID
        const sidebarId = this.element.dataset.sidebarId;

        // Restore hover state from localStorage when connecting after a Turbo navigation
        const storedHoverState = localStorage.getItem(
            `sidebar_hover_${sidebarId}`,
        );
        if (storedHoverState === "true") {
            this.element.classList.add("sidebar-hovered");
            this.element.dataset.hover = "true";
        } else {
            this.element.classList.remove("sidebar-hovered");
            this.element.dataset.hover = "false";
        }
    }

    hover() {
        // Get sidebar ID
        const sidebarId = this.element.dataset.sidebarId || "main";

        // Add the hover class immediately
        this.element.classList.add("sidebar-hovered");

        // Store state in localStorage
        localStorage.setItem(`sidebar_hover_${sidebarId}`, "true");

        // Update data attribute
        this.element.dataset.hover = "true";

        // Still call the reflex for server-side effects if needed
        this.stimulate("SidebarReflex#toggle_hover");
    }

    unhover() {
        // Get sidebar ID
        const sidebarId = this.element.dataset.sidebarId || "main";

        // Remove the hover class immediately
        this.element.classList.remove("sidebar-hovered");

        // Store state in localStorage
        localStorage.setItem(`sidebar_hover_${sidebarId}`, "false");

        // Update data attribute
        this.element.dataset.hover = "false";

        // Still call the reflex for server-side effects if needed
        this.stimulate("SidebarReflex#toggle_hover");
    }
}
