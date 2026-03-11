import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  reload(event) {
    const date = event.target.value
    if (!date) return

    const frame = document.querySelector("turbo-frame#guard_form")
    if (frame) frame.src = `${this.urlValue}?due_date=${date}`
  }
}
