import { Controller } from "@hotwired/stimulus"

// Marks the element the URL's #anchor points to, e.g. the comment a mention email or notification links to,
// and scrolls it into view. CSS :target alone misses Turbo visits, which change the URL without a real jump.
export default class extends Controller {
  connect() {
    this.highlight()
  }

  highlight() {
    const id = decodeURIComponent(window.location.hash.slice(1))
    if (!id) return

    const element = this.element.querySelector(`#${CSS.escape(id)}`)
    if (!element) return

    this.element.querySelectorAll(".anchor-highlight").forEach((marked) => marked.classList.remove("anchor-highlight"))
    // Restart the animation when the same anchor is opened again.
    void element.offsetWidth
    element.classList.add("anchor-highlight")
    element.scrollIntoView({ behavior: "smooth", block: "center" })
  }
}
