import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  initialize() {
    this.checkContentHeight = this.checkContentHeight.bind(this)
    this.observer = new MutationObserver(this.checkContentHeight)
  }

  connect() {
    this.checkContentHeight()
    window.addEventListener('resize', this.checkContentHeight)
    this.observer.observe(this.element, { 
      childList: true, 
      subtree: true, 
      attributes: true, 
      characterData: true 
    })
  }

  disconnect() {
    window.removeEventListener('resize', this.checkContentHeight)
    this.observer.disconnect()
  }

  checkContentHeight() {
    if (this.element.scrollHeight > window.innerHeight) {
      this.unlockScroll()
    } else {
      this.lockScroll()
    }
  }

  lockScroll() {
    document.body.style.overflow = 'hidden'
  }

  unlockScroll() {
    document.body.style.overflow = 'auto'
  }
}