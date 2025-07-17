// Foundation for Sites JavaScript Integration
// This file initializes Foundation components and provides utilities

import { Foundation } from "foundation-sites";
import $ from "jquery";

// Make jQuery available globally for Foundation
globalThis.$ = $;
globalThis.jQuery = $;

// Initialize Foundation
document.addEventListener("DOMContentLoaded", function () {
    Foundation.addToJquery($);
    $(document).foundation();

    // Explicitly initialize off-canvas if it exists
    const offCanvas = $("#sidebarOffCanvas");
    if (offCanvas.length > 0) {
        console.log("Initializing off-canvas:", offCanvas);
        new Foundation.OffCanvas(offCanvas);
    }
});

// Re-initialize Foundation on Turbo navigation
document.addEventListener("turbo:load", function () {
    $(document).foundation();

    // Explicitly initialize off-canvas if it exists
    const offCanvas = $("#sidebarOffCanvas");
    if (offCanvas.length > 0) {
        console.log("Re-initializing off-canvas:", offCanvas);
        new Foundation.OffCanvas(offCanvas);
    }
});

// Foundation utilities
export const FoundationUtils = {
    // Initialize specific Foundation components
    initComponent: function (component, selector) {
        const elements = selector ? $(selector) : $("[data-" + component + "]");
        elements.each(function () {
            new Foundation[component]($(this));
        });
    },

    // Destroy and reinitialize a component
    reinitComponent: function (component, selector) {
        const elements = selector ? $(selector) : $("[data-" + component + "]");
        elements.each(function () {
            const $element = $(this);
            const instance = $element.data("zfPlugin");
            if (instance) {
                instance.destroy();
            }
            new Foundation[component]($element);
        });
    },

    // Show/hide reveal modal
    toggleReveal: function (selector) {
        $(selector).foundation("toggle");
    },

    // Open reveal modal
    openReveal: function (selector) {
        $(selector).foundation("open");
    },

    // Close reveal modal
    closeReveal: function (selector) {
        $(selector).foundation("close");
    },

    // Toggle off-canvas
    toggleOffCanvas: function (selector) {
        $(selector).foundation("toggle");
    },

    // Open off-canvas
    openOffCanvas: function (selector) {
        $(selector).foundation("open");
    },

    // Close off-canvas
    closeOffCanvas: function (selector) {
        $(selector).foundation("close");
    },

    // Show/hide dropdown
    toggleDropdown: function (selector) {
        $(selector).foundation("toggle");
    },

    // Programmatically trigger tooltips
    showTooltip: function (selector) {
        $(selector).foundation("show");
    },

    // Hide tooltip
    hideTooltip: function (selector) {
        $(selector).foundation("hide");
    },

    // Orbit slider controls
    orbitNext: function (selector) {
        $(selector).foundation("next");
    },

    orbitPrev: function (selector) {
        $(selector).foundation("previous");
    },

    // Tabs
    selectTab: function (selector, targetTab) {
        $(selector).foundation("selectTab", targetTab);
    },

    // Accordion
    toggleAccordion: function (selector) {
        $(selector).foundation("toggle");
    },

    // Sticky elements
    updateSticky: function (selector) {
        const elements = selector ? $(selector) : $("[data-sticky]");
        elements.each(function () {
            const instance = $(this).data("zfPlugin");
            if (instance && instance._calc) {
                instance._calc(false);
            }
        });
    },

    // Utility to get Foundation plugin instance
    getPlugin: function (selector) {
        return $(selector).data("zfPlugin");
    },
};

// Make Foundation utilities available globally
globalThis.FoundationUtils = FoundationUtils;

// Export for module usage
export default FoundationUtils;
