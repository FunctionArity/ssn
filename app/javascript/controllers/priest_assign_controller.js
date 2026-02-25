import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dragStart(event) {
    this.draggedPriestId = event.currentTarget.dataset.priestId
    event.dataTransfer.setData("text/plain", this.draggedPriestId)
    event.dataTransfer.effectAllowed = "move"
    event.currentTarget.classList.add("opacity-50")
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("opacity-50")
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    event.currentTarget.classList.add("ring-4", "ring-purple-500", "ring-inset", "bg-purple-50")
  }

  dragLeave(event) {
    if (!event.currentTarget.contains(event.relatedTarget)) {
      event.currentTarget.classList.remove("ring-4", "ring-purple-500", "ring-inset", "bg-purple-50")
    }
  }

  drop(event) {
    event.preventDefault()
    event.currentTarget.classList.remove("ring-4", "ring-purple-500", "ring-inset", "bg-purple-50")

    const priestId = event.dataTransfer.getData("text/plain")
    const weekNumber = event.currentTarget.dataset.weekNumber
    const dayOfWeek = event.currentTarget.dataset.dayOfWeek

    document.getElementById("form_priest_id").value = priestId
    document.getElementById("form_week_number").value = weekNumber
    document.getElementById("form_day_of_week").value = dayOfWeek

    document.getElementById("priest-assign-form").submit()
  }
}
