import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="search-url-updater"
export default class extends Controller {
    static values = {
        debounceTime: { type: Number, default: 300 },
    };

    connect() {
        this.inputHandler = this.handleInput.bind(this);
        this.searchTimer = null;

        // Set up input event handler with debounce
        this.element.addEventListener("input", this.inputHandler);

        // Set up after-reflex handler
        this.updateURLHandler = this.updateURL.bind(this);
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

    // Debounced input handler
    handleInput(event) {
        if (this.searchTimer) {
            clearTimeout(this.searchTimer);
        }

        // Use debounce to prevent excessive reflexes
        this.searchTimer = setTimeout(() => {
            // Trigger the reflex programmatically
            this.stimulate("SearchReflex#perform");
        }, this.debounceTimeValue);
    }

    // Update URL after search completes successfully
    updateURL(event) {
        const { reflex, error } = event.detail;
        if (!error && reflex === "SearchReflex#perform") {
            const query = this.element.value.trim();
            const url = new URL(window.location);

            if (query === "") {
                url.searchParams.delete("query");
            } else {
                url.searchParams.set("query", query);
            }

            // Use replaceState to avoid adding a new history entry
            history.replaceState({}, "", url);
        }
    }
}
