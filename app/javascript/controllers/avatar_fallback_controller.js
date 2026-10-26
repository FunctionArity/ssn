import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "placeholder"]

  connect() {
    // The image may have already failed before the controller connected
    if (this.imageTarget.complete && this.imageTarget.naturalWidth === 0) this.fallback()
  }

  fallback() {
    this.imageTarget.classList.add("hidden")
    this.placeholderTarget.classList.replace("hidden", "flex")
  }
}
