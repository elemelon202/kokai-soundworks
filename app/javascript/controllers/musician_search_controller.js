import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = {
    url: { type: String, default: "/musicians/search" },
    placeholder: { type: String, default: "Search musicians by name, instrument, or location..." }
  }

  connect() {
    this.initTomSelect()
  }

  initTomSelect() {
    const self = this

    this.tomSelect = new TomSelect(this.element, {
      plugins: ['remove_button'],
      placeholder: this.placeholderValue,
      valueField: 'id',
      labelField: 'display',
      searchField: ['name', 'instrument', 'location', 'display'],
      maxItems: null,
      preload: 'focus',
      loadThrottle: 300,
      load: function(query, callback) {
        const url = `${self.urlValue}?query=${encodeURIComponent(query)}`
        fetch(url)
          .then(response => response.json())
          .then(json => {
            callback(json)
          })
          .catch((error) => {
            console.error('Error loading musicians:', error)
            callback()
          })
      },
      render: {
        option: function(data, escape) {
          return `<div class="musician-option">
            <span class="musician-name">${escape(data.name)}</span>
            <span class="musician-details">${escape(data.instrument)}${data.location ? ` - ${escape(data.location)}` : ''}</span>
          </div>`
        },
        item: function(data, escape) {
          return `<div class="musician-item">
            <span class="musician-name">${escape(data.name)}</span>
            <span class="musician-instrument">(${escape(data.instrument)})</span>
          </div>`
        },
        no_results: function() {
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
