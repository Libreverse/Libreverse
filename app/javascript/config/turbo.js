// Add submitting class to forms when they're being submitted
document.addEventListener("turbo:submit-start", ({ target }) => {
    target.classList.add("turbo-submitting");
});

document.addEventListener("turbo:submit-end", ({ target }) => {
    target.classList.remove("turbo-submitting");
});

// Add loading class to body during navigation
document.addEventListener("turbo:before-fetch-request", () => {
    document.body.classList.add("turbo-loading");
});

document.addEventListener("turbo:before-fetch-response", () => {
    document.body.classList.remove("turbo-loading");
});

// Handle form submission errors
document.addEventListener("turbo:submit-end", (event) => {
    const form = event.target;

    // Check if form submission had errors (look for flash error messages in the response)
    const flashMessages = document.querySelectorAll(".toast-error");
    if (flashMessages.length > 0) {
        // Focus the first input with an error for better accessibility
        const firstInvalidInput = form.querySelector(".is-invalid");
        if (firstInvalidInput) {
            firstInvalidInput.focus();
        }
    }
});
