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
  
    let fontSize = Math.min(viewportWidth * 0.08, viewportHeight * 0.15)
    fontSize = Math.min(fontSize, 130)
    fontSize = Math.max(fontSize, 80)

    element.style.fontSize = `${fontSize}px`
   
    let newContent = element.textContent;

    if (viewportWidth <= 1000) {
      newContent = newContent.replace('White', '<br>White')
    }
  
    if (viewportWidth <= 600) {
      newContent = newContent.replace('paper', '<br>paper')
    }
  
    element.innerHTML = newContent
  }
}