// Foundation for Sites JavaScript Integration
// This file provides utilities for Foundation components managed by Stimulus controllers

import { Foundation } from "foundation-sites";
import $ from "jquery";

// Make jQuery available for Foundation components only when needed
// Don't pollute global scope - Stimulus controllers will handle jQuery setup
let foundationJQueryInitialized = false;

function ensureJQueryForFoundation() {
    if (!foundationJQueryInitialized) {
        Foundation.addToJquery($);
        foundationJQueryInitialized = true;
    }
    return $;
}

// Foundation utilities
export const FoundationUtils = {
    // Ensure jQuery is set up for Foundation before using any component
    initializeFoundation() {
        return ensureJQueryForFoundation();
    },

    // Initialize specific Foundation components
    initComponent: function (component, selector) {
        const $ = ensureJQueryForFoundation();
        const elements = selector ? $(selector) : $("[data-" + component + "]");
        elements.each(function () {
            new Foundation[component]($(this));
        });
    },

    // Destroy and reinitialize a component
    reinitComponent: function (component, selector) {
        const $ = ensureJQueryForFoundation();
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
        const $ = ensureJQueryForFoundation();
        $(selector).foundation("toggle");
    },

    // Open reveal modal
    openReveal: function (selector) {
        const $ = ensureJQueryForFoundation();
        $(selector).foundation("open");
    },

    // Close reveal modal
    closeReveal: function (selector) {
        const $ = ensureJQueryForFoundation();
        $(selector).foundation("close");
    },

    // Toggle off-canvas
    toggleOffCanvas: function (selector) {
        const $ = ensureJQueryForFoundation();
        $(selector).foundation("toggle");
    },

    // Open off-canvas
    openOffCanvas: function (selector) {
        const $ = ensureJQueryForFoundation();
        $(selector).foundation("open");
    },

    // Close off-canvas
    closeOffCanvas: function (selector) {
        const $ = ensureJQueryForFoundation();
        $(selector).foundation("close");
    },

    // Show/hide dropdown
    toggleDropdown: function (selector) {
        const $ = ensureJQueryForFoundation();
        $(selector).foundation("toggle");
    },

    // Programmatically trigger tooltips
    showTooltip: function (selector) {
        const $ = ensureJQueryForFoundation();
        $(selector).foundation("show");
    },

    // Hide tooltip
    hideTooltip: function (selector) {
        const $ = ensureJQueryForFoundation();
        $(selector).foundation("hide");
    },

    // Orbit slider controls
    orbitNext: function (selector) {
        const $ = ensureJQueryForFoundation();
        $(selector).foundation("next");
    },

    orbitPrev: function (selector) {
        const $ = ensureJQueryForFoundation();
        $(selector).foundation("previous");
    },

    // Tabs
    selectTab: function (selector, targetTab) {
        const $ = ensureJQueryForFoundation();
        $(selector).foundation("selectTab", targetTab);
    },

    // Accordion
    toggleAccordion: function (selector) {
        const $ = ensureJQueryForFoundation();
        $(selector).foundation("toggle");
    },

    // Sticky elements
    updateSticky: function (selector) {
        const $ = ensureJQueryForFoundation();
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
        const $ = ensureJQueryForFoundation();
        return $(selector).data("zfPlugin");
    },
};

// Export for module usage
export default FoundationUtils;
