import ApplicationController from "./application_controller";

export default class extends ApplicationController {
    static values = { id: String };

    connect() {
        super.connect(); // Call parent connect() to register StimulusReflex
        // StimulusReflex.register(this); // Handled by ApplicationController
    }

    disconnect() {
        // No listeners to remove
    }

    // Called by data-action directive on mouseenter/mouseleave
    toggleHover(event) {
        // Prevent default only if needed, hover usually doesn't have one
        // event.preventDefault();

        // Get the sidebar ID from the element's dataset
        const sidebarId = this.element.dataset.sidebarId || "main";

        // Call the reflex to toggle the server state and update DOM via CableReady
        this.stimulate("SidebarReflex#toggle_hover", { sidebar_id: sidebarId });
    }
}
