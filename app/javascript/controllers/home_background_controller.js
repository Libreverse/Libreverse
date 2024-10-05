import { Controller } from "@hotwired/stimulus";
import RaindropFX from "raindrop-fx";

// Connects to data-controller="home-background"
export default class extends Controller {
  connect() {
    const canvas = document.querySelector("#canvas");
    const rect = canvas.getBoundingClientRect();
    canvas.width = rect.width;
    canvas.height = rect.height;

    const backgroundImagePath = canvas.getAttribute("data-background-image");

    const raindropFx = new RaindropFX({
      canvas: canvas,
      background: backgroundImagePath,
      backgroundBlurSteps: 1,
      mistBlurStep: 3,
    });

    window.onresize = () => {
      const rect = canvas.getBoundingClientRect();
      raindropFx.resize(rect.width, rect.height);
    };

    raindropFx.start();
  }
}
