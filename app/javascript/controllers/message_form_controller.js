import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  submitOnEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      const input = this.inputTarget
      if (input.value.trim() !== "") {
        this.element.requestSubmit()
        // Clear the input after submitting
        setTimeout(() => {
          input.value = ""
          input.focus()
        }, 10)
      }
    }
  }
}
