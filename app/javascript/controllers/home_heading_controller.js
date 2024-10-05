//taken from the pre-rewrite libreverse codebase and modified by xAI Grok 2

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
  
    let fontSize = Math.min(viewportWidth * 0.15, 200)
    fontSize = Math.max(fontSize, 100)

    element.style.fontSize = `${fontSize}px`
   
    let newContent = element.textContent;

    if (viewportWidth <= 600) {
      newContent = newContent.replace('verse', '<br>verse')
    }
  
    element.innerHTML = newContent
  }
}