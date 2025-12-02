import { Controller } from "@hotwired/stimulus"

// Syncs the logo spin animation to a fixed clock so it maintains
// consistent position across page navigations
export default class extends Controller {
  connect() {
    const now = Date.now() / 1000 // current time in seconds
    const duration = 80 // matches the 80s in CSS animation
    const delay = -(now % duration) // negative delay syncs to clock
    this.element.style.animationDelay = `${delay}s`
  }
}
