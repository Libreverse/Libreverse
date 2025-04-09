import ApplicationController from "./application_controller";
import { useHotkeys } from "stimulus-use/hotkeys";

export default class extends ApplicationController {
    static targets = ["icon", "content"];
    static values = { useForceUpdate: Boolean };

    connect() {
        super.connect(); // Call parent connect() to register StimulusReflex
        // StimulusReflex.register(this); // Handled by ApplicationController

        useHotkeys(this, {
            hotkeys: {
                d: {
                    handler: this.singleKeyHandler.bind(this),
                },
            },
            filter: this.filter,
        });
    }

    disconnect() {
        // No need to remove listeners, as we don't have any specific client-side ones for state anymore
    }

    // eslint-disable-next-line no-unused-vars
    singleKeyHandler(event) {
        this.toggle();
    }

    toggle() {
        // Find the .drawer element *within* the controller's element
        const drawerElement = this.element.querySelector(".drawer");
        if (!drawerElement) {
            console.error(
                "Could not find .drawer element within the controller scope",
            );
            return;
        }

        const drawerId = drawerElement.dataset.drawerId || "main";
        // We no longer read the state here, the server will handle it based on session
        // We still pass the ID so the server knows which drawer state to toggle
        const args = { drawerId: drawerId };

        if (this.useForceUpdateValue) {
            this.stimulate("DrawerReflex#force_update", args);
        } else {
            this.stimulate("DrawerReflex#toggle", args);
        }
    }

    // Method to switch to force update mode if regular toggle isn't working
    enableForceUpdate() {
        this.useForceUpdateValue = true;
    }
}
