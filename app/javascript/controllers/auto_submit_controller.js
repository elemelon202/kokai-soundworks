import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="auto-submit"
export default class extends Controller {
  submit(event) {
    const form = this.element.closest("form")
    if (form) {
      form.requestSubmit()
    }
  }
}
