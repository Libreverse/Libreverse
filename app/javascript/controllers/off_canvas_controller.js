import { Controller } from "@hotwired/stimulus";
import { FoundationUtils } from "../libs/foundation.js";

// Off-Canvas Stimulus Controller
// Specifically handles Foundation off-canvas components with proper Turbo integration
export default class extends Controller {
    static targets = ["offCanvas"];
    static values = {
        position: { type: String, default: "left" },
        transition: { type: String, default: "push" },
        forceTop: { type: Boolean, default: false },
        autoFocus: { type: Boolean, default: true },
        closeOnClick: { type: Boolean, default: true },
        targetId: String, // ID of the off-canvas element to control
    };

    connect() {
        // Initialize Foundation's jQuery integration
        FoundationUtils.initializeFoundation();

        // Find the target off-canvas element
        this.offCanvasElement = this.hasTargetIdValue
            ? document.querySelector(`#${this.targetIdValue}`)
            : this.element;

        // Initialize the off-canvas component
        this.initializeOffCanvas();

        // Listen for Turbo events to reinitialize
        this.handleTurboLoad = this.handleTurboLoad.bind(this);
        document.addEventListener("turbo:load", this.handleTurboLoad);
        document.addEventListener("turbo:render", this.handleTurboLoad);
    }

    disconnect() {
        // Clean up Foundation instance
        if (this.offCanvasInstance) {
            this.offCanvasInstance.destroy();
            this.offCanvasInstance = undefined;
        }

        // Remove Turbo event listeners
        document.removeEventListener("turbo:load", this.handleTurboLoad);
        document.removeEventListener("turbo:render", this.handleTurboLoad);
    }

    handleTurboLoad() {
        this.initializeOffCanvas();
    }

    initializeOffCanvas() {
        const $ = FoundationUtils.initializeFoundation();

        // Use the target element (could be different from controller element)
        const targetElement = this.offCanvasElement;

        if (!targetElement) {
            console.error("[OffCanvasController] Target element not found");
            return;
        }

        // Destroy existing instance if it exists
        if (this.offCanvasInstance) {
            this.offCanvasInstance.destroy();
        }

        // Set up options
        const options = {
            position: this.positionValue,
            transition: this.transitionValue,
            forceTop: this.forceTopValue,
            autoFocus: this.autoFocusValue,
            closeOnClick: this.closeOnClickValue,
        };

        // Initialize Foundation OffCanvas
        import("foundation-sites").then(({ Foundation }) => {
            this.offCanvasInstance = new Foundation.OffCanvas(
                $(targetElement),
                options,
            );
        });
    }

    // Action methods for controlling the off-canvas
    toggle() {
        if (this.offCanvasInstance) {
            this.offCanvasInstance.toggle();
        } else {
            console.warn(
                "[OffCanvasController] Cannot toggle - instance not initialized",
            );
        }
    }

    open() {
        if (this.offCanvasInstance) {
            this.offCanvasInstance.open();
        } else {
            console.warn(
                "[OffCanvasController] Cannot open - instance not initialized",
            );
        }
    }

    close() {
        if (this.offCanvasInstance) {
            this.offCanvasInstance.close();
        } else {
            console.warn(
                "[OffCanvasController] Cannot close - instance not initialized",
            );
        }
    }

    // Handle clicks on trigger elements
    handleTrigger(event) {
        event.preventDefault();
        this.toggle();
    }
}
