import GlassController from "./glass_controller.js";
import StimulusReflex from "stimulus_reflex";

/**
 * Drawer Controller - extends GlassController for drawer/modal components
 * Manages the state of a drawer, with optimistic UI updates and backend state synchronization.
 */
export default class extends GlassController {
    static values = {
        ...GlassController.values,
        componentType: { type: String, default: "drawer" },
        cornerRounding: { type: String, default: "top" },
        borderRadius: { type: Number, default: 20 },
        tintOpacity: { type: Number, default: 0.1 },
        expanded: { type: Boolean, default: false },
        drawerId: { type: String, default: "main" },
        height: { type: Number, default: 60 },
        expandedHeight: { type: Number, default: 600 },
    };

    static targets = ["drawer", "overlay", "content", "icon"];

    connect() {
        super.connect();
        console.log("[GlassDrawerController] Connected", {
            element: this.element,
            expanded: this.expandedValue,
        });

        // Register with StimulusReflex to enable `this.stimulate`
        StimulusReflex.register(this);

        this.boundHandleKeydown = this.handleKeydown.bind(this);
        this.boundDrawerEventHandler = this.handleDrawerEvent.bind(this);
        document.addEventListener("keydown", this.boundHandleKeydown);
        document.addEventListener(
            "drawer:toggle",
            this.boundDrawerEventHandler,
        );

        // Store initial state to prevent unwanted resets
        this._initialExpanded = this.expandedValue;

        // Initial UI setup based on the starting `expandedValue`
        // Defer UI update until the next frame to ensure targets are available.
        requestAnimationFrame(() => {
            this.updateUI();
        });
    }

    disconnect() {
        document.removeEventListener("keydown", this.boundHandleKeydown);
        document.removeEventListener(
            "drawer:toggle",
            this.boundDrawerEventHandler,
        );
        super.disconnect();
    }

    // Drawers do not have navigation items.
    getNavItems() {
        return [];
    }

    // No special click handling needed for the drawer itself.
    handleNavClick() {}

    // This can be simplified or removed if styling is handled by CSS.
    customPostRenderSetup() {
        console.log("[GlassDrawerController] Custom post-render setup");
        // Ensure glass initialization doesn't change the drawer state
        // Preserve the current expanded state
        const currentExpanded = this.expandedValue;

        // After glass setup, restore the state if it was changed
        requestAnimationFrame(() => {
            if (this.expandedValue !== currentExpanded) {
                console.log(
                    "[GlassDrawerController] Restoring expanded state after glass setup:",
                    currentExpanded,
                );
                this.expandedValue = currentExpanded;
            }
        });
    }

    // StimulusReflex lifecycle callbacks
    beforeReflex() {
        // Called before reflex actions - no special handling needed
        console.log(
            "[GlassDrawerController] Before reflex - UI already updated",
        );
    }

    afterReflex(element, reflex) {
        console.log("[GlassDrawerController] After reflex:", reflex);
        // Server acknowledgment received - no UI changes needed as they were already applied optimistically
    }

    reflexError(element, reflex, error) {
        console.error("[GlassDrawerController] Reflex error:", error);
        // On error, we could potentially revert the UI state here if needed
    }

    // --- Drawer Actions ---

    /**
     * Toggles the drawer state immediately on the client-side.
     * Server state is updated asynchronously for persistence only.
     */
    toggle(event) {
        event?.preventDefault();

        // Immediate UI update - no waiting for server
        this.expandedValue = !this.expandedValue;

        // Fire-and-forget server update for persistence
        // Use setTimeout to ensure this doesn't block the UI update
        setTimeout(() => {
            this.stimulate("DrawerReflex#toggle", {
                drawer_id: this.drawerIdValue,
                expanded: this.expandedValue,
            });
        }, 0);
    }

    /**
     * Opens the drawer immediately if it is not already open.
     */
    open() {
        if (this.expandedValue) return;

        // Immediate UI update
        this.expandedValue = true;

        // Fire-and-forget server update
        setTimeout(() => {
            this.stimulate("DrawerReflex#toggle", {
                drawer_id: this.drawerIdValue,
                expanded: true,
            });
        }, 0);
    }

    /**
     * Closes the drawer immediately if it is not already closed.
     */
    close() {
        if (!this.expandedValue) return;

        // Immediate UI update
        this.expandedValue = false;

        // Fire-and-forget server update
        setTimeout(() => {
            this.stimulate("DrawerReflex#toggle", {
                drawer_id: this.drawerIdValue,
                expanded: false,
            });
        }, 0);
    }

    // --- Event Handlers ---

    handleDrawerEvent(event) {
        if (event.detail.drawerId !== this.drawerIdValue) return;

        if (event.detail.open) {
            this.open();
        } else if (event.detail.close) {
            this.close();
        }
    }

    handleKeydown(event) {
        if (event.key === "Escape" && this.expandedValue) {
            this.close();
        }
    }

    // --- UI Update Methods ---

    /**
     * Centralized method to update all UI components based on the current state.
     */
    updateUI() {
        this.updateDrawerHeight();
        this.updateAriaExpanded();
        this.updateToggleIcon();
    }

    /**
     * Smoothly transitions the drawer's height.
     */
    updateDrawerHeight() {
        if (!this.hasDrawerTarget || !this.hasContentTarget) return;

        const drawer = this.drawerTarget;
        const content = this.contentTarget;

        const targetHeight = this.expandedValue
            ? `${this.expandedHeightValue}px`
            : `${this.heightValue}px`;
        const contentHeight = this.expandedValue
            ? `${this.expandedHeightValue - this.heightValue}px`
            : "0px";

        drawer.style.height = targetHeight;
        content.style.height = contentHeight;
        drawer.classList.toggle("drawer-expanded", this.expandedValue);

        // Only refresh glass if glass is actually enabled
        if (this.enableGlassValue && this.glassContainer) {
            this.refreshGlass();
        }
    }

    /**
     * Updates ARIA attributes for accessibility.
     */
    updateAriaExpanded() {
        if (this.hasDrawerTarget) {
            this.drawerTarget.setAttribute(
                "aria-expanded",
                this.expandedValue.toString(),
            );
        }
    }

    /**
     * Rotates the toggle icon to indicate state.
     */
    updateToggleIcon() {
        if (this.hasIconTarget) {
            this.iconTarget.classList.toggle("rotated", this.expandedValue);
        }
    }

    // --- Value Change Callbacks ---

    /**
     * This is the primary driver of UI changes. It is called automatically by Stimulus
     * whenever `this.expandedValue` is changed.
     */
    expandedValueChanged() {
        console.log(
            `[GlassDrawerController] Expanded state changed to: ${this.expandedValue}`,
        );
        this.updateUI();

        // Dispatch events to notify other parts of the application.
        const eventName = this.expandedValue
            ? "drawer:opened"
            : "drawer:closed";
        this.element.dispatchEvent(
            new CustomEvent(eventName, {
                detail: { drawerId: this.drawerIdValue },
                bubbles: true,
            }),
        );
    }
}
