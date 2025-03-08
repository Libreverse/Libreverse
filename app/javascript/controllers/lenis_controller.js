import { Controller } from "@hotwired/stimulus";
import Lenis from "lenis";

export default class extends Controller {
  connect() {
    this.lenis = undefined;
    // Bind the event handlers once to preserve references
    this.boundDestroyIfNeeded = this.destroyIfNeeded.bind(this);
    this.boundDestroy = this.destroy.bind(this);
    this.setupEventListeners();
    this.init();
  }

  disconnect() {
    this.destroy();
    this.removeEventListeners();
  }

  init() {
    try {
      this.lenis ||= new Lenis({
        duration: 1.2,
        easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
        touchMultiplier: 2,
        infinite: false,
        autoRaf: true,
      });
    } catch (error) {
      console.error("Failed to initialize Lenis:", error);
    }
  }

  destroy() {
    if (this.lenis) {
      this.lenis.destroy();
      this.lenis = undefined;
    }
  }

  resume() {
    if (this.lenis) {
      this.lenis.start();
    }
  }

  destroyIfNeeded(event) {
    if (
      this.lenis &&
      (!event || event.target.controller !== "Turbo.FrameController")
    ) {
      this.destroy();
    }
  }

  handleTurboLoad = () => {
    if (this.lenis) {
      this.resume();
    } else {
      this.init();
    }
  };
  handleTurboRender = () => {
    if (!this.lenis) {
      this.init();
    }
  };

  setupEventListeners() {
    document.addEventListener("turbo:load", this.handleTurboLoad);
    document.addEventListener("turbo:before-cache", this.boundDestroyIfNeeded);
    document.addEventListener("turbo:before-render", this.boundDestroyIfNeeded);
    document.addEventListener("turbo:render", this.handleTurboRender);
    window.addEventListener("beforeunload", this.boundDestroy);
  }

  removeEventListeners() {
    document.removeEventListener("turbo:load", this.handleTurboLoad);
    document.removeEventListener(
      "turbo:before-cache",
      this.boundDestroyIfNeeded,
    );
    document.removeEventListener(
      "turbo:before-render",
      this.boundDestroyIfNeeded,
    );
    document.removeEventListener("turbo:render", this.handleTurboRender);
    window.removeEventListener("beforeunload", this.boundDestroy);
  }
}
