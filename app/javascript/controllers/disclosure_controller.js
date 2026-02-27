import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  toggle(event) {
    event.preventDefault()
    const details = this.element
    const content = this.contentTarget

    if (details.open) {
      const animation = content.animate(
        [{ height: content.offsetHeight + "px" }, { height: "0px" }],
        { duration: 200, easing: "ease-out" }
      )
      animation.onfinish = () => { details.open = false }
    } else {
      details.open = true
      const height = content.offsetHeight + "px"
      content.animate(
        [{ height: "0px" }, { height }],
        { duration: 200, easing: "ease-out" }
      )
    }
  }
}
