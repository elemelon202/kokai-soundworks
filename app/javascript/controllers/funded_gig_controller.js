import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["progressBar", "currentAmount", "percentage", "supporterCount", "remainingAmount"]
  static values = { fundedGigId: Number, fundingTarget: Number }

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "FundedGigChannel", funded_gig_id: this.fundedGigIdValue },
      {
        received: (data) => this.handleUpdate(data)
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  handleUpdate(data) {
    if (data.type === 'funding_update') {
      this.animateUpdate(data)

      if (data.funding_reached) {
        this.celebrate()
      }
    }
  }

  animateUpdate(data) {
    // Animate the progress bar
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.transition = 'width 1s ease-out'
      this.progressBarTarget.style.width = `${Math.min(data.funding_percentage, 100)}%`
    }

    // Animate the current amount with counting effect
    if (this.hasCurrentAmountTarget) {
      this.animateNumber(this.currentAmountTarget, data.current_pledged_cents)
    }

    // Update percentage
    if (this.hasPercentageTarget) {
      this.percentageTarget.textContent = `${data.funding_percentage}%`
      this.percentageTarget.classList.add('pulse-animation')
      setTimeout(() => this.percentageTarget.classList.remove('pulse-animation'), 500)
    }

    // Update supporter count
    if (this.hasSupporterCountTarget) {
      this.supporterCountTarget.textContent = data.supporter_count
    }

    // Update remaining amount
    if (this.hasRemainingAmountTarget) {
      const remaining = data.funding_target_cents - data.current_pledged_cents
      this.remainingAmountTarget.textContent = `${Math.max(remaining, 0).toLocaleString()}`
    }

    // Show new pledge notification
    if (data.latest_pledge) {
      this.showPledgeNotification(data.latest_pledge)
    }
  }

  animateNumber(element, targetValue) {
    const currentText = element.textContent.replace(/[^0-9]/g, '')
    const startValue = parseInt(currentText) || 0
    const duration = 1000
    const startTime = performance.now()

    const animate = (currentTime) => {
      const elapsed = currentTime - startTime
      const progress = Math.min(elapsed / duration, 1)

      // Easing function for smooth animation
      const easeOut = 1 - Math.pow(1 - progress, 3)
      const current = Math.round(startValue + (targetValue - startValue) * easeOut)

      element.textContent = `${current.toLocaleString()}`

      if (progress < 1) {
        requestAnimationFrame(animate)
      }
    }

    requestAnimationFrame(animate)
  }

  showPledgeNotification(pledge) {
    const notification = document.createElement('div')
    notification.className = 'pledge-notification'
    notification.innerHTML = `
      <div class="pledge-notification-content">
        <i class="fa-solid fa-heart"></i>
        <span><strong>${pledge.display_name}</strong> pledged ${pledge.amount.toLocaleString()}</span>
      </div>
    `
    document.body.appendChild(notification)

    // Animate in
    setTimeout(() => notification.classList.add('show'), 10)

    // Remove after 4 seconds
    setTimeout(() => {
      notification.classList.remove('show')
      setTimeout(() => notification.remove(), 300)
    }, 4000)
  }

  celebrate() {
    // Create confetti first
    this.createConfetti()

    // Play sound effect if available
    this.playSuccessSound()

    // Wait for confetti to build up before showing the success banner (3 seconds delay)
    setTimeout(() => {
      const successBanner = document.createElement('div')
      successBanner.className = 'funding-success-banner'
      successBanner.innerHTML = `
        <div class="funding-success-content">
          <h2>FUNDING GOAL REACHED!</h2>
          <p>This show is happening!</p>
        </div>
      `
      document.body.appendChild(successBanner)

      setTimeout(() => successBanner.classList.add('show'), 10)
    }, 3000)
  }

  createConfetti() {
    const colors = ['#C8E938', '#FFD700', '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD']
    const confettiCount = 150

    for (let i = 0; i < confettiCount; i++) {
      setTimeout(() => {
        const confetti = document.createElement('div')
        confetti.className = 'confetti'
        confetti.style.cssText = `
          left: ${Math.random() * 100}vw;
          background-color: ${colors[Math.floor(Math.random() * colors.length)]};
          animation-duration: ${Math.random() * 3 + 2}s;
          animation-delay: ${Math.random() * 0.5}s;
        `
        document.body.appendChild(confetti)

        // Remove after animation
        setTimeout(() => confetti.remove(), 5000)
      }, i * 20)
    }
  }

  playSuccessSound() {
    // Optional: Add a success sound
    try {
      const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2teleQMCPKHd7K1jAQE9qOb3sGMBATak4PsAA')
      audio.volume = 0.3
      audio.play().catch(() => {}) // Ignore errors if autoplay is blocked
    } catch (e) {
      // Audio not supported
    }
  }
}
