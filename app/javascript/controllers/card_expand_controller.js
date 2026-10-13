import { Controller } from "@hotwired/stimulus"

// Shows a grid of compact cards where one card at a time can be expanded to full width.
// Each card gets data-state="idle" (nothing open), "expanded" (the open card) or "collapsed" (the others),
// which the markup styles with Tailwind data-* variants. Changes are animated with the View Transitions API
// when the browser supports it and the user has not asked for reduced motion.
export default class extends Controller {
  static targets = ["card"]

  connect() {
    this.onKeydown = (event) => { if (event.key === "Escape" && this.openCard) this.collapse() }
    document.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKeydown)
  }

  toggle(event) {
    const card = event.currentTarget.closest("[data-card-expand-target='card']")
    this.show(card === this.openCard ? null : card)
  }

  collapse() {
    this.show(null)
  }

  // openCard is updated right away, so a second click during the animation toggles from the intended state.
  show(card) {
    this.openCard = card
    this.transition(() => this.apply(card))
  }

  apply(expanded) {
    this.cardTargets.forEach((card) => {
      card.dataset.state = !expanded ? "idle" : card === expanded ? "expanded" : "collapsed"
      card.querySelector("[aria-expanded]")?.setAttribute("aria-expanded", card === expanded)
      const details = card.querySelector("[data-card-expand-details]")
      if (details) details.hidden = card !== expanded
    })
  }

  transition(update) {
    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (!document.startViewTransition || reduceMotion) return update()

    this.viewTransition?.skipTransition()
    const viewTransition = document.startViewTransition(update)
    this.viewTransition = viewTransition
    viewTransition.finished.then(() => {
      if (this.viewTransition !== viewTransition) return
      this.viewTransition = null
      this.openCard?.scrollIntoView({ block: "nearest", behavior: "smooth" })
    })
  }
}
