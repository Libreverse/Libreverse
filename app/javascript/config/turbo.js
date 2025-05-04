// Add submitting class to forms when they're being submitted
document.addEventListener("turbo:submit-start", ({ target }) => {
    target.classList.add("turbo-submitting");
});
document.addEventListener("turbo:submit-end", ({ target }) => {
    target.classList.remove("turbo-submitting");
});

// Add loading class to body only during page-changing navigation
document.addEventListener("turbo:visit", () => {
    document.body.classList.add("turbo-loading");
});
document.addEventListener("turbo:load", () => {
    document.body.classList.remove("turbo-loading");
});
