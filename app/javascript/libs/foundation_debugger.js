// Foundation Debug Helper
// This module provides debugging utilities for Foundation issues

import { Foundation } from "foundation-sites";

export const FoundationDebugger = {
    // Check if Foundation is properly loaded and initialized
    checkFoundationStatus() {
        const results = {
            foundationImported: false,
            jQueryAvailable: false,
            foundationOnJQuery: false,
            components: {},
            issues: [],
        };

        // Check if Foundation is imported
        try {
            results.foundationImported = !!Foundation;
        } catch {
            results.issues.push("Foundation Sites not properly imported");
        }

        // Check if jQuery is available
        if (globalThis.$ === undefined) {
            results.issues.push("jQuery not available globally");
        } else {
            results.jQueryAvailable = true;

            // Check if Foundation is attached to jQuery
            if (globalThis.$.fn.foundation === undefined) {
                results.issues.push("Foundation not attached to jQuery");
            } else {
                results.foundationOnJQuery = true;
            }
        }

        // Check specific Foundation components
        const componentsToCheck = [
            "OffCanvas",
            "Reveal",
            "Dropdown",
            "Tooltip",
        ];
        for (const component of componentsToCheck) {
            try {
                results.components[component] = !!Foundation[component];
            } catch {
                results.components[component] = false;
                results.issues.push(`${component} component not available`);
            }
        }

        return results;
    },

    // Check if off-canvas elements are properly set up
    checkOffCanvasElements() {
        const offCanvasElements =
            document.querySelectorAll("[data-off-canvas]");
        const results = {
            elementsFound: offCanvasElements.length,
            elements: [],
            issues: [],
        };

        for (const [index, element] of offCanvasElements.entries()) {
            const elementInfo = {
                id: element.id || `element-${index}`,
                classes: [...element.classList],
                hasController: Object.hasOwn(element.dataset, "controller"),
                hasFoundationInstance: false,
            };

            // Check if Foundation instance exists
            if (globalThis.$ !== undefined) {
                const $element = globalThis.$(element);
                const instance = $element.data("zfPlugin");
                elementInfo.hasFoundationInstance = !!instance;

                if (!instance) {
                    results.issues.push(
                        `Off-canvas element ${elementInfo.id} has no Foundation instance`,
                    );
                }
            }

            results.elements.push(elementInfo);
        }

        return results;
    },

    // Generate a complete diagnostic report
    generateReport() {
        const report = {
            timestamp: new Date().toISOString(),
            foundationStatus: this.checkFoundationStatus(),
            offCanvasStatus: this.checkOffCanvasElements(),
            stimulusControllers: this.checkStimulusControllers(),
        };

        return report;
    },

    // Check Stimulus controllers
    checkStimulusControllers() {
        const results = {
            stimulusAvailable: false,
            registeredControllers: [],
            issues: [],
        };

        if (globalThis.Stimulus === undefined) {
            results.issues.push("Stimulus not available globally");
        } else {
            results.stimulusAvailable = true;

            // Get registered controller names (this might not work in all Stimulus versions)
            try {
                const application = globalThis.Stimulus;
                if (
                    application.router &&
                    application.router.modulesByIdentifier
                ) {
                    results.registeredControllers = [
                        ...application.router.modulesByIdentifier.keys(),
                    ];
                }
            } catch {
                results.issues.push(
                    "Could not retrieve Stimulus controller list",
                );
            }
        }

        return results;
    },

    // Log the diagnostic report to console
    logReport() {
        const report = this.generateReport();
        console.group("Foundation Diagnostic Report");
        console.log("Report generated at:", report.timestamp);

        console.group("Foundation Status");
        console.log(report.foundationStatus);
        console.groupEnd();

        console.group("Off-Canvas Status");
        console.log(report.offCanvasStatus);
        console.groupEnd();

        console.group("Stimulus Status");
        console.log(report.stimulusControllers);
        console.groupEnd();

        if (
            report.foundationStatus.issues.length > 0 ||
            report.offCanvasStatus.issues.length > 0 ||
            report.stimulusControllers.issues.length > 0
        ) {
            console.group("Issues Found");
            for (const issue of [
                ...report.foundationStatus.issues,
                ...report.offCanvasStatus.issues,
                ...report.stimulusControllers.issues,
            ])
                console.warn(issue);
            console.groupEnd();
        }

        console.groupEnd();

        return report;
    },
};

// Make available globally for debugging
globalThis.FoundationDebugger = FoundationDebugger;

export default FoundationDebugger;
