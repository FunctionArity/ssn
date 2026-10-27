import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String, source: String }
  static targets = ["icon"]

  copy() {
    navigator.clipboard.writeText(this.text).then(() => {
      this.iconTarget.className = "ph ph-check text-green-500"
      setTimeout(() => {
        this.iconTarget.className = "ph ph-copy"
      }, 2000)
    })
  }

  // With a source, the text is read at click time from that element's data-copy-text,
  // so it stays current when the element is replaced by a Turbo broadcast.
  get text() {
    if (!this.hasSourceValue) return this.textValue
    return document.getElementById(this.sourceValue)?.dataset.copyText ?? ""
  }
}
