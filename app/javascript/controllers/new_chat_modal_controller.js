import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "list", "noResults", "musician"]

  connect() {
    this.element.addEventListener("shown.bs.modal", this.handleModalShown.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("shown.bs.modal", this.handleModalShown.bind(this))
  }

  handleModalShown() {
    this.searchTarget.value = ""
    this.filter()
    this.searchTarget.focus()
  }

  filter() {
    const searchTerm = this.searchTarget.value.toLowerCase().trim()
    let visibleCount = 0

    this.musicianTargets.forEach((musician) => {
      const name = musician.dataset.musicianName || ""
      const instrument = musician.dataset.musicianInstrument || ""

      if (name.includes(searchTerm) || instrument.includes(searchTerm)) {
        musician.style.display = "block"
        visibleCount++
      } else {
        musician.style.display = "none"
      }
    })

    this.noResultsTarget.style.display = visibleCount === 0 ? "block" : "none"
  }
}
