import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._onVisit = this.close.bind(this)
    document.addEventListener("turbo:visit", this._onVisit)
  }

  disconnect() {
    document.removeEventListener("turbo:visit", this._onVisit)
  }

  toggle() {
    document.body.classList.toggle("mobile-nav-open")
  }

  close() {
    document.body.classList.remove("mobile-nav-open")
  }
}
