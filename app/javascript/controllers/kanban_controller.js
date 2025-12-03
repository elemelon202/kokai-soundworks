import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="kanban"
export default class extends Controller {
  static targets = ["card", "column"]
  static values = { bandId: Number }

  connect() {
    this.draggedCard = null
  }

  dragStart(event) {
    this.draggedCard = event.currentTarget
    event.currentTarget.classList.add("dragging")
    event.dataTransfer.effectAllowed = "move"
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("dragging")
    this.columnTargets.forEach(col => col.classList.remove("drag-over"))
  }

  dragOver(event) {
    event.preventDefault()
    event.currentTarget.classList.add("drag-over")
  }

   dragLeave(event) {
    event.currentTarget.classList.remove("drag-over")
  }

  drop(event) {
    event.preventDefault()
    const column = event.currentTarget
    column.classList.remove("drag-over")

    if(!this.draggedCard) return

    const taskId = this.draggedCard.dataset.taskId
    const newStatus = column.dataset.status

    this.updateTaskStatus(taskId, newStatus)
  }
  async updateTaskStatus(taskId, status) {
      const response = await fetch(`/bands/${this.bandIdValue}/tasks/${taskId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        },
        body: JSON.stringify({ kanban_task: { status: status } })
      })

      if (response.ok) {
        window.location.reload()
      }
    }

}
