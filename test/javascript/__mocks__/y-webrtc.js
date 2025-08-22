class MockWebrtcProvider {
    constructor(room, ydoc, options = {}) {
        this.room = room;
        this.ydoc = ydoc;
        this.options = options;
        this.destroyed = false;
    }
    destroy() {
        this.destroyed = true;
    }
}

export { MockWebrtcProvider as WebrtcProvider };
export default MockWebrtcProvider;
