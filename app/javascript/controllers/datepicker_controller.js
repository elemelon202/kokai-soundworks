import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "calendar"]

  connect() {
    if (typeof flatpickr === "undefined") {
      console.error("Flatpickr not loaded")
      return
    }

    // Find or create calendar container
    const calendarWrapper = this.element.querySelector(".calendar-wrapper")

    this.picker = flatpickr(calendarWrapper || this.inputTarget, {
      inline: true,
      dateFormat: "Y-m-d",
      minDate: "today",
      defaultDate: new Date(),
      onChange: (selectedDates, dateStr) => {
        this.inputTarget.value = dateStr
      }
    })

    // Set initial value
    this.inputTarget.value = this.picker.formatDate(new Date(), "Y-m-d")
  }

  disconnect() {
    if (this.picker) {
      this.picker.destroy()
    }
  }
}
