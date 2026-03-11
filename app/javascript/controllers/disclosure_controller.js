import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  toggle(event) {
    event.preventDefault()
    const details = this.element
    const content = this.contentTarget

    const easing = "cubic-bezier(0.4, 0, 0.2, 1)"
    const duration = 350

    if (details.open) {
      const animation = content.animate(
        [{ height: content.offsetHeight + "px", opacity: 1 }, { height: "0px", opacity: 0 }],
        { duration, easing }
      )
      animation.onfinish = () => { details.open = false }
    } else {
      details.open = true
      const height = content.offsetHeight + "px"
      content.animate(
        [{ height: "0px", opacity: 0 }, { height, opacity: 1 }],
        { duration, easing }
      )
    }
  }
}
