import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    console.log("Dropdown controller connected")
    // Close dropdown when clicking outside
    document.addEventListener("click", this.closeOnClickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside.bind(this))
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.hasMenuTarget) {
      const isVisible = this.menuTarget.classList.contains("show")
      if (isVisible) {
        this.hide()
      } else {
        this.show()
      }
    }
  }

  show() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add("show")
      this.menuTarget.style.display = "block"
    }
  }

  hide() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.remove("show")
      this.menuTarget.style.display = "none"
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }
}