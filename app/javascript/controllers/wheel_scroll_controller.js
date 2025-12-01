import { Controller } from "@hotwired/stimulus"

// Converts vertical scroll wheel to horizontal scrolling when hovering over the element
export default class extends Controller {
  static targets = ["shelf"]

  connect() {
    this.isHovering = false
    this.boundHandleWheel = this.handleWheel.bind(this)

    // Use the shelf target if available, otherwise use the element itself
    this.scrollElement = this.hasShelfTarget ? this.shelfTarget : this.element

    this.scrollElement.addEventListener("mouseenter", () => {
      this.isHovering = true
    })

    this.scrollElement.addEventListener("mouseleave", () => {
      this.isHovering = false
    })

    // Add wheel listener to window to catch scroll before it propagates
    window.addEventListener("wheel", this.boundHandleWheel, { passive: false })
  }

  disconnect() {
    window.removeEventListener("wheel", this.boundHandleWheel)
  }

  handleWheel(event) {
    if (!this.isHovering) return

    // Only convert if it's primarily a vertical scroll
    if (Math.abs(event.deltaY) > Math.abs(event.deltaX)) {
      // Check if mouse is over the scroll element
      const rect = this.scrollElement.getBoundingClientRect()
      if (
        event.clientX >= rect.left &&
        event.clientX <= rect.right &&
        event.clientY >= rect.top &&
        event.clientY <= rect.bottom
      ) {
        event.preventDefault()
        this.scrollElement.scrollLeft += event.deltaY * 8
      }
    }
  }
}
