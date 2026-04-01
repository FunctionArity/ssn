import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label", "select"]

  change(event) {
    event.preventDefault()
    document.removeEventListener("click", this._outsideHandler) // clear any stale handler
    this.labelTarget.classList.add("hidden")
    this.selectTarget.classList.remove("hidden")
    this.selectTarget.querySelector("select").focus()
    this._outsideHandler = this._handleOutsideClick.bind(this)
    document.addEventListener("click", this._outsideHandler)
  }

  _handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.selectTarget.classList.add("hidden")
      this.labelTarget.classList.remove("hidden")
      document.removeEventListener("click", this._outsideHandler)
    }
  }

  disconnect() {
    document.removeEventListener("click", this._outsideHandler)
  }
}
