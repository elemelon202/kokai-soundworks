import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = {
    placeholder: { type: String, default: "Search..." }
  }

  connect() {
    const isMultiple = this.element.hasAttribute('multiple')
    const plugins = isMultiple ? ['remove_button', 'clear_button'] : ['clear_button']

    this.tomSelect = new TomSelect(this.element, {
      plugins: plugins,
      placeholder: this.placeholderValue,
      allowEmptyOption: true,
      maxItems: isMultiple ? null : 1,

      onInitialize() {
        // preselected musician is shown
        const preselected = [...this.element.options]
          .filter(opt => opt.selected)
          .map(opt => opt.value)

        if (preselected.length > 0) {
          this.setValue(preselected)
        }
      }
    })
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy()
    }
  }
}
