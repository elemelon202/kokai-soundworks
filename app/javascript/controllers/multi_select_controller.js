import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  connect() {
    this.tomSelect = new TomSelect(this.element, {
      plugins: ['remove_button'],
      maxItems: null,
      allowEmptyOption: true,
      closeAfterSelect: false,
      hidePlaceholder: true
    })
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy()
    }
  }
}
