import { Controller } from "@hotwired/stimulus";
import { FoundationUtils } from "../libs/foundation.js";
import { Foundation } from "foundation-sites";
import $ from "jquery";

// Foundation Stimulus Controller
// Connects Foundation components to Stimulus
export default class extends Controller {
    static targets = [
        "reveal",
        "offCanvas",
        "dropdown",
        "tooltip",
        "orbit",
        "tabs",
        "accordion",
        "sticky",
    ];
    static values = {
        component: String,
        options: Object,
    };

    connect() {
        // Initialize the specific Foundation component
        if (this.hasComponentValue) {
            this.initializeComponent();
        }
    }

    disconnect() {
        // Clean up Foundation component
        if (this.foundationInstance) {
            this.foundationInstance.destroy();
        }
    }

    initializeComponent() {
        const componentName = this.componentValue;
        const options = this.hasOptionsValue ? this.optionsValue : {};

        // Initialize the Foundation component
        const FoundationComponent = Foundation[componentName];
        if (FoundationComponent) {
            this.foundationInstance = new FoundationComponent(
                $(this.element),
                options,
            );
        }
    }

    // Reveal modal actions
    openReveal() {
        if (this.hasRevealTarget) {
            FoundationUtils.openReveal(this.revealTarget);
        }
    }

    closeReveal() {
        if (this.hasRevealTarget) {
            FoundationUtils.closeReveal(this.revealTarget);
        }
    }

    toggleReveal() {
        if (this.hasRevealTarget) {
            FoundationUtils.toggleReveal(this.revealTarget);
        }
    }

    // Off-canvas actions
    openOffCanvas() {
        if (this.hasOffCanvasTarget) {
            FoundationUtils.openOffCanvas(this.offCanvasTarget);
        }
    }

    closeOffCanvas() {
        if (this.hasOffCanvasTarget) {
            FoundationUtils.closeOffCanvas(this.offCanvasTarget);
        }
    }

    toggleOffCanvas() {
        if (this.hasOffCanvasTarget) {
            FoundationUtils.toggleOffCanvas(this.offCanvasTarget);
        }
    }

    // Dropdown actions
    toggleDropdown() {
        if (this.hasDropdownTarget) {
            FoundationUtils.toggleDropdown(this.dropdownTarget);
        }
    }

    // Tooltip actions
    showTooltip() {
        if (this.hasTooltipTarget) {
            FoundationUtils.showTooltip(this.tooltipTarget);
        }
    }

    hideTooltip() {
        if (this.hasTooltipTarget) {
            FoundationUtils.hideTooltip(this.tooltipTarget);
        }
    }

    // Orbit slider actions
    orbitNext() {
        if (this.hasOrbitTarget) {
            FoundationUtils.orbitNext(this.orbitTarget);
        }
    }

    orbitPrev() {
        if (this.hasOrbitTarget) {
            FoundationUtils.orbitPrev(this.orbitTarget);
        }
    }

    // Tabs actions
    selectTab(event) {
        if (this.hasTabsTarget) {
            const targetTab = event.target.dataset.tab;
            FoundationUtils.selectTab(this.tabsTarget, targetTab);
        }
    }

    // Accordion actions
    toggleAccordion() {
        if (this.hasAccordionTarget) {
            FoundationUtils.toggleAccordion(this.accordionTarget);
        }
    }

    // Sticky actions
    updateSticky() {
        if (this.hasStickyTarget) {
            FoundationUtils.updateSticky(this.stickyTarget);
        }
    }

    // Generic action handler
    handleAction(event) {
        const action = event.target.dataset.action;
        const target = event.target.dataset.target;

        if (action && target) {
            const targetElement = this.element.querySelector(target);
            if (targetElement) {
                FoundationUtils[action](targetElement);
            }
        }
    }
}
