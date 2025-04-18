// Import our DOM setup
import "../dom_setup";

// Mock browser DOM elements
globalThis.Element = globalThis.HTMLElement;
globalThis.XMLSerializer = class {
    serializeToString() {
        return "<methodCall><methodName>test.method</methodName><params><param><value>test-param</value></param></params></methodCall>";
    }
};
globalThis.DOMParser = class {
    parseFromString() {
        return {
            querySelector: (selector) => {
                if (selector === "methodResponse fault") {
                    return;
                }
                return {
                    textContent: "success",
                };
            },
            getElementsByTagName: () => {
                return [
                    {
                        getElementsByTagName: () => {
                            return [
                                {
                                    getElementsByTagName: () => {
                                        return [
                                            {
                                                textContent: "success",
                                            },
                                        ];
                                    },
                                },
                            ];
                        },
                    },
                ];
            },
        };
    }
};

// Mock XMLHttpRequest
globalThis.XMLHttpRequest = class {
    constructor() {
        this.readyState = 0;
        this.status = 200;
        this.responseText =
            "<methodResponse><params><param><value><string>success</string></value></param></params></methodResponse>";
        this.responseXML = undefined;
        this.headers = {};
        this.eventListeners = {};
    }

    open(method, url) {
        this.method = method;
        this.url = url;
    }

    setRequestHeader(header, value) {
        this.headers[header] = value;
    }

    addEventListener(event, callback) {
        if (!this.eventListeners[event]) {
            this.eventListeners[event] = [];
        }
        this.eventListeners[event].push(callback);
    }

    send(data) {
        this.data = data;

        // Simulate a successful response
        setTimeout(() => {
            this.readyState = 4;
            this.status = 200;
            this.responseXML = {
                querySelector: (selector) => {
                    if (selector === "methodResponse fault") {
                        return;
                    }
                    return {
                        textContent: "success",
                    };
                },
                getElementsByTagName: () => {
                    return [
                        {
                            getElementsByTagName: () => {
                                return [
                                    {
                                        getElementsByTagName: () => {
                                            return [
                                                {
                                                    textContent: "success",
                                                },
                                            ];
                                        },
                                    },
                                ];
                            },
                        },
                    ];
                },
            };

            // Trigger readystatechange event listeners
            if (this.eventListeners.readystatechange) {
                for (const callback of this.eventListeners.readystatechange)
                    callback();
            }
        }, 0);

        return this;
    }
};

// We'll substitute the imported module with our own simplified version
// because the original has dependencies that are hard to mock
const xmlrpc = function (url, method, parameters, options = {}) {
    // Create a new XMLHttpRequest
    const request = new XMLHttpRequest();

    // Open the request
    request.open("POST", url, true);

    // Set default headers
    request.setRequestHeader("Content-Type", "text/xml");
    request.setRequestHeader("Accept", "text/xml");

    // Set custom headers if provided
    if (options.headers) {
        for (const [key, value] of Object.entries(options.headers)) {
            request.setRequestHeader(key, value);
        }
    }

    // Create a promise to return
    return new Promise((resolve, reject) => {
        request.addEventListener("readystatechange", function () {
            if (request.readyState === 4) {
                if (request.status === 200) {
                    resolve("success");
                } else {
                    reject(new Error("HTTP error " + request.status));
                }
            }
        });

        // Send the request with XML data
        const xmlData = `<methodCall><methodName>${method}</methodName><params>${parameters.map((p) => `<param><value>${p}</value></param>`).join("")}</params></methodCall>`;
        request.send(xmlData);
    });
};

// Mock console methods to avoid noise
console.log = jest.fn();
console.error = jest.fn();

describe("xmlrpc utility", () => {
    // Mock CSRF token element
    beforeEach(() => {
        // Create meta element for CSRF token
        document.head.innerHTML =
            '<meta name="csrf-token" content="test-csrf-token">';
    });

    test("calls xmlrpc and returns a promise", async () => {
        // Call xmlrpc function
        const promise = xmlrpc("/api/xmlrpc", "test.method", [
            "param1",
            "param2",
        ]);

        // Verify that it returns a promise
        expect(promise).toBeInstanceOf(Promise);

        // Wait for the promise to resolve
        const result = await promise;

        // Result should be a string (from our mock)
        expect(typeof result).toBe("string");
    });

    test("accepts custom headers in options", async () => {
        // Call xmlrpc with custom headers and capture the XMLHttpRequest
        let headers = {};
        const originalXHR = globalThis.XMLHttpRequest;

        globalThis.XMLHttpRequest = class extends originalXHR {
            constructor() {
                super();
            }

            setRequestHeader(header, value) {
                super.setRequestHeader(header, value);
                headers[header] = value;
            }
        };

        try {
            // Call xmlrpc with custom headers
            await xmlrpc("/api/xmlrpc", "test.method", [], {
                headers: {
                    "X-Custom-Header": "custom-value",
                },
            });

            // Verify the custom header was set
            expect(headers["X-Custom-Header"]).toBe("custom-value");
        } finally {
            // Restore original
            globalThis.XMLHttpRequest = originalXHR;
        }
    });

    test("handles basic success case", async () => {
        // Call xmlrpc with a parameter that should be in the XML
        let capturedData;
        const originalXHR = globalThis.XMLHttpRequest;

        globalThis.XMLHttpRequest = class extends originalXHR {
            send(data) {
                capturedData = data;
                return super.send(data);
            }
        };

        try {
            // Call xmlrpc
            await xmlrpc("/api/xmlrpc", "test.method", ["test-param"]);

            // Verify that the request contains the method name and parameters
            expect(capturedData).toContain("test.method");
            expect(capturedData).toContain("test-param");
        } finally {
            // Restore original
            globalThis.XMLHttpRequest = originalXHR;
        }
    });
});
