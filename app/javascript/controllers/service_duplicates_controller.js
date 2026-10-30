import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button", "spinner", "modal", "frame"]
  static values = { url: String, minLength: { type: Number, default: 3 }, delay: { type: Number, default: 300 } }

  // The name is already filled in when the form comes back with validation errors.
  connect() {
    this.lookup()
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.lookup(), this.delayValue)
  }

  lookup() {
    const name = this.inputTarget.value.trim()

    if (name.length < this.minLengthValue) {
      this.frameTarget.removeAttribute("src")
      this.frameTarget.innerHTML = ""
      this.buttonTarget.classList.add("hidden")
      this.spinnerTarget.classList.add("hidden")
      return
    }

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("full_name", name)
    this.frameTarget.src = url.pathname + url.search
  }

  lookupStarted(event) {
    if (event.target !== this.frameTarget) return

    this.buttonTarget.classList.add("hidden")
    this.spinnerTarget.classList.remove("hidden")
  }

  // The src check drops a response that lands after the name was cleared.
  frameLoaded() {
    const found = this.frameTarget.hasAttribute("src") && this.frameTarget.childElementCount > 0
    this.spinnerTarget.classList.add("hidden")
    this.buttonTarget.classList.toggle("hidden", !found)
  }

  // preventDefault stops Turbo from leaving the page, which would lose the unsaved form.
  lookupFailed(event) {
    event.preventDefault()
    this.spinnerTarget.classList.add("hidden")
  }

  open() {
    this.modalTarget.showModal()
  }

  close() {
    this.modalTarget.close()
  }

  // Clicks on the backdrop land on the dialog itself; its content fills the rest.
  backdropClick(event) {
    if (event.target === this.modalTarget) this.close()
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
