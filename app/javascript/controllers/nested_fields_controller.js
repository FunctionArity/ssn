import { Controller } from "@hotwired/stimulus"

// Adds and removes rows of a nested form (accepts_nested_attributes_for).
// New rows are cloned from a <template> whose field indexes use the placeholder value;
// removing a saved row marks its _destroy field instead of deleting it from the form.
export default class extends Controller {
  static targets = ["template", "container"]
  static values = { placeholder: { type: String, default: "NEW_RECORD" } }

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replaceAll(this.placeholderValue, `${Date.now()}${Math.floor(Math.random() * 1000)}`)
    this.containerTarget.insertAdjacentHTML("beforeend", html)
    this.containerTarget.lastElementChild?.querySelector("input:not([type=hidden])")?.focus()
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest("[data-nested-fields-item]")
    if (!item) return

    const destroyField = item.querySelector(":scope > input[name$='[_destroy]']")
    if (destroyField) {
      destroyField.value = "1"
      item.hidden = true
    } else {
      item.remove()
    }
  }
}
