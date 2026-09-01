import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["row"]
  static values = { context: { type: String, default: "guard_show" } }

  dragStart(event) {
    this.draggedId = event.currentTarget.dataset.serviceId
    event.dataTransfer.setData("text/plain", this.draggedId)
    event.dataTransfer.effectAllowed = "move"
    event.currentTarget.classList.add("opacity-50")
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("opacity-50")
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    event.currentTarget.classList.add("bg-indigo-50")
  }

  dragLeave(event) {
    event.currentTarget.classList.remove("bg-indigo-50")
  }

  drop(event) {
    event.preventDefault()
    event.currentTarget.classList.remove("bg-indigo-50")

    const targetRow = event.currentTarget
    const draggedId = event.dataTransfer.getData("text/plain")
    if (!draggedId || draggedId === targetRow.dataset.serviceId) return

    const position = this.rowTargets.indexOf(targetRow) + 1
    this.#submit(draggedId, position)
  }

  #submit(serviceId, position) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(`/services/${serviceId}/move`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html",
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: `position=${position}&context=${this.contextValue}`
    })
      .then((response) => response.text())
      .then((html) => Turbo.renderStreamMessage(html))
  }
}
