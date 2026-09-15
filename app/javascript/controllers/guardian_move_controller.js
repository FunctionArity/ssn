import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["pill", "dropzone"]

  dragStart(event) {
    this.draggedId = event.currentTarget.dataset.guardianId
    this.sourceGuardSetupId = event.currentTarget.dataset.sourceGuardSetupId
    event.dataTransfer.setData("text/plain", this.draggedId)
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setDragImage(event.currentTarget, event.offsetX, event.offsetY)
    event.currentTarget.classList.add("opacity-50")
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("opacity-50")
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    event.currentTarget.classList.add("ring-2", "ring-indigo-400")
  }

  dragLeave(event) {
    event.currentTarget.classList.remove("ring-2", "ring-indigo-400")
  }

  drop(event) {
    event.preventDefault()
    event.currentTarget.classList.remove("ring-2", "ring-indigo-400")

    const dropzone = event.currentTarget
    const guardianId = event.dataTransfer.getData("text/plain")
    const guardSetupId = dropzone.dataset.guardSetupId
    if (!guardianId || guardSetupId === this.sourceGuardSetupId) return

    this.#submit(guardSetupId, guardianId)
  }

  #submit(guardSetupId, guardianId) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(`/guard_setups/${guardSetupId}/move_guardian`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html",
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: `user_id=${guardianId}`
    })
      .then((response) => response.text())
      .then((html) => Turbo.renderStreamMessage(html))
  }
}
