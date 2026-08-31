import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const FACETS = ["country", "state", "city"]

export default class extends Controller {
  static targets = ["card", "panel", "badge", "checkbox", "count", "empty"]

  connect() {
    this.outsideClick = (event) => {
      if (!this.element.contains(event.target)) this.closePanels()
    }
    document.addEventListener("click", this.outsideClick)
    this.filter()
    this.ready = true
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClick)
  }

  toggle(event) {
    const facet = event.params.facet
    this.panelTargets.forEach((panel) => {
      panel.classList.toggle("hidden", panel.dataset.facet !== facet || !panel.classList.contains("hidden"))
    })
  }

  closePanels() {
    this.panelTargets.forEach((panel) => panel.classList.add("hidden"))
  }

  select() {
    this.closePanels()
    this.filter()
  }

  clear() {
    this.checkboxTargets.forEach((checkbox) => { checkbox.checked = false })
    this.closePanels()
    this.filter()
  }

  visit(event) {
    if (event.target.closest("a")) return
    Turbo.visit(event.params.url)
  }

  filter() {
    const selected = {}
    FACETS.forEach((facet) => {
      selected[facet] = this.checkboxTargets
        .filter((checkbox) => checkbox.dataset.facet === facet && checkbox.checked)
        .map((checkbox) => checkbox.value)
    })

    let visible = 0
    let revealIndex = 0
    this.cardTargets.forEach((card) => {
      const show = FACETS.every((facet) =>
        selected[facet].length === 0 || selected[facet].includes(card.dataset[facet])
      )

      if (show) {
        if (card.classList.contains("hidden")) this.reveal(card, revealIndex)
        revealIndex++
        visible++
      } else if (!card.classList.contains("hidden")) {
        this.conceal(card)
      }
    })

    if (this.ready && this.countTarget.textContent !== String(visible)) this.pulse(this.countTarget)
    this.countTarget.textContent = visible

    const showingEmpty = visible === 0
    if (showingEmpty && this.emptyTarget.classList.contains("hidden") && this.ready) {
      this.reveal(this.emptyTarget)
    }
    this.emptyTarget.classList.toggle("hidden", !showingEmpty)

    this.badgeTargets.forEach((badge) => {
      const count = selected[badge.dataset.facet].length
      badge.textContent = count
      badge.classList.toggle("hidden", count === 0)
    })
  }

  reveal(element, index = 0) {
    element.classList.remove("hidden", "card-filter-out")
    element.style.animationDelay = `${Math.min(index, 8) * 25}ms`
    element.classList.add("card-filter-in")
    element.addEventListener("animationend", () => {
      element.classList.remove("card-filter-in")
      element.style.animationDelay = ""
    }, { once: true })
  }

  conceal(element) {
    element.classList.remove("card-filter-in")
    element.classList.add("card-filter-out")
    element.addEventListener("animationend", () => {
      element.classList.add("hidden")
      element.classList.remove("card-filter-out")
    }, { once: true })
  }

  pulse(element) {
    element.classList.remove("count-pulse")
    void element.offsetWidth
    element.classList.add("count-pulse")
  }
}
