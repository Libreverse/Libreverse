import { Controller } from "@hotwired/stimulus";
import StimulusReflex from "stimulus_reflex";

export default class extends Controller {
    static values = { id: String };

    connect() {
        StimulusReflex.register(this);
        // No client-side state needed
    }
    
    disconnect() {
        // No listeners to remove
    }

    hover(event) {
        // Tell the server the desired state is true
        this.stimulate("SidebarReflex#set_hover_state", {
            sidebarId: this.element.dataset.sidebarId || "main",
            desiredState: true 
        });
    }

    unhover(event) {
        // Tell the server the desired state is false
        this.stimulate("SidebarReflex#set_hover_state", {
            sidebarId: this.element.dataset.sidebarId || "main",
            desiredState: false
        });
    }
}
