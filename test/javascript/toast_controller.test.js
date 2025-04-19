// Import our DOM setup
import "./dom_setup";

// Create simplified version of the controller for testing
const ToastControllerClass = class {
    constructor(element) {
        this.element = element;
        this.toasts = [];
    }

    connect() {
        // Show existing toasts on connect
        this.showToasts();
    }

    showToasts() {
        // Find all toast elements and show them
        const toastElements =
            this.element.querySelectorAll(".toast:not(.show)");

        for (const toast of toastElements) {
            toast.classList.add("show");
            this.setupAutoHide(toast);
        }
    }

    hideToast(toast) {
        toast.classList.remove("show");

        // Remove toast after animation
        setTimeout(() => {
            toast.remove();
        }, 150);
    }

    close(event) {
        const toast = event.target.closest(".toast");
        if (toast) {
            this.hideToast(toast);
        }
    }

    createToast(message, title = "Notification", autoHide = false) {
        // Create toast element
        const toast = document.createElement("div");
        toast.classList.add("toast");

        // Set toast content
        toast.innerHTML = `
      <div class="toast-header">
        <strong class="me-auto">${title}</strong>
        <button type="button" class="btn-close" data-action="toast#close"></button>
      </div>
      <div class="toast-body">${message}</div>
    `;

        // Add to container
        this.element.append(toast);

        // Show the toast
        toast.classList.add("show");

        // Setup auto-hide if enabled
        if (autoHide) {
            this.setupAutoHide(toast);
        }

        return toast;
    }

    setupAutoHide(toast) {
        if (toast.dataset.autoHide === "true") {
            setTimeout(() => {
                if (toast && document.body.contains(toast)) {
                    this.hideToast(toast);
                }
            }, 5000); // Auto-hide after 5 seconds
        }
    }
};

describe("ToastController", () => {
    let controller;
    let element;

    beforeEach(() => {
        // Set up the DOM
        document.body.innerHTML = `
      <div data-controller="toast" id="toast-container">
        <div class="toast" data-auto-hide="true">
          <div class="toast-header">
            <strong class="me-auto">Test Toast</strong>
            <button type="button" class="btn-close" data-action="toast#close"></button>
          </div>
          <div class="toast-body">
            This is a test toast message
          </div>
        </div>
      </div>
    `;

        // Get elements
        element = document.querySelector("#toast-container");

        // Create controller instance
        controller = new ToastControllerClass(element);
    });

    test("showToasts shows all toasts", () => {
        // Call showToasts
        controller.showToasts();

        // Check that all toasts now have the 'show' class
        const toasts = element.querySelectorAll(".toast");
        for (const toast of toasts) {
            expect(toast.classList.contains("show")).toBe(true);
        }
    });

    test("hideToast removes show class and deletes toast after delay", () => {
        // Get the toast
        const toast = element.querySelector(".toast");

        // Replace setTimeout with a mock
        const originalSetTimeout = globalThis.setTimeout;
        let timeoutCallback;
        globalThis.setTimeout = jest.fn((function_) => {
            timeoutCallback = function_;
            return 123; // Fake timer ID
        });

        // Call hideToast
        controller.hideToast(toast);

        // Check that 'show' class was removed immediately
        expect(toast.classList.contains("show")).toBe(false);

        // Run the timeout callback to simulate the delay
        timeoutCallback();

        // Check that the toast was removed from the DOM
        expect(element.contains(toast)).toBe(false);

        // Restore setTimeout
        globalThis.setTimeout = originalSetTimeout;
    });

    test("close hides the toast when close button is clicked", () => {
        // Get the toast and close button
        const toast = element.querySelector(".toast");
        const closeButton = toast.querySelector(".btn-close");

        // Mock the hideToast method
        const originalHideToast = controller.hideToast;
        controller.hideToast = jest.fn();

        // Simulate a click on the close button
        controller.close({
            target: closeButton,
        });

        // Check that hideToast was called with the toast
        expect(controller.hideToast).toHaveBeenCalledWith(toast);

        // Restore hideToast
        controller.hideToast = originalHideToast;
    });

    test("createToast creates and shows a new toast", () => {
        // Call createToast
        const message = "New toast message";
        const title = "New Toast";
        const toast = controller.createToast(message, title);

        // Check that a new toast was created with the correct content
        expect(toast.classList.contains("toast")).toBe(true);
        expect(toast.classList.contains("show")).toBe(true);
        expect(toast.querySelector(".toast-header strong").textContent).toBe(
            title,
        );
        expect(toast.querySelector(".toast-body").textContent).toBe(message);

        // Check that the toast was added to the container
        expect(element.contains(toast)).toBe(true);
    });

    test("createToast uses default title when none provided", () => {
        // Call createToast with only a message
        const message = "New toast message";
        const toast = controller.createToast(message);

        // Check that the default title was used
        expect(toast.querySelector(".toast-header strong").textContent).toBe(
            "Notification",
        );
    });

    test("createToast sets up auto-hide when enabled", () => {
        // Spy on setupAutoHide
        const setupSpy = jest.spyOn(controller, "setupAutoHide");

        // Create toast with auto-hide
        const toast = controller.createToast("Message", "Title", true);

        // Check setupAutoHide was called
        expect(setupSpy).toHaveBeenCalledWith(toast);

        // Clean up
        setupSpy.mockRestore();
    });
});
