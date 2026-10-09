import { Controller } from "@hotwired/stimulus"

// Highlights the table-of-contents link of the section currently in view,
// and smooth-scrolls to a section when its link is clicked.
export default class extends Controller {
  static targets = ["link"]
  static classes = ["active"]
  static values = { offset: { type: Number, default: 120 } }

  connect() {
    this.sections = this.linkTargets
      .map((link) => document.getElementById(link.hash.slice(1)))
      .filter(Boolean)
    this.onScroll = () => this.update()
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  jump(event) {
    const section = document.getElementById(event.currentTarget.hash.slice(1))
    if (!section) return

    event.preventDefault()
    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    section.scrollIntoView({ behavior: reduceMotion ? "auto" : "smooth", block: "start" })
    history.replaceState(null, "", `#${section.id}`)
  }

  update() {
    const atBottom = window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2
    let current = atBottom ? this.sections[this.sections.length - 1] : null

    if (!current) {
      for (const section of this.sections) {
        if (section.getBoundingClientRect().top <= this.offsetValue) current = section
      }
    }

    this.linkTargets.forEach((link) => {
      const active = Boolean(current) && link.hash === `#${current.id}`
      this.activeClasses.forEach((name) => link.classList.toggle(name, active))
      if (active) link.setAttribute("aria-current", "location")
      else link.removeAttribute("aria-current")
    })
  }
}
