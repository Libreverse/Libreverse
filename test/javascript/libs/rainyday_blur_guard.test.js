import "~/libs/rainyday.js";

describe("RainyDay stackBlurCanvasRGB guards", () => {
    test("does not throw when height is 0", () => {
        const rd = Object.create(globalThis.RainyDay.prototype);
        expect(() => rd.stackBlurCanvasRGB(10, 0, 5)).not.toThrow();
    });

    test("does not throw when width is 0", () => {
        const rd = Object.create(globalThis.RainyDay.prototype);
        expect(() => rd.stackBlurCanvasRGB(0, 10, 5)).not.toThrow();
    });

    test("does not throw when radius is < 1", () => {
        const rd = Object.create(globalThis.RainyDay.prototype);
        expect(() => rd.stackBlurCanvasRGB(10, 10, 0)).not.toThrow();
    });
});
