// We'll import the library after setting up window mocks

// Mock yrb-actioncable provider to avoid network dependencies
jest.mock("@y-rb/actioncable", () => ({
    WebsocketProvider: class MockProvider {
        constructor() {
            this.synced = false;
        }
        on() {}
        destroy() {}
    },
}));

// Minimal ActionCable mock
globalThis.ActionCable = {
    createConsumer: () => ({
        subscriptions: {
            create: () => ({}),
        },
    }),
};

let postMessageSpy;

beforeAll(async () => {
    // Ensure parent reference is the same window object
    globalThis.parent = globalThis;
    // Spy on parent.postMessage before the lib runs
    postMessageSpy = jest
        .spyOn(globalThis.parent, "postMessage")
        .mockImplementation(() => {});
    // Now import the library which will create the global P2P and post iframe-ready
    await import("../../app/javascript/libs/websocket_p2p_client.js");
});

describe("Injected P2P + Yjs API", () => {
    beforeEach(() => {
        // Clear postMessage calls between tests
        postMessageSpy.mockClear();
    });

    it("exposes global P2P object", () => {
        expect(globalThis.P2P).toBeDefined();
        expect(typeof globalThis.P2P.send).toBe("function");
        expect(typeof globalThis.P2P.attachCollab).toBe("function");
        expect(typeof globalThis.P2P.getDoc).toBe("function");
    });

    it("fires iframe-ready message", () => {
        expect(globalThis.LibreverseWebSocketP2P).toBeDefined();
        const spy = jest.spyOn(
            globalThis.LibreverseWebSocketP2P.prototype,
            "sendToParent",
        );
        // Creating a new instance triggers the constructor which should emit iframe-ready
        new globalThis.LibreverseWebSocketP2P();
        expect(spy).toHaveBeenCalledWith("iframe-ready", {});
        spy.mockRestore();
    });

    it("attaches default collab doc after init", () => {
        const handler = jest.fn();
        const unsub = globalThis.P2P.onCollabReady(handler);

        // simulate parent p2p-init
        globalThis.P2P.handleParentMessage({
            type: "p2p-init",
            peerId: "peer-1",
            sessionId: "sess-123",
            isHost: true,
            connected: true,
        });

        // provider will not actually connect in this mock; ensure no throw and default id set
        expect(globalThis.P2P.defaultDocId).toBe("session:sess-123");
        unsub();
    });
});
