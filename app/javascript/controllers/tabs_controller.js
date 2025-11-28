import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "content"]

  switch(event) {
    const tabId = event.currentTarget.dataset.tab

    this.buttonTargets.forEach(btn => btn.classList.remove("active"))
    event.currentTarget.classList.add("active")

    this.contentTargets.forEach(content => {
      if (content.id === `tab-${tabId}`) {
        content.classList.add("active")
      } else {
        content.classList.remove("active")
      }
    })
  }
}
