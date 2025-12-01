import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["stack", "card", "indicatorRight", "indicatorLeft", "progress", "progressText", "form", "statusInput"]

  connect() {
    this.currentIndex = 0
    this.cards = this.cardTargets
    this.totalCards = this.cards.length
    this.startX = 0
    this.startY = 0
    this.isDragging = false

    if (this.cards.length > 0) {
      this.setupTouchEvents()
    }
  }

  setupTouchEvents() {
    this.cards.forEach((card, index) => {
      card.addEventListener('touchstart', (e) => this.handleTouchStart(e, card))
      card.addEventListener('touchmove', (e) => this.handleTouchMove(e, card))
      card.addEventListener('touchend', (e) => this.handleTouchEnd(e, card))

      card.addEventListener('mousedown', (e) => this.handleMouseDown(e, card))
      card.addEventListener('mousemove', (e) => this.handleMouseMove(e, card))
      card.addEventListener('mouseup', (e) => this.handleMouseUp(e, card))
      card.addEventListener('mouseleave', (e) => this.handleMouseUp(e, card))
    })
  }

  handleTouchStart(e, card) {
    if (!card.classList.contains('active')) return
    this.startX = e.touches[0].clientX
    this.startY = e.touches[0].clientY
    this.isDragging = true
    card.style.transition = 'none'
  }

  handleTouchMove(e, card) {
    if (!this.isDragging || !card.classList.contains('active')) return

    const currentX = e.touches[0].clientX
    const currentY = e.touches[0].clientY
    const diffX = currentX - this.startX
    const diffY = currentY - this.startY

    // Only horizontal swipes
    if (Math.abs(diffX) > Math.abs(diffY)) {
      e.preventDefault()
      this.updateCardPosition(card, diffX)
    }
  }

  handleTouchEnd(e, card) {
    if (!this.isDragging || !card.classList.contains('active')) return
    this.isDragging = false

    const currentX = e.changedTouches[0].clientX
    const diffX = currentX - this.startX

    this.finalizeSwipe(card, diffX)
  }

  handleMouseDown(e, card) {
    if (!card.classList.contains('active')) return
    this.startX = e.clientX
    this.isDragging = true
    card.style.transition = 'none'
    card.style.cursor = 'grabbing'
  }

  handleMouseMove(e, card) {
    if (!this.isDragging || !card.classList.contains('active')) return

    const diffX = e.clientX - this.startX
    this.updateCardPosition(card, diffX)
  }

  handleMouseUp(e, card) {
    if (!this.isDragging || !card.classList.contains('active')) return
    this.isDragging = false
    card.style.cursor = 'grab'

    const diffX = e.clientX - this.startX
    this.finalizeSwipe(card, diffX)
  }

  updateCardPosition(card, diffX) {
    const rotation = diffX * 0.1
    const opacity = Math.min(Math.abs(diffX) / 100, 1)

    card.style.transform = `translateX(${diffX}px) rotate(${rotation}deg)`

    // Show indicators
    const rightIndicator = card.querySelector('.swipe-indicator-interested')
    const leftIndicator = card.querySelector('.swipe-indicator-skip')

    if (diffX > 0) {
      rightIndicator.style.opacity = opacity
      leftIndicator.style.opacity = 0
    } else {
      leftIndicator.style.opacity = opacity
      rightIndicator.style.opacity = 0
    }
  }

  finalizeSwipe(card, diffX) {
    const threshold = 100

    card.style.transition = 'transform 0.3s ease, opacity 0.3s ease'

    if (diffX > threshold) {
      this.animateSwipe(card, 'right')
    } else if (diffX < -threshold) {
      this.animateSwipe(card, 'left')
    } else {
      // Reset position
      card.style.transform = ''
      const rightIndicator = card.querySelector('.swipe-indicator-interested')
      const leftIndicator = card.querySelector('.swipe-indicator-skip')
      rightIndicator.style.opacity = 0
      leftIndicator.style.opacity = 0
    }
  }

  swipeRight() {
    const currentCard = this.cards[this.currentIndex]
    if (!currentCard) return
    this.animateSwipe(currentCard, 'right')
  }

  swipeLeft() {
    const currentCard = this.cards[this.currentIndex]
    if (!currentCard) return
    this.animateSwipe(currentCard, 'left')
  }

  animateSwipe(card, direction) {
    const gigId = card.dataset.gigId
    const flyOutX = direction === 'right' ? window.innerWidth : -window.innerWidth
    const rotation = direction === 'right' ? 30 : -30

    card.style.transition = 'transform 0.5s ease, opacity 0.5s ease'
    card.style.transform = `translateX(${flyOutX}px) rotate(${rotation}deg)`
    card.style.opacity = '0'

    // Handle RSVP for right swipe
    if (direction === 'right') {
      this.submitRsvp(gigId, 'interested')
    }

    setTimeout(() => {
      card.classList.remove('active')
      card.style.display = 'none'

      this.currentIndex++
      this.updateProgress()

      // Show next card
      if (this.currentIndex < this.cards.length) {
        const nextCard = this.cards[this.currentIndex]
        nextCard.classList.add('active')
        nextCard.style.display = ''
        nextCard.style.transform = ''
        nextCard.style.opacity = '1'

        // Pre-show the card after next
        if (this.currentIndex + 1 < this.cards.length) {
          this.cards[this.currentIndex + 1].style.display = ''
        }
        if (this.currentIndex + 2 < this.cards.length) {
          this.cards[this.currentIndex + 2].style.display = ''
        }
      } else {
        // All cards swiped
        this.showEmptyState()
      }
    }, 300)
  }

  submitRsvp(gigId, status) {
    if (!this.hasFormTarget) return

    fetch(`/gigs/${gigId}/rsvp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: `status=${status}`
    }).then(response => {
      if (response.ok) {
        this.showToast('Added to your interested gigs!')
      }
    }).catch(error => {
      console.error('RSVP failed:', error)
    })
  }

  showToast(message) {
    const toast = document.createElement('div')
    toast.className = 'swipe-toast'
    toast.innerHTML = `<i class="fa-solid fa-heart"></i> ${message}`
    document.body.appendChild(toast)

    setTimeout(() => toast.classList.add('show'), 10)
    setTimeout(() => {
      toast.classList.remove('show')
      setTimeout(() => toast.remove(), 300)
    }, 2000)
  }

  updateProgress() {
    if (this.hasProgressTextTarget) {
      const remaining = this.totalCards - this.currentIndex
      if (remaining > 0) {
        this.progressTextTarget.textContent = `${this.currentIndex + 1} / ${this.totalCards}`
      } else {
        this.progressTarget.style.display = 'none'
      }
    }
  }

  showDetails() {
    const currentCard = this.cards[this.currentIndex]
    if (!currentCard) return

    const gigId = currentCard.dataset.gigId
    window.location.href = `/gigs/${gigId}`
  }

  showEmptyState() {
    this.stackTarget.innerHTML = `
      <div class="swipe-empty">
        <div class="swipe-empty-icon">
          <i class="fa-solid fa-calendar-check"></i>
        </div>
        <h2>You're all caught up!</h2>
        <p>You've seen all available gigs. Check back later for new shows!</p>
        <a href="/discover-gigs" class="swipe-browse-btn">
          <i class="fa-solid fa-list"></i> Browse All Gigs
        </a>
      </div>
    `
  }
}
