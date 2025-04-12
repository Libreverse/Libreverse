import ApplicationController from "./application_controller";

/**
 * Controls the sidebar interactions, specifically toggling hover state.
 */
export default class extends ApplicationController {
    /**
     * Initializes the controller and registers it with StimulusReflex.
     */
    connect() {
        super.connect();
        // console.log("Sidebar controller connected", this.element);
    }

    /**
     * Called on mouseenter and mouseleave to toggle the hover state via a Reflex.
     * The Reflex action reads the current state and toggles it.
     * @param {Event} event - The mouse event.
     */
    toggleHover(/* event */) {
        const sidebarId = this.element.dataset.sidebarId || "main";
        // console.log(`Sidebar toggleHover triggered for ${sidebarId}`);

        // Call the reflex action. The reflex will handle toggling the state.
        // Pass the sidebar ID for context if needed by the reflex.
        this.stimulate("SidebarReflex#toggle_hover", { sidebar_id: sidebarId });
    }

    // Note: Assuming an explicit expand/collapse click might be handled by a different
    // action or directly by data-reflex if the state change only needs a morph.
    // If an explicit toggle *method* is needed, it would call SidebarReflex#set_expanded_state.
}
