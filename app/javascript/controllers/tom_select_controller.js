import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = {
    placeholder: { type: String, default: "Search..." }
  }

  connect() {
    this.tomSelect = new TomSelect(this.element, {
      plugins: ['clear_button'],
      placeholder: this.placeholderValue,
      allowEmptyOption: true,
      sortField: {
        field: "text",
        direction: "asc"
      }
    })
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy()
    }
  }
}
