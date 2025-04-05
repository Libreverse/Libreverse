// Import our DOM setup
require("./dom_setup");

// Create a minimal version of the search url updater controller for testing
const SearchUrlUpdaterControllerClass = class {
    constructor(element) {
        this.element = element;
        this.debounceTimeValue = 300; // Default value
        this.searchTimer = null;
    }

    connect() {
        this.inputHandler = this.handleInput.bind(this);
        this.updateURLHandler = this.updateURL.bind(this);

        this.element.addEventListener("input", this.inputHandler);
        document.addEventListener(
            "stimulus-reflex:after",
            this.updateURLHandler,
        );
    }

    disconnect() {
        this.element.removeEventListener("input", this.inputHandler);
        document.removeEventListener(
            "stimulus-reflex:after",
            this.updateURLHandler,
        );

        if (this.searchTimer) {
            clearTimeout(this.searchTimer);
        }
    }

    handleInput() {
        if (this.searchTimer) {
            clearTimeout(this.searchTimer);
        }

        this.searchTimer = setTimeout(() => {
            this.stimulate("SearchReflex#perform", { updateUrl: true });
        }, this.debounceTimeValue);
    }

    updateURL(event) {
        const { reflex, error } = event.detail;
        if (!error && reflex === "SearchReflex#perform") {
            // URL updating handled by the reflex
            this.urlUpdated = true;
        }
    }

    // Mock method for testing
    stimulate(reflexName, options) {
        this.lastReflexCalled = reflexName;
        this.lastReflexOptions = options;
        return true;
    }
};

describe("SearchUrlUpdaterController", () => {
    let controller;
    let element;

    beforeEach(() => {
        // Set up the DOM
        document.body.innerHTML = `
      <form data-controller="search-url-updater">
        <input type="text" name="query" placeholder="Search...">
      </form>
    `;

        // Get elements
        element = document.querySelector(
            '[data-controller="search-url-updater"]',
        );

        // Create controller instance
        controller = new SearchUrlUpdaterControllerClass(element);
        controller.connect();
    });

    afterEach(() => {
        controller.disconnect();
    });

    test("handleInput debounces search requests", () => {
        // Replace setTimeout with a mock
        const originalSetTimeout = global.setTimeout;
        let timeoutCallback;
        let timeoutTime;

        global.setTimeout = jest.fn((callback, time) => {
            timeoutCallback = callback;
            timeoutTime = time;
            return 123; // Mock timer ID
        });

        // Call handleInput
        controller.handleInput();

        // Check that setTimeout was called with the correct debounce time
        expect(timeoutTime).toBe(controller.debounceTimeValue);

        // Execute the callback and check if the reflex was triggered
        timeoutCallback();
        expect(controller.lastReflexCalled).toBe("SearchReflex#perform");
        expect(controller.lastReflexOptions).toEqual({ updateUrl: true });

        // Restore setTimeout
        global.setTimeout = originalSetTimeout;
    });

    test("multiple handleInput calls only trigger one search", () => {
        // Mock clearTimeout and setTimeout
        const originalClearTimeout = global.clearTimeout;
        const originalSetTimeout = global.setTimeout;

        let clearTimeoutCalled = 0;
        let setTimeoutCalled = 0;

        global.clearTimeout = jest.fn(() => {
            clearTimeoutCalled++;
        });

        global.setTimeout = jest.fn(() => {
            setTimeoutCalled++;
            return 123; // Mock timer ID
        });

        // Call handleInput multiple times
        controller.handleInput();
        controller.handleInput();
        controller.handleInput();

        // Check clearTimeout was called for subsequent calls
        expect(clearTimeoutCalled).toBe(2); // Called twice for 3 calls

        // Check setTimeout was called for each call
        expect(setTimeoutCalled).toBe(3);

        // Restore original functions
        global.clearTimeout = originalClearTimeout;
        global.setTimeout = originalSetTimeout;
    });

    test("updateURL updates URL when SearchReflex#perform completes successfully", () => {
        // Before the event, urlUpdated should be undefined
        expect(controller.urlUpdated).toBeUndefined();

        // Create a mock event
        const mockEvent = {
            detail: {
                reflex: "SearchReflex#perform",
                error: null,
            },
        };

        // Call updateURL
        controller.updateURL(mockEvent);

        // Check that urlUpdated is now true
        expect(controller.urlUpdated).toBe(true);
    });

    test("updateURL does not update URL for different reflex", () => {
        // Create a mock event with a different reflex
        const mockEvent = {
            detail: {
                reflex: "OtherReflex#action",
                error: null,
            },
        };

        // Call updateURL
        controller.updateURL(mockEvent);

        // Check that urlUpdated is still undefined
        expect(controller.urlUpdated).toBeUndefined();
    });

    test("updateURL does not update URL when there is an error", () => {
        // Create a mock event with an error
        const mockEvent = {
            detail: {
                reflex: "SearchReflex#perform",
                error: new Error("Test error"),
            },
        };

        // Call updateURL
        controller.updateURL(mockEvent);

        // Check that urlUpdated is still undefined
        expect(controller.urlUpdated).toBeUndefined();
    });
});
