 // =============================================================================
  // SHORTS CAROUSEL CONTROLLER BY SAM! PAY ATTENTION TO THE COMMENTS! THIS TOOK MANY HOURS OF GOOGLE AND TRIAL AND ERROR! AND ALSO IT'S 3AM! AND I'M TIRED! AND I HAD TO REREAD ALL OF STIMULUS DOCS TO REMEMBER HOW STIMULUS WORKS!
  // =============================================================================
  // A Stimulus controller for a vertical, swipeable video carousel (YouTube Shorts-style)
  //
  // MARKUP REQUIREMENTS:
  // - Container with data-controller="shorts-carousel"
  // - data-shorts-carousel-target="feed" on the scrollable container
  // - data-shorts-carousel-target="card" + data-index="N" on each video card
  // - data-shorts-carousel-target="prevButton" / "nextButton" on nav buttons
  // - Each card must contain a nested video-player controller
  //
  // FEATURES:
  // 1. Vertical snap-scrolling between full-height video cards
  // 2. Multiple input methods: buttons, keyboard (↑/↓), touch swipe
  // 3. Lazy video playback via IntersectionObserver (only visible video plays)
  // 4. Auto-hides nav buttons at carousel boundaries
  //
  // =============================================================================

  // TARGETS
  // - feed: The scrollable viewport container
  // - card: Individual video cards (must have data-index attribute which means their position)
  // - prevButton/nextButton: Navigation controls

  // LIFECYCLE
  // - connect(): Initializes state, binds touch/keyboard events, sets up observer
  // - disconnect(): Cleans up keyboard listener and observer

  // INTERSECTION OBSERVER (setupIntersectionObserver)
  // - Watches cards with 50% visibility threshold
  // - When card enters view: plays its video, updates currentIndex, refreshes nav buttons
  // - When card leaves view: pauses its video
  // - This enables lazy loading - videos only play when visible

  // NAVIGATION (scrollToCard, next, prev)
  // - scrollToCard(index): Scrolls feed to card at index with smooth animation
  // - next()/prev(): Increment/decrement index with bounds checking
  // - updateNavButtons(): Hides prev at start, next at end

  // INPUT HANDLERS
  // - handleKeydown: ArrowUp → prev(), ArrowDown → next()
  // - handleTouchStart/End: Tracks Y-axis swipe, 50px threshold triggers nav
  //   (swipe up = next, swipe down = prev)

  // 1. Initialization (connect())

  // Page loads → Stimulus connects controller
  //   ↓
  // Set currentIndex = 0 (start at first card)
  //   ↓
  // Bind event listeners:
  //   - touchstart/touchend on feed (for swipe detection)
  //   - keydown on document (for arrow keys)
  //   ↓
  // Setup IntersectionObserver (watches which card is visible)
  //   ↓
  // Update nav button visibility

  // 2. IntersectionObserver kicks in

  // Observer detects first card is 50%+ visible
  //   ↓
  // Finds the video-player controller inside that card
  //   ↓
  // Calls videoController.play() → first video starts
  //   ↓
  // Sets currentIndex to that card's data-index

  // 3. User navigates (button, key, or swipe)

  // Button click / Arrow key:
  // next() or prev() called
  //   ↓
  // Bounds check (don't go below 0 or above card count)
  //   ↓
  // scrollToCard(newIndex)
  //   ↓
  // Smooth scroll feed so new card is in view
  //   ↓
  // Observer detects old card left view → pauses its video
  // Observer detects new card entered view → plays its video
  //   ↓
  // updateNavButtons() hides/shows buttons at boundaries

  // Touch swipe:
  // touchstart → store Y coordinate
  //   ↓
  // touchend → store Y coordinate
  //   ↓
  // Calculate difference (touchStartY - touchEndY)
  //   ↓
  // If diff > 50px → swipe up → next()
  // If diff < -50px → swipe down → prev()

  // 4. Cleanup (disconnect())

import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="shorts-carousel"
export default class extends Controller {
  static targets = [ "feed", "card", "prevButton", "nextButton" ]
 // a lot of this is to do with touch events for mobile swiping, which is why it's more complex than a simple carousel. lots of x and y coordinates. thanks google! sam
  connect() {
    this.currentIndex = 0 // Start at the first card
    this.touchStartX = 0 // Initialize touch start X coordinate
    this.touchEndX = 0 // Initialize touch end X coordinate

    this.feedTarget.addEventListener('touchstart', (event) => this.handleTouchStart(event)) // Bind touchstart event
    this.feedTarget.addEventListener('touchend', (event) => this.handleTouchEnd(event)) // Bind touchend event

    document.addEventListener("keydown", this.handleKeydown.bind(this)) // Bind 'this' context

    this.setupIntersectionObserver() // Setup Intersection Observer which watches for visibility of cards. we need this to lazy load videos which means we only load videos when they are in view.
    this.updateNavButtons()
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown.bind(this)) // Clean up event listener on disconnect
    this.observer?.disconnect() // Disconnect Intersection Observer
  }

  setupIntersectionObserver() {
    const options = {
      root: this.feedTarget,
      threshold: 0.5 // Trigger when 50% of the card is visible
    }
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        const card = entry.target
        const videoController = this.application.getControllerForElementAndIdentifier(card.querySelector("[data-controller= 'video-player']"), "video-player"
      )
        if (entry.isIntersecting) {
          videoController?.play() // Play video when card is in view
          this.currentIndex = parseInt(card.dataset.index) // Update current index
          this.updateNavButtons()
        } else {
          videoController?.pause() // Pause video when card is out of view
        }
  })
    }, options)

    this.cardTargets.forEach(card => this.observer.observe(card)) // Observe each card
  }

  previous() {
    if (this.currentIndex > 0) {
      this.goToIndex(this.currentIndex - 1)
    }
  }

  next() {
    if (this.currentIndex < this.cardTargets.length - 1) {
      this.goToIndex(this.currentIndex + 1)
    }
  }

  goToIndex(index) { // Scroll to card at specified index.
    const card = this.cardTargets[index]
    if (card) {
      card.scrollIntoView({ behavior: 'smooth', block: 'center' })
      this.currentIndex = index
      this.updateNavButtons()
    }
  }

  handleKeydown(event) {
    if (event.key === "ArrowUp" || event.key === "k") {
      event.preventDefault() // Prevent default scrolling behavior
      this.previous() // Up arrow or 'k' key for previous
    } else if (event.key === "ArrowDown" || event.key === "j") {
      event.preventDefault() // Prevent default scrolling behavior
      this.next() // Down arrow or 'j' key for next
    }
  }
  handleTouchStart(event) {
    this.touchStartY = event.touches[0].clientY // Get the starting Y coordinate
  }

  handleTouchEnd(event) {
    this.touchEndY = event.changedTouches[0].clientY // Get the ending Y coordinate
    const diff =this.touchStartY - this.touchEndY
    const threshold = 50 // Minimum distance to be considered a swipe

    if (Math.abs(diff) > threshold) {
      if (diff > 0) {
        this.next() // Swipe up
      } else {
        this.previous() // Swipe down
      }
    }
  }
  updateNavButtons() {
    if (this.hasPrevButtonTarget) {
      this.prevButtonTarget.disabled = this.currentIndex === 0
    }
    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = this.currentIndex === this.cardTargets.length - 1
    }
  }
}
