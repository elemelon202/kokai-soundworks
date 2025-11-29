import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="video-upload"
// Handles video file preview and direct upload progress for the shorts upload form
export default class extends Controller {
  static targets = ["input", "preview", "previewVideo", "submitButton"]

  connect() {
    if (this.hasSubmitButtonTarget) {
      this.setupDirectUpload()
    }
  }

  preview() {
    if (!this.hasInputTarget) return

    const file = this.inputTarget.files[0]
    if (!file) {
      this.hidePreview()
      return
    }

    const allowedTypes = ['video/mp4', 'video/webm', 'video/quicktime']
    if (!allowedTypes.includes(file.type)) {
      alert('Please select a valid video file (mp4, webm, mov).')
      this.inputTarget.value = ''
      this.hidePreview()
      return
    }

    const maxSize = 200 * 1024 * 1024 // 200MB in bytes
    if (file.size > maxSize) {
      alert('The selected file exceeds the maximum size of 200MB.')
      this.inputTarget.value = ''
      this.hidePreview()
      return
    }

    // Show preview if targets exist
    if (this.hasPreviewVideoTarget && this.hasPreviewTarget) {
      const url = URL.createObjectURL(file)
      this.previewVideoTarget.src = url
      this.previewTarget.style.display = 'block'
    }
  }

  hidePreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.style.display = 'none'
    }
    if (this.hasPreviewVideoTarget) {
      this.previewVideoTarget.src = ''
    }
  }

  setupDirectUpload() {
    this.element.addEventListener("direct-upload:start", () => {
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = true
        this.submitButtonTarget.value = "Uploading..."
      }
    })

    this.element.addEventListener("direct-upload:progress", (event) => {
      if (this.hasSubmitButtonTarget) {
        const { progress } = event.detail
        this.submitButtonTarget.value = `Uploading... ${Math.round(progress)}%`
      }
    })

    this.element.addEventListener("direct-upload:end", () => {
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = false
        this.submitButtonTarget.value = "Upload Short"
      }
    })

    this.element.addEventListener("direct-upload:error", (event) => {
      event.preventDefault()
      const { error } = event.detail
      alert(`Upload failed: ${error}`)
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = false
        this.submitButtonTarget.value = "Upload Short"
      }
    })
  }
}
