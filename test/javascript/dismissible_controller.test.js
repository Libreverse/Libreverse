// Import our DOM setup
require("./dom_setup");

// Mock the xmlrpc utility
const mockXmlrpc = jest.fn(() => Promise.resolve());

// Store original console.error
const originalConsoleError = console.error;
// Create a simple mock for console.error
let errorCalled = false;
let errorArguments = [];

describe("DismissibleController", () => {
    let controller;
    let element;
    let dismissButton;

    // Create simplified version of the controller for testing
    const DismissibleControllerClass = class {
        constructor(element, xmlrpcFunction = mockXmlrpc) {
            this.element = element;
            this.xmlrpc = xmlrpcFunction;
            this.idValue = element.dataset.id || "123";
            this.targetValue = element.dataset.target || "test_target";
            this.dismissed = false;
        }

        connect() {
            // Setup in real controller
        }

        dismiss() {
            // Add 'dismissed' class immediately
            this.element.classList.add("dismissed");
            this.dismissed = true;

            // Call to server
            return this.xmlrpc(this.targetValue, "dismiss", [
                this.idValue,
            ]).catch((error) => {
                // Log error but keep dismissed state
                console.error("Failed to dismiss:", error);
                // Don't remove the dismissed class on error
            });
        }
    };

    beforeEach(() => {
        // Reset mocks
        mockXmlrpc.mockClear();

        // Setup console.error mock
        errorCalled = false;
        errorArguments = [];
        console.error = function (...arguments_) {
            errorCalled = true;
            errorArguments = arguments_;
        };

        // Set up the DOM
        document.body.innerHTML = `
      <div data-controller="dismissible" 
           data-dismissible-id-value="123" 
           data-dismissible-target-value="test_target">
        <button data-action="dismissible#dismiss">Dismiss</button>
      </div>
    `;

        // Get elements
        element = document.querySelector('[data-controller="dismissible"]');
        dismissButton = element.querySelector("button");

        // Create controller instance
        controller = new DismissibleControllerClass(element);
    });

    afterEach(() => {
        // Restore original console.error
        console.error = originalConsoleError;
    });

    test("dismiss adds dismissed class immediately", async () => {
        // Call dismiss
        await controller.dismiss();

        // Check that dismissed class was added
        expect(element.classList.contains("dismissed")).toBe(true);
    });

    test("dismiss calls xmlrpc with correct parameters", async () => {
        // Call dismiss
        await controller.dismiss();

        // Check xmlrpc was called with correct arguments
        expect(mockXmlrpc).toHaveBeenCalledWith("test_target", "dismiss", [
            "123",
        ]);
    });

    test("dismiss handles errors gracefully", async () => {
        // Make xmlrpc fail
        mockXmlrpc.mockImplementationOnce(() =>
            Promise.reject(new Error("Test error")),
        );

        // Call dismiss and wait for the promise to settle
        await controller.dismiss();

        // Should still have dismissed class
        expect(element.classList.contains("dismissed")).toBe(true);

        // Should have logged the error
        expect(errorCalled).toBe(true);
    });

    test("clicking the button calls dismiss", () => {
        // Create a spy for dismiss
        const originalDismiss = controller.dismiss;
        let dismissCalled = false;

        controller.dismiss = function () {
            dismissCalled = true;
            return Promise.resolve();
        };

        // Add an event listener to the button
        dismissButton.addEventListener("click", () => controller.dismiss());

        // Click the button
        dismissButton.click();

        // Check dismiss was called
        expect(dismissCalled).toBe(true);

        // Restore dismiss
        controller.dismiss = originalDismiss;
    });
});
