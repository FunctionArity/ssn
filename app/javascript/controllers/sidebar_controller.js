import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "sidebar-collapsed"

export default class extends Controller {
  static targets = ["icon"]

  connect() {
    if (localStorage.getItem(STORAGE_KEY) === "true") {
      document.body.classList.add("sidebar-collapsed")
    }
    this.updateIcon()
  }

  toggle() {
    const collapsed = document.body.classList.toggle("sidebar-collapsed")
    localStorage.setItem(STORAGE_KEY, collapsed)
    this.updateIcon()
  }

  updateIcon() {
    if (!this.hasIconTarget) return

    const collapsed = document.body.classList.contains("sidebar-collapsed")
    this.iconTarget.classList.toggle("ph-caret-line-right", collapsed)
    this.iconTarget.classList.toggle("ph-caret-line-left", !collapsed)
  }
}
