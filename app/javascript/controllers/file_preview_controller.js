import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "placeholder"]
  static values = { multiple: { type: Boolean, default: true } }

  connect() {
    // Check if input allows multiple files
    this.isMultiple = this.inputTarget.multiple
    // Store accumulated files as an array
    this.files = []
    this.updatePreview()
  }

  preview(event) {
    const newFiles = Array.from(this.inputTarget.files)

    if (this.isMultiple) {
      // For multiple file inputs, accumulate files
      newFiles.forEach(file => {
        const exists = this.files.some(f => f.name === file.name && f.size === file.size)
        if (!exists) {
          this.files.push(file)
        }
      })
    } else {
      // For single file inputs (like banner), replace the file
      this.files = newFiles.slice(0, 1)
    }

    this.syncInputFiles()
    this.updatePreview()
  }

  syncInputFiles() {
    const dataTransfer = new DataTransfer()
    this.files.forEach(file => {
      dataTransfer.items.add(file)
    })
    this.inputTarget.files = dataTransfer.files
  }

  updatePreview() {
    const preview = this.previewTarget
    const placeholder = this.hasPlaceholderTarget ? this.placeholderTarget : null

    if (this.files.length > 0) {
      preview.innerHTML = ""

      // Header with clear button and count
      const header = document.createElement("div")
      header.className = "preview-header"

      const clearAllBtn = document.createElement("button")
      clearAllBtn.type = "button"
      clearAllBtn.className = "preview-clear-all"
      clearAllBtn.innerHTML = `<i class="fa-solid fa-xmark"></i> ${this.isMultiple ? 'Clear All' : 'Clear'}`
      clearAllBtn.addEventListener("click", () => this.clearAll())
      header.appendChild(clearAllBtn)

      const countLabel = document.createElement("span")
      countLabel.className = "preview-count"
      if (this.isMultiple) {
        countLabel.textContent = `${this.files.length} file${this.files.length > 1 ? 's' : ''} selected`
      } else {
        countLabel.textContent = this.files[0].name.length > 20
          ? this.files[0].name.substring(0, 17) + "..."
          : this.files[0].name
      }
      header.appendChild(countLabel)

      // Add more button (only for multiple file inputs)
      if (this.isMultiple) {
        const addMoreBtn = document.createElement("button")
        addMoreBtn.type = "button"
        addMoreBtn.className = "preview-add-more"
        addMoreBtn.innerHTML = '<i class="fa-solid fa-plus"></i> Add More'
        addMoreBtn.addEventListener("click", () => this.inputTarget.click())
        header.appendChild(addMoreBtn)
      }

      preview.appendChild(header)

      // Preview items container
      const itemsContainer = document.createElement("div")
      itemsContainer.className = "preview-items"

      this.files.forEach((file, index) => {
        if (file.type.startsWith("image/")) {
          this.createImagePreview(file, itemsContainer, index)
        } else if (file.type.startsWith("video/")) {
          this.createVideoPreview(file, itemsContainer, index)
        }
      })

      preview.appendChild(itemsContainer)
      preview.style.display = "block"
      if (placeholder) placeholder.style.display = "none"
    } else {
      preview.style.display = "none"
      preview.innerHTML = ""
      if (placeholder) placeholder.style.display = "flex"
    }
  }

  createImagePreview(file, container, index) {
    const wrapper = document.createElement("div")
    wrapper.className = "preview-item"
    wrapper.dataset.index = index

    // Remove button (only for multiple file inputs)
    if (this.isMultiple) {
      const removeBtn = document.createElement("button")
      removeBtn.type = "button"
      removeBtn.className = "preview-remove-btn"
      removeBtn.innerHTML = '<i class="fa-solid fa-xmark"></i>'
      removeBtn.addEventListener("click", (e) => {
        e.stopPropagation()
        this.removeFile(index)
      })
      wrapper.appendChild(removeBtn)
    }

    // Create thumbnail
    const img = document.createElement("img")
    img.className = "preview-thumbnail"
    img.alt = file.name
    wrapper.appendChild(img)

    const name = document.createElement("span")
    name.className = "preview-filename"
    name.textContent = file.name.length > 12 ? file.name.substring(0, 9) + "..." : file.name
    wrapper.appendChild(name)

    container.appendChild(wrapper)

    // Read file and set image src
    const reader = new FileReader()
    reader.onload = (e) => {
      img.src = e.target.result
    }
    reader.readAsDataURL(file)
  }

  createVideoPreview(file, container, index) {
    const wrapper = document.createElement("div")
    wrapper.className = "preview-item video"
    wrapper.dataset.index = index

    // Remove button (only for multiple file inputs)
    if (this.isMultiple) {
      const removeBtn = document.createElement("button")
      removeBtn.type = "button"
      removeBtn.className = "preview-remove-btn"
      removeBtn.innerHTML = '<i class="fa-solid fa-xmark"></i>'
      removeBtn.addEventListener("click", (e) => {
        e.stopPropagation()
        this.removeFile(index)
      })
      wrapper.appendChild(removeBtn)
    }

    const icon = document.createElement("i")
    icon.className = "fa-solid fa-film"
    wrapper.appendChild(icon)

    const name = document.createElement("span")
    name.className = "preview-filename"
    name.textContent = file.name.length > 12 ? file.name.substring(0, 9) + "..." : file.name
    wrapper.appendChild(name)

    container.appendChild(wrapper)
  }

  removeFile(index) {
    this.files.splice(index, 1)
    this.syncInputFiles()
    this.updatePreview()
  }

  clearAll() {
    this.files = []
    this.syncInputFiles()
    this.updatePreview()
  }
}
