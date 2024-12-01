import { Controller } from "@hotwired/stimulus";
import Lenis from "lenis";

export default class extends Controller {
  connect() {
    this.lenis = null;
    this.setupEventListeners();
    this.init();
  }

  disconnect() {
    this.destroy();
    this.removeEventListeners();
  }

  init() {
    try {
      if (!this.lenis) {
        this.lenis = new Lenis({
          duration: 1.2,
          easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
          direction: "vertical",
          gestureDirection: "vertical",
          smooth: true,
          mouseMultiplier: 1,
          smoothTouch: true,
          touchMultiplier: 2,
          infinite: false,
          autoRaf: true,
        });
      }
    } catch (error) {
      console.error("Failed to initialize Lenis:", error);
    }
  }

  destroy() {
    if (this.lenis) {
      this.lenis.destroy();
      this.lenis = null;
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
    if (!this.lenis) {
      this.init();
    } else {
      this.resume();
    }
  };

  handleTurboRender = () => {
    if (!this.lenis) {
      this.init();
    }
  };

  setupEventListeners() {
    document.addEventListener("turbo:load", this.handleTurboLoad);
    document.addEventListener(
      "turbo:before-cache",
      this.destroyIfNeeded.bind(this),
    );
    document.addEventListener(
      "turbo:before-render",
      this.destroyIfNeeded.bind(this),
    );
    document.addEventListener("turbo:render", this.handleTurboRender);
    window.addEventListener("beforeunload", this.destroy.bind(this));
  }

  removeEventListeners() {
    document.removeEventListener("turbo:load", this.handleTurboLoad);
    document.removeEventListener(
      "turbo:before-cache",
      this.destroyIfNeeded.bind(this),
    );
    document.removeEventListener(
      "turbo:before-render",
      this.destroyIfNeeded.bind(this),
    );
    document.removeEventListener("turbo:render", this.handleTurboRender);
    window.removeEventListener("beforeunload", this.destroy.bind(this));
  }
}
