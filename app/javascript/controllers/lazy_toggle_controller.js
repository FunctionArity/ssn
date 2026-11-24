import { Controller } from "@hotwired/stimulus"

// Shows and hides a section, animating its height so the change reads as an expand/collapse rather than a snap.
// Its markup waits in a <template> until the first time it's shown, so heavy content like a map only loads
// when someone asks for it.
export default class extends Controller {
  static targets = ["content", "template"]
  static values = { duration: { type: Number, default: 250 } }

  toggle(event) {
    // When the whole section is the click target, a link inside it (e.g. a mentioned user's name)
    // should navigate instead of toggling.
    if (event.target.closest("a")) return
    event.preventDefault()

    const expanding = this.contentTarget.hidden

    if (expanding && this.hasTemplateTarget) {
      this.contentTarget.append(this.templateTarget.content.cloneNode(true))
      this.templateTarget.remove()
    }

    event.currentTarget.setAttribute("aria-expanded", expanding)
    expanding ? this.#expand() : this.#collapse()
  }

  #expand() {
    const content = this.contentTarget
    content.style.overflow = "hidden"
    content.hidden = false
    const height = content.scrollHeight

    content.animate(
      [ { height: "0px", opacity: 0 }, { height: `${height}px`, opacity: 1 } ],
      { duration: this.durationValue, easing: "cubic-bezier(0.4, 0, 0.2, 1)" }
    )
  }

  #collapse() {
    const content = this.contentTarget
    const height = content.scrollHeight

    const animation = content.animate(
      [ { height: `${height}px`, opacity: 1 }, { height: "0px", opacity: 0 } ],
      { duration: this.durationValue, easing: "cubic-bezier(0.4, 0, 0.2, 1)" }
    )
    animation.onfinish = () => { content.hidden = true }
  }
}
