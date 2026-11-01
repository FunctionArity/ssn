import { Controller } from "@hotwired/stimulus"

// Mentions are plain links in the comment HTML, so they are found by their href.
const MENTION_HREF = /^\/users\/\d+$/
const GAP = 6

export default class extends Controller {
  static targets = ["panel", "frame", "loading"]
  static values = { showDelay: { type: Number, default: 200 }, hideDelay: { type: Number, default: 150 } }

  disconnect() {
    this.hide()
  }

  show(event) {
    const link = this.mentionLink(event.target)
    if (!link) return

    this.cancelHide()
    clearTimeout(this.showTimeout)
    this.showTimeout = setTimeout(() => this.open(link), this.showDelayValue)
  }

  leave(event) {
    if (this.mentionLink(event.target)) this.scheduleHide()
  }

  // The delay lets the pointer travel from the link to the popover.
  scheduleHide() {
    clearTimeout(this.showTimeout)
    this.cancelHide()
    this.hideTimeout = setTimeout(() => this.hide(), this.hideDelayValue)
  }

  cancelHide() {
    clearTimeout(this.hideTimeout)
  }

  hide() {
    clearTimeout(this.showTimeout)
    this.cancelHide()
    if (this.panelTarget.matches(":popover-open")) this.panelTarget.hidePopover()
  }

  // The popover renders in the top layer, so it isn't clipped or offset by the ancestors of the comment.
  open(link) {
    this.link = link
    // Turbo rewrites the src of the frame as an absolute URL.
    const url = `${link.href}/card`

    if (this.frameTarget.src !== url) {
      this.frameTarget.innerHTML = this.loadingTarget.innerHTML
      this.frameTarget.setAttribute("src", url)
    }

    if (!this.panelTarget.matches(":popover-open")) this.panelTarget.showPopover()
    this.position()
  }

  // Runs again when the card loads, since it is taller than the spinner.
  position() {
    if (!this.link || !this.panelTarget.matches(":popover-open")) return

    const link = this.link.getBoundingClientRect()
    const panel = this.panelTarget.getBoundingClientRect()
    const fitsBelow = link.bottom + GAP + panel.height <= window.innerHeight
    const left = Math.min(link.left, document.documentElement.clientWidth - panel.width - GAP)

    this.panelTarget.style.left = `${Math.max(GAP, left)}px`
    this.panelTarget.style.top = `${fitsBelow ? link.bottom + GAP : Math.max(GAP, link.top - GAP - panel.height)}px`
  }

  // A deleted user or an expired session answers without the frame, and there is nothing to show.
  loadFailed(event) {
    event.preventDefault()
    this.frameTarget.removeAttribute("src")
    this.hide()
  }

  mentionLink(element) {
    const link = element.closest?.("a[href]")
    return link && !this.panelTarget.contains(link) && MENTION_HREF.test(link.getAttribute("href")) ? link : null
  }
}
