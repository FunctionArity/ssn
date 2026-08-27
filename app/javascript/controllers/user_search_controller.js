import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form", "frame"]
  static values = { minLength: { type: Number, default: 3 }, delay: { type: Number, default: 300 } }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const length = this.inputTarget.value.trim().length
      if (length === 0 || length >= this.minLengthValue) this.formTarget.requestSubmit()
    }, this.delayValue)
  }

  expandResults() {
    this.frameTarget.querySelectorAll("details").forEach((details) => { details.open = true })
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
