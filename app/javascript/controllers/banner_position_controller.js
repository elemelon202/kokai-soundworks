import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "input", "value", "preview"]

  connect() {
    this.position = parseInt(this.inputTarget.value) || 50
    this.isDragging = false
    this.startY = 0
    this.startPosition = 0

    // Add drag support
    this.previewTarget.addEventListener("mousedown", this.startDrag.bind(this))
    this.previewTarget.addEventListener("touchstart", this.startDrag.bind(this), { passive: false })
    document.addEventListener("mousemove", this.drag.bind(this))
    document.addEventListener("touchmove", this.drag.bind(this), { passive: false })
    document.addEventListener("mouseup", this.endDrag.bind(this))
    document.addEventListener("touchend", this.endDrag.bind(this))
  }

  disconnect() {
    document.removeEventListener("mousemove", this.drag.bind(this))
    document.removeEventListener("touchmove", this.drag.bind(this))
    document.removeEventListener("mouseup", this.endDrag.bind(this))
    document.removeEventListener("touchend", this.endDrag.bind(this))
  }

  startDrag(event) {
    event.preventDefault()
    this.isDragging = true
    this.startY = event.type.includes("touch") ? event.touches[0].clientY : event.clientY
    this.startPosition = this.position
    this.previewTarget.style.cursor = "grabbing"
  }

  drag(event) {
    if (!this.isDragging) return
    event.preventDefault()

    const currentY = event.type.includes("touch") ? event.touches[0].clientY : event.clientY
    const deltaY = currentY - this.startY
    const previewHeight = this.previewTarget.offsetHeight

    // Calculate new position (inverted: drag down = lower %, drag up = higher %)
    const deltaPercent = (deltaY / previewHeight) * 100
    let newPosition = this.startPosition + deltaPercent

    // Clamp between 0 and 100
    newPosition = Math.max(0, Math.min(100, newPosition))
    this.setPosition(Math.round(newPosition))
  }

  endDrag() {
    this.isDragging = false
    this.previewTarget.style.cursor = "grab"
  }

  moveUp() {
    this.setPosition(Math.max(0, this.position - 5))
  }

  moveDown() {
    this.setPosition(Math.min(100, this.position + 5))
  }

  setPosition(value) {
    this.position = value
    this.imageTarget.style.objectPosition = `center ${value}%`
    this.inputTarget.value = value
    this.valueTarget.textContent = `${value}%`

    // Also update the hidden field in the main media form if it exists
    // This ensures banner position is saved when the user clicks "Save Media" or "Save Changes"
    const mediaFormInput = document.getElementById('band-media-form-banner-position') ||
                           document.getElementById('musician-form-banner-position')
    if (mediaFormInput) {
      mediaFormInput.value = value
    }
  }
}
