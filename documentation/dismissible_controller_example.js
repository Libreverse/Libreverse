/**
 * Example demonstrating how to use the dismissible controller with XML-RPC
 *
 * This file is for documentation purposes only and is not part of the application.
 */
import { XmlRpcClient } from "@foxglove/xmlrpc";

// Example usage in HTML:
//
// <div data-controller="dismissible" data-dismissible-key-value="dashboard-tutorial">
//   <div class="tutorial-content">
//     <h2>Welcome to the Dashboard</h2>
//     <p>This tutorial will help you get started with Libreverse.</p>
//   </div>
//   <button data-action="click->dismissible#dismiss">
//     Don't show again
//   </button>
// </div>

// XML-RPC client implementation example using @foxglove/xmlrpc
function checkDismissalStatusExample() {
    // Get CSRF token from meta tag
    const csrfToken = document.querySelector(
        'meta[name="csrf-token"]',
    )?.content;

    // Create the XML-RPC client
    const client = new XmlRpcClient("/api/xmlrpc", {
        headers: {
            "Content-Type": "text/xml",
            "X-Requested-With": "XMLHttpRequest",
            "X-CSRF-Token": csrfToken,
        },
    });

    // Call the XML-RPC method
    client
        .methodCall("preferences.isDismissed", ["dashboard-tutorial"])
        .then((dismissed) => {
            console.log("Is dismissed:", dismissed);

            // Update UI based on the dismissed status
            if (dismissed) {
                document
                    .querySelector(".dashboard-tutorial")
                    ?.classList.add("dismissed");
            }
        })
        .catch((error) => {
            console.error("Error checking dismissal status:", error);
        });
}

// Example of dismissing an item using @foxglove/xmlrpc
function dismissExample() {
    // Get CSRF token from meta tag
    const csrfToken = document.querySelector(
        'meta[name="csrf-token"]',
    )?.content;

    // Create the XML-RPC client
    const client = new XmlRpcClient("/api/xmlrpc", {
        headers: {
            "Content-Type": "text/xml",
            "X-CSRF-Token": csrfToken,
        },
    });

    // Update UI immediately (optimistic update)
    document.querySelector(".dashboard-tutorial")?.classList.add("dismissed");

    // Call the XML-RPC method
    client
        .methodCall("preferences.dismiss", ["dashboard-tutorial"])
        .then((result) => {
            console.log("Dismissal successful");
        })
        .catch((error) => {
            console.error("Error during dismiss:", error);
            // Could revert UI change here if needed
        });
}

// Example of handling XML-RPC faults
function handleXmlRpcFaults() {
    const client = new XmlRpcClient("/api/xmlrpc");

    client
        .methodCall("preferences.isDismissed", ["invalid-key"])
        .then((result) => {
            console.log("Result:", result);
        })
        .catch((error) => {
            // XML-RPC faults are caught as regular errors
            // The @foxglove/xmlrpc package takes care of parsing fault responses
            console.error("XML-RPC fault:", error.message);

            // For a fault, error will have properties like:
            // - faultCode: number
            // - faultString: string
            if (error.faultCode) {
                console.error(
                    `Fault code: ${error.faultCode}, Fault string: ${error.faultString}`,
                );
            }
        });
}
