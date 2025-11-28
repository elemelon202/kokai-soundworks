import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()
    document.addEventListener("turbo:before-stream-render", this.handleStreamRender)
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.handleStreamRender)
  }

  handleStreamRender = () => {
    setTimeout(() => {
      this.scrollToBottom()
    }, 100)
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
