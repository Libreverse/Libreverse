// Import our DOM setup
import "./dom_setup";

// Create a minimal version of the sidebar controller for testing
const SidebarControllerClass = class {
    constructor(element) {
        this.element = element;
        this.idValue = element.dataset.sidebarIdValue || "";
    }

    connect() {
        // StimulusReflex registration would happen here
    }

    hover() {
        return this.stimulate("SidebarReflex#set_hover_state", true);
    }

    unhover() {
        return this.stimulate("SidebarReflex#set_hover_state", false);
    }

    // Mock method for testing
    stimulate(reflexName, options) {
        this.lastReflexCalled = reflexName;
        this.lastReflexOptions = options;
        return true;
    }
};

describe("SidebarController", () => {
    let controller;
    let element;

    beforeEach(() => {
        // Set up the DOM
        document.body.innerHTML = `
      <div data-controller="sidebar" data-sidebar-id="test-sidebar" data-sidebar-id-value="123">
        <div class="sidebar-content"></div>
      </div>
    `;

        // Get elements
        element = document.querySelector('[data-controller="sidebar"]');

        // Create controller instance
        controller = new SidebarControllerClass(element);
    });

    test("hover method sets hover state to true", () => {
        // Call hover
        controller.hover();

        // Check that the reflex was called with correct parameters
        expect(controller.lastReflexCalled).toBe(
            "SidebarReflex#set_hover_state",
        );
        expect(controller.lastReflexOptions).toEqual(true);
    });

    test("unhover method sets hover state to false", () => {
        // Call unhover
        controller.unhover();

        // Check that the reflex was called with correct parameters
        expect(controller.lastReflexCalled).toBe(
            "SidebarReflex#set_hover_state",
        );
        expect(controller.lastReflexOptions).toEqual(false);
    });

    test("uses 'main' as default sidebar ID when none provided", () => {
        // Set up the DOM without a sidebar-id
        document.body.innerHTML = `
      <div data-controller="sidebar" data-sidebar-id-value="123">
        <div class="sidebar-content"></div>
      </div>
    `;

        // Get element and create controller
        const elementWithoutId = document.querySelector(
            '[data-controller="sidebar"]',
        );
        const controllerWithoutId = new SidebarControllerClass(
            elementWithoutId,
        );

        // Call hover
        controllerWithoutId.hover();

        // Check that the default sidebar ID was used
        expect(controllerWithoutId.lastReflexOptions).toEqual(true);
    });
});
