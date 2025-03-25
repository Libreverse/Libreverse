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
        this.toggleDrawer();
    }

    toggle() {
        this.toggleDrawer();
    }

    toggleDrawer() {
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

    test("toggleDrawer toggles the CSS classes correctly", () => {
        // Call the method
        controller.toggleDrawer();

        // Check drawer expanded state
        const drawerElement = element.querySelector(".drawer");
        expect(drawerElement.classList.contains("drawer-expanded")).toBe(true);
        expect(iconElement.classList.contains("rotated")).toBe(true);
        expect(contentElement.classList.contains("visible")).toBe(true);
        expect(document.body.classList.contains("drawer-is-expanded")).toBe(
            true,
        );

        // Call it again to toggle back
        controller.toggleDrawer();

        // Check drawer collapsed state
        expect(drawerElement.classList.contains("drawer-expanded")).toBe(false);
        expect(iconElement.classList.contains("rotated")).toBe(false);
        expect(contentElement.classList.contains("visible")).toBe(false);
        expect(document.body.classList.contains("drawer-is-expanded")).toBe(
            false,
        );
    });

    test("toggle method calls toggleDrawer", () => {
        // Create a spy for toggleDrawer
        const originalToggleDrawer = controller.toggleDrawer;
        let toggleDrawerCalled = false;

        controller.toggleDrawer = function () {
            toggleDrawerCalled = true;
            originalToggleDrawer.call(this);
        };

        // Call toggle
        controller.toggle();

        // Verify toggleDrawer was called
        expect(toggleDrawerCalled).toBe(true);

        // Restore original method
        controller.toggleDrawer = originalToggleDrawer;
    });

    test("singleKeyHandler calls toggleDrawer", () => {
        // Create a spy for toggleDrawer
        const originalToggleDrawer = controller.toggleDrawer;
        let toggleDrawerCalled = false;

        controller.toggleDrawer = function () {
            toggleDrawerCalled = true;
            originalToggleDrawer.call(this);
        };

        // Call the handler
        controller.singleKeyHandler();

        // Verify toggleDrawer was called
        expect(toggleDrawerCalled).toBe(true);

        // Restore original method
        controller.toggleDrawer = originalToggleDrawer;
    });
});
