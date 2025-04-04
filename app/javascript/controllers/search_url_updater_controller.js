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
            this.stimulate("SearchReflex#perform", { updateUrl: true });
        }, this.debounceTimeValue);
    }

    // Update URL after search completes successfully
    updateURL(event) {
        const { reflex, error } = event.detail;
        if (!error && reflex === "SearchReflex#perform") {
            // URL updating is now handled by the reflex
        }
    }
}
