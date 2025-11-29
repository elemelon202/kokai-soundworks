import { Controller } from "@hotwired/stimulus"

/**
 * Shorts Reorder Controller
 *
 * This Stimulus controller enables drag-and-drop reordering of musician short videos.
 * It allows users to rearrange the display order of their shorts by dragging them
 * to new positions within a grid layout with smooth slide animations.
 *
 * Usage:
 *   <div data-controller="shorts-reorder" data-shorts-reorder-musician-id-value="123">
 *     <div data-shorts-reorder-target="grid">
 *       <div data-short-id="1" draggable="true"
 *            data-action="dragstart->shorts-reorder#dragStart
 *                         dragover->shorts-reorder#dragOver
 *                         drop->shorts-reorder#drop">
 *         <!-- short content -->
 *       </div>
 *     </div>
 *   </div>
 *
 * Flow:
 *   1. User starts dragging a short video card
 *   2. As they drag over other cards, items slide smoothly to make room
 *   3. When dropped, the new order is sent to the server via PATCH request
 *   4. Server persists the new display_order for each short
 */
export default class extends Controller {
  static targets = ["grid"]
  static values = { musicianId: Number }

  connect() {
    this.draggedItem = null
    this.placeholder = null
    this.animationDuration = 200 // ms

    // Add transition styles to all items
    this.addTransitionStyles()
  }

  /**
   * Add CSS transition to all draggable items for smooth animations
   */
  addTransitionStyles() {
    const items = this.gridTarget.querySelectorAll("[data-short-id]")
    items.forEach(item => {
      item.style.transition = `transform ${this.animationDuration}ms ease, opacity ${this.animationDuration}ms ease`
    })
  }

  /**
   * Called when user starts dragging a short card.
   * Creates a placeholder and applies visual styling.
   */
  dragStart(event) {
    this.draggedItem = event.target.closest("[data-short-id]")
    if (!this.draggedItem) return

    event.dataTransfer.effectAllowed = "move"

    // Store original position for animation
    this.originalRect = this.draggedItem.getBoundingClientRect()

    // Create placeholder
    this.placeholder = document.createElement('div')
    this.placeholder.className = 'shorts-reorder-placeholder'
    this.placeholder.style.cssText = `
      width: ${this.draggedItem.offsetWidth}px;
      height: ${this.draggedItem.offsetHeight}px;
      background: rgba(200, 233, 56, 0.2);
      border: 2px dashed #C8E938;
      border-radius: 12px;
      transition: all ${this.animationDuration}ms ease;
    `

    // Insert placeholder after dragged item
    this.draggedItem.parentNode.insertBefore(this.placeholder, this.draggedItem.nextSibling)

    // Style the dragged item
    requestAnimationFrame(() => {
      this.draggedItem.style.opacity = '0.5'
      this.draggedItem.style.transform = 'scale(1.05)'
      this.draggedItem.classList.add("is-dragging")
    })
  }

  /**
   * Called continuously as the dragged item moves over potential drop targets.
   * Moves the placeholder with smooth animation to indicate drop position.
   */
  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const target = event.target.closest("[data-short-id]")
    if (!target || target === this.draggedItem || target === this.placeholder) return

    const rect = target.getBoundingClientRect()
    const midpoint = rect.left + rect.width / 2

    // Animate other items out of the way
    const items = Array.from(this.gridTarget.querySelectorAll("[data-short-id]"))

    if (event.clientX < midpoint) {
      // Insert placeholder before target
      if (this.placeholder.nextSibling !== target) {
        this.animateInsertion(target, 'before')
        this.gridTarget.insertBefore(this.placeholder, target)
      }
    } else {
      // Insert placeholder after target
      if (this.placeholder.previousSibling !== target) {
        this.animateInsertion(target, 'after')
        this.gridTarget.insertBefore(this.placeholder, target.nextSibling)
      }
    }
  }

  /**
   * Animate items sliding to make room for the dragged item
   */
  animateInsertion(target, position) {
    const items = Array.from(this.gridTarget.querySelectorAll("[data-short-id]:not(.is-dragging)"))

    items.forEach(item => {
      // Quick flash animation to indicate movement
      item.style.transform = 'scale(0.98)'
      setTimeout(() => {
        item.style.transform = ''
      }, this.animationDuration / 2)
    })
  }

  /**
   * Called when the dragged item is dropped.
   * Animates the item into place and persists the new order.
   */
  drop(event) {
    event.preventDefault()
    this.finishDrag()
  }

  /**
   * Called when dragging ends (whether dropped successfully or canceled).
   * Ensures cleanup happens even if drop event doesn't fire.
   */
  dragEnd() {
    this.finishDrag()
  }

  /**
   * Shared cleanup logic for ending a drag operation.
   * Animates the dragged item into its final position.
   */
  finishDrag() {
    if (this.draggedItem && this.placeholder) {
      // Get placeholder position for animation
      const placeholderRect = this.placeholder.getBoundingClientRect()
      const draggedRect = this.draggedItem.getBoundingClientRect()

      // Calculate the distance to animate
      const deltaX = placeholderRect.left - draggedRect.left
      const deltaY = placeholderRect.top - draggedRect.top

      // Animate to placeholder position
      this.draggedItem.style.transform = `translate(${deltaX}px, ${deltaY}px) scale(1)`
      this.draggedItem.style.opacity = '1'

      // After animation, move to final position and clean up
      setTimeout(() => {
        // Move dragged item to placeholder position
        this.gridTarget.insertBefore(this.draggedItem, this.placeholder)

        // Remove placeholder
        this.placeholder.remove()
        this.placeholder = null

        // Reset dragged item styles
        this.draggedItem.style.transform = ''
        this.draggedItem.style.opacity = ''
        this.draggedItem.classList.remove("is-dragging")

        // Add a subtle bounce effect
        this.draggedItem.style.transform = 'scale(1.02)'
        setTimeout(() => {
          this.draggedItem.style.transform = ''
          this.draggedItem = null
        }, 100)

        // Save the new order
        this.saveOrder()
      }, this.animationDuration)
    } else if (this.draggedItem) {
      // Cleanup if no placeholder (drag was cancelled early)
      this.draggedItem.style.transform = ''
      this.draggedItem.style.opacity = ''
      this.draggedItem.classList.remove("is-dragging")
      this.draggedItem = null
    }
  }

  /**
   * Persists the new display order to the server.
   * Collects all short IDs in their current DOM order and sends them
   * to the reorder endpoint, which updates each short's display_order.
   */
  async saveOrder() {
    const shortIds = Array.from(this.gridTarget.querySelectorAll("[data-short-id]"))
      .map(item => item.dataset.shortId)

    try {
      const response = await fetch(`/musicians/${this.musicianIdValue}/shorts/reorder`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ short_ids: shortIds })
      })

      if (!response.ok) {
        throw new Error("Failed to save new order")
      }
    } catch (error) {
      console.error("Error saving order:", error)
      alert("Failed to save new order. Please try again.")
    }
  }
}
