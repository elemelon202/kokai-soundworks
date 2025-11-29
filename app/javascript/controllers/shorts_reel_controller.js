import { Controller } from "@hotwired/stimulus"

// Shorts reel controller - tracks current short index during scroll-snap navigation
export default class extends Controller {
  static targets = ["container", "short", "counter"]

  connect() {
    this.currentIndex = 0
    this.scrollTimeout = null

    if (this.hasContainerTarget) {
      // Listen for scroll events to track current index
      this.containerTarget.addEventListener('scroll', this.onScroll.bind(this), { passive: true })
    }

    this.updateCounter()
    this.updateDots()
  }

  onScroll() {
    if (this.scrollTimeout) {
      clearTimeout(this.scrollTimeout)
    }

    // After scroll ends, determine which short we're on
    this.scrollTimeout = setTimeout(() => {
      this.updateCurrentIndex()
    }, 100)
  }

  updateCurrentIndex() {
    if (!this.hasContainerTarget) return

    const scrollTop = this.containerTarget.scrollTop
    // Use container height instead of window height (for embedded reels)
    const shortHeight = this.containerTarget.clientHeight
    if (shortHeight > 0) {
      this.currentIndex = Math.round(scrollTop / shortHeight)
    }

    this.updateCounter()
    this.updateDots()
  }

  disconnect() {
    if (this.scrollTimeout) {
      clearTimeout(this.scrollTimeout)
    }
  }

  next() {
    if (this.currentIndex < this.shortTargets.length - 1) {
      this.currentIndex++
      this.scrollToCurrentShort()
    }
  }

  prev() {
    if (this.currentIndex > 0) {
      this.currentIndex--
      this.scrollToCurrentShort()
    }
  }

  scrollToCurrentShort() {
    if (this.hasContainerTarget) {
      const shortHeight = this.containerTarget.clientHeight
      const targetScroll = this.currentIndex * shortHeight
      this.containerTarget.scrollTo({
        top: targetScroll,
        behavior: 'smooth'
      })
    }
    this.updateCounter()
    this.updateDots()
  }

  goToShortIndex(targetIndex) {
    this.currentIndex = targetIndex
    this.scrollToCurrentShort()
  }

  updateCounter() {
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.currentIndex + 1} / ${this.shortTargets.length}`
    }
  }

  updateDots() {
    // Update navigation dots
    const dots = this.element.querySelectorAll('[data-dot]')
    dots.forEach((dot, index) => {
      dot.style.background = index === this.currentIndex ? '#C8E938' : 'rgba(255,255,255,0.3)'
    })
  }

  // Click on a specific short (for dot navigation)
  goToShort(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    if (!isNaN(index)) {
      this.currentIndex = index
      this.goToShortIndex(this.currentIndex)
    }
  }
}
