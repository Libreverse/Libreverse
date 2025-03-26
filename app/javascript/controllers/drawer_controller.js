import { Controller } from "@hotwired/stimulus";
import { useHotkeys } from "stimulus-use/hotkeys";
import StimulusReflex from "stimulus_reflex";

export default class extends Controller {
    static targets = ["icon", "content"];
    static values = { useForceUpdate: Boolean }

    connect() {
        StimulusReflex.register(this);

        useHotkeys(this, {
            hotkeys: {
                d: {
                    handler: this.singleKeyHandler.bind(this),
                },
            },
            filter: this.filter,
        });
        
        // Default ID if not provided in the HTML
        const drawer = this.element.querySelector(".drawer");
        if (!drawer.dataset.drawerId) {
            drawer.dataset.drawerId = "main";
        }
        
        const drawerId = drawer.dataset.drawerId;

        // Apply initial state from localStorage
        const isExpanded = localStorage.getItem(`drawer_expanded_${drawerId}`) === "true";
        
        // Ensure DOM elements match the state
        if (isExpanded) {
            drawer.classList.add("drawer-expanded");
            this.iconTarget.classList.add("rotated");
            this.contentTarget.classList.add("visible");
            document.body.classList.add("drawer-is-expanded");
            drawer.dataset.expanded = "true";
        } else {
            drawer.classList.remove("drawer-expanded");
            this.iconTarget.classList.remove("rotated");
            this.contentTarget.classList.remove("visible");
            document.body.classList.remove("drawer-is-expanded");
            drawer.dataset.expanded = "false";
        }
        
        // Initialize use-force-update value if not set
        if (this.hasUseForceUpdateValue === false) {
            this.useForceUpdateValue = false;
        }
    }

    // eslint-disable-next-line no-unused-vars
    singleKeyHandler(event) {
        this.toggle();
    }

    toggle() {
        // Manual toggle for immediate feedback to improve UX
        const drawer = this.element.querySelector(".drawer");
        const drawerId = drawer.dataset.drawerId || "main";
        const currentState = drawer.dataset.expanded === "true";
        const newState = !currentState;
        
        // Toggle classes immediately for responsive UI
        if (newState) {
            drawer.classList.add("drawer-expanded");
            this.iconTarget.classList.add("rotated");
            this.contentTarget.classList.add("visible");
            document.body.classList.add("drawer-is-expanded");
        } else {
            drawer.classList.remove("drawer-expanded");
            this.iconTarget.classList.remove("rotated");
            this.contentTarget.classList.remove("visible");
            document.body.classList.remove("drawer-is-expanded");
        }
        
        // Update data attribute
        drawer.dataset.expanded = newState ? "true" : "false";
        
        // Store state in localStorage for persistence
        localStorage.setItem(`drawer_expanded_${drawerId}`, newState ? "true" : "false");
        
        // Then use reflex for any server-side effects if needed
        if (this.useForceUpdateValue) {
            this.stimulate("DrawerReflex#force_update");
        } else {
            this.stimulate("DrawerReflex#toggle");
        }
    }

    // Method to switch to force update mode if regular toggle isn't working
    enableForceUpdate() {
        this.useForceUpdateValue = true;
    }
}
