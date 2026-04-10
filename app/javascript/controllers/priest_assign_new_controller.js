import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.selectedPriestId = null
    this.sourceSetupId = null
  }

  // ── Click-based assignment ────────────────────────────────────────────────

  selectPriest(event) {
    const chip = event.currentTarget
    const priestId = chip.dataset.priestId

    if (this.selectedPriestId === priestId) {
      this.clearSelection()
    } else {
      this.clearSelection()
      this.selectedPriestId = priestId
      chip.classList.add("ring-2", "ring-inset", "ring-purple-500", "bg-purple-200", "border-purple-400")
      chip.classList.remove("bg-purple-50", "border-purple-200")
    }
  }

  assignCell(event) {
    if (!this.selectedPriestId) return

    const cell = event.currentTarget
    if (cell.dataset.hasAssignment === "true") return

    this.#submit(this.selectedPriestId, cell.dataset.weekNumber, cell.dataset.dayOfWeek, null)
  }

  clearSelection() {
    this.selectedPriestId = null
    this.element.querySelectorAll("[data-priest-chip]").forEach(el => {
      el.classList.remove("ring-2", "ring-inset", "ring-purple-500", "bg-purple-200", "border-purple-400")
      el.classList.add("bg-purple-50", "border-purple-200")
    })
  }

  // ── Drag & drop ───────────────────────────────────────────────────────────

  dragStart(event) {
    this.draggedPriestId = event.currentTarget.dataset.priestId
    this.sourceSetupId = event.currentTarget.dataset.sourceSetupId || ""
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
    const cell = event.currentTarget
    this.#submit(priestId, cell.dataset.weekNumber, cell.dataset.dayOfWeek, this.sourceSetupId)
  }

  // ── Private ───────────────────────────────────────────────────────────────

  #submit(priestId, weekNumber, dayOfWeek, sourceSetupId) {
    document.getElementById("new-form-priest-id").value = priestId
    document.getElementById("new-form-week-number").value = weekNumber
    document.getElementById("new-form-day-of-week").value = dayOfWeek
    document.getElementById("new-form-source-setup-id").value = sourceSetupId || ""
    document.getElementById("priest-assign-new-form").requestSubmit()
    this.clearSelection()
  }
}
