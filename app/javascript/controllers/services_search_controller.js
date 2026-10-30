import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "frame", "input", "clear", "spinner", "results", "filters", "prompt", "toggle", "guard"]
  static values = { delay: { type: Number, default: 300 } }

  search() {
    this.updateFiltersState()
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.formTarget.requestSubmit(), this.delayValue)
  }

  clear() {
    clearTimeout(this.timeout)
    this.inputTargets.forEach((input) => { input.value = "" })
    this.updateFiltersState()
    this.formTarget.requestSubmit()
  }

  toggleFilters() {
    const button = this.toggleTarget
    const opening = !this.filtersOpen
    const label = opening ? button.dataset.hideLabel : button.dataset.showLabel

    button.setAttribute("aria-expanded", opening)
    button.setAttribute("aria-label", label)
    button.title = label

    this.animateVisibility(this.filtersTarget, !opening)
    this.guardTargets.forEach((guard) => this.animateVisibility(guard, opening))
  }

  // The guard section is re-rendered with the frame, for example after clearing the filters.
  guardTargetConnected(guard) {
    guard.hidden = this.filtersOpen
  }

  get filtersOpen() {
    return this.toggleTarget.getAttribute("aria-expanded") === "true"
  }

  animateVisibility(element, hiding) {
    element.getAnimations().forEach((animation) => animation.cancel())
    element.hidden = false

    const open = { height: `${element.offsetHeight}px`, opacity: 1, overflow: "hidden" }
    const closed = { height: "0px", opacity: 0, overflow: "hidden" }
    const animation = element.animate(hiding ? [open, closed] : [closed, open], { duration: 350, easing: "cubic-bezier(0.4, 0, 0.2, 1)" })

    // A click during the animation cancels it, and that animation must no longer hide the element.
    if (hiding) animation.onfinish = () => { if (animation.playState === "finished") element.hidden = true }
  }

  updateFiltersState() {
    const empty = this.inputTargets.every((input) => input.value.trim().length === 0)
    this.clearTarget.classList.toggle("hidden", empty)
    this.promptTarget.classList.toggle("hidden", !empty)
  }

  // Requests started by the cards inside the frame (complete, prefetch) must not show the spinner.
  showSpinner(event) {
    if (event.target !== this.formTarget && event.target !== this.frameTarget) return

    this.resultsTarget.classList.add("hidden")
    this.spinnerTarget.classList.remove("hidden")
  }

  // A successful load replaces the frame, which removes the spinner along with it.
  hideSpinner() {
    this.spinnerTarget.classList.add("hidden")
    this.resultsTarget.classList.remove("hidden")
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
