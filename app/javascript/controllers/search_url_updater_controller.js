import ApplicationController from "./application_controller";

// Connects to data-controller="search-url-updater"
export default class extends ApplicationController {
    static values = {
        debounceTime: { type: Number, default: 300 },
    };

    connect() {
        super.connect();
        this.inputHandler = this.handleInput.bind(this);
        this.searchTimer = null;

        // Set up input event listener with debounce
        this.element.addEventListener("input", this.inputHandler);

        // Listen for successful SearchReflex completion
        this.updateURLHandler = this.updateURLAfterSearch.bind(this);
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

    // Debounced input handler: Triggers SearchReflex
    handleInput() {
        if (this.searchTimer) {
            clearTimeout(this.searchTimer);
        }

        this.searchTimer = setTimeout(() => {
            this.stimulate("SearchReflex#perform");
        }, this.debounceTimeValue);
    }

    // Updates the URL after SearchReflex completes successfully
    updateURLAfterSearch(event) {
        const { reflex, error } = event.detail;

        // Only proceed if SearchReflex succeeded
        if (!error && reflex === "SearchReflex#perform") {
            const query = this.element.value.trim(); // Get current input value
            const currentUrl = new URL(window.location.href);
            const params = currentUrl.searchParams;

            if (query) {
                params.set("query", query);
            } else {
                params.delete("query");
            }

            // Update the URL without reloading the page and without adding a new history entry
            const newUrl = currentUrl.pathname + "?" + params.toString();
            // Only replace state if the URL actually changed
            if (window.location.search !== params.toString()) {
                window.history.replaceState({ path: newUrl }, "", newUrl);
            }
        }
    }
}
