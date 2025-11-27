import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = {
    url: { type: String, default: "/musicians/search" },
    exclude: { type: String, default: "" },
    placeholder: { type: String, default: "Search musicians by name, instrument, or location..." }
  }

  connect() {
    const excludedIds = this.excludeValue.split(',').filter(id => id.trim() !== '')

    this.tomSelect = new TomSelect(this.element, {
      plugins: ['clear_button'],
      placeholder: this.placeholderValue,
      valueField: 'id',
      labelField: 'display',
      searchField: ['name', 'instrument', 'location'],
      maxItems: 1,
      preload: true,
      load: (query, callback) => {
        const url = `${this.urlValue}?query=${encodeURIComponent(query)}`
        fetch(url)
          .then(response => response.json())
          .then(json => {
            // Filter out excluded musicians (already in band or pending invitation)
            const filtered = json.filter(m => !excludedIds.includes(String(m.id)))
            callback(filtered)
          })
          .catch(() => {
            callback()
          })
      },
      render: {
        option: (data, escape) => {
          return `<div class="musician-option">
            <span class="musician-name">${escape(data.name)}</span>
            <span class="musician-details">${escape(data.instrument)}${data.location ? ` - ${escape(data.location)}` : ''}</span>
          </div>`
        },
        item: (data, escape) => {
          return `<div class="musician-item">
            <span class="musician-name">${escape(data.name)}</span>
            <span class="musician-instrument">(${escape(data.instrument)})</span>
          </div>`
        },
        no_results: () => {
          return '<div class="no-results">No musicians found</div>'
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
