import { Application } from "@hotwired/stimulus";
import DismissibleController from "../../app/javascript/controllers/dismissible_controller";
import * as xmlrpc from "@foxglove/xmlrpc";

// Mock the createClient method
jest.mock("@foxglove/xmlrpc", () => ({
    createClient: jest.fn().mockImplementation(() => ({
        methodCall: jest.fn().mockImplementation((method, parameters) => {
            // Mock responses for different methods
            if (method === "preferences.isDismissed") {
                return Promise.resolve(true);
            } else if (method === "preferences.dismiss") {
                return Promise.resolve(true);
            }
            return Promise.reject(new Error("Unknown method"));
        }),
    })),
}));

describe("DismissibleController", () => {
    let controller;
    let element;

    beforeEach(() => {
        // Setup document with meta tag for CSRF token
        document.head.innerHTML = `<meta name="csrf-token" content="test-csrf-token">`;
        document.body.innerHTML = `
      <div data-controller="dismissible" data-dismissible-key-value="test-key">
        <button data-dismissible-target="button">Dismiss</button>
      </div>
    `;

        element = document.querySelector("[data-controller='dismissible']");

        const application = Application.start();
        application.register("dismissible", DismissibleController);

        controller = application.getControllerForElementAndIdentifier(
            element,
            "dismissible",
        );

        // Clear mock calls before each test
        jest.clearAllMocks();
    });

    describe("connect", () => {
        it("checks the dismissal status on connect", () => {
            // Mock implementation to verify this method gets called
            const spy = jest.spyOn(controller, "checkDismissalStatus");

            // Simulate connect
            controller.connect();

            expect(spy).toHaveBeenCalled();
        });
    });

    describe("checkDismissalStatus", () => {
        it("calls the XML-RPC client with the correct method and parameters", () => {
            controller.checkDismissalStatus();

            expect(xmlrpc.createClient).toHaveBeenCalledWith(
                expect.objectContaining({
                    url: "/api/xmlrpc",
                    headers: expect.objectContaining({
                        "X-Requested-With": "XMLHttpRequest",
                        "X-CSRF-Token": "test-csrf-token",
                    }),
                }),
            );

            const client = xmlrpc.createClient();
            expect(client.methodCall).toHaveBeenCalledWith(
                "preferences.isDismissed",
                ["test-key"],
            );
        });

        it("adds the dismissed class when the preference is dismissed", async () => {
            await controller.checkDismissalStatus();

            expect(element.classList.contains("dismissed")).toBe(true);
        });
    });

    describe("dismiss", () => {
        it("adds the dismissed class immediately", () => {
            controller.dismiss();

            expect(element.classList.contains("dismissed")).toBe(true);
        });

        it("calls the XML-RPC client with the correct method and parameters", () => {
            controller.dismiss();

            expect(xmlrpc.createClient).toHaveBeenCalledWith(
                expect.objectContaining({
                    url: "/api/xmlrpc",
                    headers: expect.objectContaining({
                        "X-CSRF-Token": "test-csrf-token",
                    }),
                }),
            );

            const client = xmlrpc.createClient();
            expect(client.methodCall).toHaveBeenCalledWith(
                "preferences.dismiss",
                ["test-key"],
            );
        });
    });
});
