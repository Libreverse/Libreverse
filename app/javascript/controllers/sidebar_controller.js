import { Controller } from "@hotwired/stimulus";
import StimulusReflex from "stimulus_reflex";

export default class extends Controller {
    static values = { id: String };

    connect() {
        StimulusReflex.register(this);
    }

    disconnect() {
        // No listeners to remove
    }

    // Called by data-action directive in the view
    hover() {
        // Update DOM immediately for instant feedback
        this.element.classList.add("sidebar-hovered");
        this.element
            .closest(".sidebar-container")
            .classList.add("sidebar-hovered");

        // Get the sidebar ID
        const sidebarId = this.element.dataset.sidebarId || "main";

        // Call the reflex to update the server state
        this.stimulate("SidebarReflex#set_hover_state", {
            sidebarId: sidebarId,
            desiredState: true,
        });
    }

    unhover() {
        // Update DOM immediately for instant feedback
        this.element.classList.remove("sidebar-hovered");
        this.element
            .closest(".sidebar-container")
            .classList.remove("sidebar-hovered");

        // Get the sidebar ID
        const sidebarId = this.element.dataset.sidebarId || "main";

        // Call the reflex to update the server state
        this.stimulate("SidebarReflex#set_hover_state", {
            sidebarId: sidebarId,
            desiredState: false,
        });
    }
}
