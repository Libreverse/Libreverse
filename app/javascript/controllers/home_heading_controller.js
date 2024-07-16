import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text"]

  connect() {
    this.adjustFontSize()
    window.addEventListener('resize', this.adjustFontSize.bind(this))
  }

  disconnect() {
    window.removeEventListener('resize', this.adjustFontSize.bind(this))
  }

  adjustFontSize() {
    const element = this.textTarget
    const viewportWidth = window.innerWidth
    const viewportHeight = window.innerHeight
  
    let fontSize = Math.min(viewportWidth * 0.15, viewportHeight * 0.3)
    fontSize = Math.min(fontSize, 200)
    fontSize = Math.max(fontSize, 100)
  
    element.style.fontSize = `${fontSize}px`
  
    if (viewportWidth <= 600) {
      element.innerHTML = element.textContent.replace('verse', '<br>verse')
    } else {
      element.innerHTML = element.textContent
    }
  }
}