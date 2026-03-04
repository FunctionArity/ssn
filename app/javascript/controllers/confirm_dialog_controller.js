import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "message"]

  connect() {
    // Register this controller instance globally so Turbo can call it
    window.confirmDialogController = this
  }

  open(message) {
    return new Promise((resolve) => {
      this._resolve = resolve
      this.messageTarget.textContent = message
      this.dialogTarget.classList.remove("hidden")
      this.dialogTarget.classList.add("flex")
    })
  }

  confirm() {
    this._close()
    this._resolve?.(true)
  }

  cancel() {
    this._close()
    this._resolve?.(false)
  }

  backdropClick(event) {
    if (event.target === this.dialogTarget) {
      this.cancel()
    }
  }

  _close() {
    this.dialogTarget.classList.add("hidden")
    this.dialogTarget.classList.remove("flex")
  }
}
