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

        // Apply initial state from server on connect
        const isExpanded = document.body.classList.contains("drawer-is-expanded");
        
        // Ensure DOM elements match the session state
        const drawer = this.element.querySelector(".drawer");
        if (isExpanded) {
            drawer.classList.add("drawer-expanded");
            this.iconTarget.classList.add("rotated");
            this.contentTarget.classList.add("visible");
        } else {
            drawer.classList.remove("drawer-expanded");
            this.iconTarget.classList.remove("rotated");
            this.contentTarget.classList.remove("visible");
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
        // Use the appropriate reflex based on configuration
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
