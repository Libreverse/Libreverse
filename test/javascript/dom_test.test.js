describe("DOM manipulation", () => {
    test("can manipulate the DOM", () => {
        // Create an element
        const div = document.createElement("div");
        div.textContent = "Hello World";
        div.className = "test-div";

        // Append to the document
        document.body.append(div);

        // Query for the element
        const foundDiv = document.querySelector(".test-div");

        // Assert that it exists and has the right content
        expect(foundDiv).not.toBeNull();
        expect(foundDiv.textContent).toBe("Hello World");
    });
});
