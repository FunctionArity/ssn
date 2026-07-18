import { Controller } from "@hotwired/stimulus"

const FACETS = ["country", "state", "city"]

export default class extends Controller {
  static targets = ["card", "panel", "badge", "checkbox", "count", "empty"]

  connect() {
    this.outsideClick = (event) => {
      if (!this.element.contains(event.target)) this.closePanels()
    }
    document.addEventListener("click", this.outsideClick)
    this.filter()
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

  clear() {
    this.checkboxTargets.forEach((checkbox) => { checkbox.checked = false })
    this.closePanels()
    this.filter()
  }

  filter() {
    const selected = {}
    FACETS.forEach((facet) => {
      selected[facet] = this.checkboxTargets
        .filter((checkbox) => checkbox.dataset.facet === facet && checkbox.checked)
        .map((checkbox) => checkbox.value)
    })

    let visible = 0
    this.cardTargets.forEach((card) => {
      const show = FACETS.every((facet) =>
        selected[facet].length === 0 || selected[facet].includes(card.dataset[facet])
      )
      card.classList.toggle("hidden", !show)
      if (show) visible++
    })

    this.countTarget.textContent = visible
    this.emptyTarget.classList.toggle("hidden", visible !== 0)

    this.badgeTargets.forEach((badge) => {
      const count = selected[badge.dataset.facet].length
      badge.textContent = count
      badge.classList.toggle("hidden", count === 0)
    })
  }
}
