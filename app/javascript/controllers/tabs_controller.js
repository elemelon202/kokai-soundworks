import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "content"]

  switch(event) {
    const tabId = event.currentTarget.dataset.tab

    // Update tab buttons
    this.tabTargets.forEach(tab => tab.classList.remove("active"))
    event.currentTarget.classList.add("active")

    // Update content panels
    this.contentTargets.forEach(content => {
      if (content.dataset.tab === tabId) {
        content.classList.add("active")
      } else {
        content.classList.remove("active")
      }
    })
  }
}
