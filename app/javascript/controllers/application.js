import { Application } from "@hotwired/stimulus";

const app = Application.start();

// Configure Stimulus development experience
app.debug = false;
globalThis.Stimulus = app;

export { app as application };
