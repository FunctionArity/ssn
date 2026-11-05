import { Controller } from "@hotwired/stimulus"

// Shows and hides a section. Its markup waits in a <template> until the first time it's shown,
// so heavy content like a map only loads when someone asks for it.
export default class extends Controller {
  static targets = ["content", "template"]

  toggle(event) {
    const expanded = this.contentTarget.hidden

    if (expanded && this.hasTemplateTarget) {
      this.contentTarget.append(this.templateTarget.content.cloneNode(true))
      this.templateTarget.remove()
    }

    this.contentTarget.hidden = !expanded
    event.currentTarget.setAttribute("aria-expanded", expanded)
  }
}
