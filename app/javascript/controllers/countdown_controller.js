import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["days", "hours", "minutes"]
  static values = { date: String }

  connect() {
    this.updateCountdown()
    this.timer = setInterval(() => this.updateCountdown(), 60000) // Update every minute
  }

  disconnect() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }

  updateCountdown() {
    const targetDate = new Date(this.dateValue)
    const now = new Date()
    const diff = targetDate - now

    if (diff <= 0) {
      this.daysTarget.textContent = "0"
      this.hoursTarget.textContent = "0"
      this.minutesTarget.textContent = "0"
      return
    }

    const days = Math.floor(diff / (1000 * 60 * 60 * 24))
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))

    this.daysTarget.textContent = days
    this.hoursTarget.textContent = hours
    this.minutesTarget.textContent = minutes
  }
}
