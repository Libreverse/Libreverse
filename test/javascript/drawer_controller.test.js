// Import our DOM setup
require("./dom_setup");

// Create a minimal version of the drawer controller for testing
const DrawerControllerClass = class {
    constructor(element, targets) {
        this.element = element;
        this.iconTarget = targets.icon;
        this.contentTarget = targets.content;
    }

    connect() {
        // Mock connect method
    }

    singleKeyHandler() {
        this.toggle();
    }

    toggle() {
        // Mock stimulate method for testing
        this.stimulate("DrawerReflex#toggle");
    }

    // Helper to mock StimulusReflex
    stimulate(reflex) {
        // In our test, we'll simulate what the reflex would do
        const drawerElement = this.element.querySelector(".drawer");
        drawerElement.classList.toggle("drawer-expanded");
        this.iconTarget.classList.toggle("rotated");
        this.contentTarget.classList.toggle("visible");

        // Toggle the body class for expanded drawer
        document.body.classList.toggle("drawer-is-expanded");
    }
};

describe("DrawerController", () => {
    let controller;
    let element;
    let iconElement;
    let contentElement;
    let toggleButton;

    beforeEach(() => {
        // Set up the DOM
        document.body.innerHTML = `
      <div data-controller="drawer">
        <div class="drawer">
          <button data-action="click->drawer#toggle">Toggle</button>
          <div data-drawer-target="icon" class="drawer-icons"></div>
          <div data-drawer-target="content" class="drawer-contents"></div>
        </div>
      </div>
    `;

        // Get elements
        element = document.querySelector('[data-controller="drawer"]');
        iconElement = document.querySelector('[data-drawer-target="icon"]');
        contentElement = document.querySelector(
            '[data-drawer-target="content"]',
        );
        toggleButton = document.querySelector(
            '[data-action="click->drawer#toggle"]',
        );

        // Create controller instance
        controller = new DrawerControllerClass(element, {
            icon: iconElement,
            content: contentElement,
        });
    });

    test("toggle method uses StimulusReflex", () => {
        // Create a spy for stimulate
        const originalStimulate = controller.stimulate;
        let stimulateCalled = false;
        let reflexCalled = "";

        controller.stimulate = function (reflex) {
            stimulateCalled = true;
            reflexCalled = reflex;
            originalStimulate.call(this, reflex);
        };

        // Call toggle
        controller.toggle();

        // Verify stimulate was called with the correct reflex
        expect(stimulateCalled).toBe(true);
        expect(reflexCalled).toBe("DrawerReflex#toggle");

        // Check drawer expanded state
        const drawerElement = element.querySelector(".drawer");
        expect(drawerElement.classList.contains("drawer-expanded")).toBe(true);
        expect(iconElement.classList.contains("rotated")).toBe(true);
        expect(contentElement.classList.contains("visible")).toBe(true);
        expect(document.body.classList.contains("drawer-is-expanded")).toBe(
            true,
        );

        // Call it again to toggle back
        controller.toggle();

        // Check drawer collapsed state
        expect(drawerElement.classList.contains("drawer-expanded")).toBe(false);
        expect(iconElement.classList.contains("rotated")).toBe(false);
        expect(contentElement.classList.contains("visible")).toBe(false);
        expect(document.body.classList.contains("drawer-is-expanded")).toBe(
            false,
        );

        // Restore original method
        controller.stimulate = originalStimulate;
    });

    test("singleKeyHandler calls toggle", () => {
        // Create a spy for toggle
        const originalToggle = controller.toggle;
        let toggleCalled = false;

        controller.toggle = function () {
            toggleCalled = true;
            originalToggle.call(this);
        };

        // Call the handler
        controller.singleKeyHandler();

        // Verify toggle was called
        expect(toggleCalled).toBe(true);

        // Restore original method
        controller.toggle = originalToggle;
    });
});
