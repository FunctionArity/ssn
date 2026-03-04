import { Controller } from "@hotwired/stimulus"

const ROLE_STYLES = {
  guardian: { bg: "bg-green-50",  ring: "ring-green-600/20",  text: "text-green-700"  },
  vocal:    { bg: "bg-red-50",    ring: "ring-red-600/10",    text: "text-red-700"    },
  priest:   { bg: "bg-purple-50", ring: "ring-purple-700/10", text: "text-purple-700" }
}

const ALL_BG   = ["bg-green-50",  "bg-red-50",    "bg-purple-50"]
const ALL_RING = ["ring-green-600/20", "ring-red-600/10", "ring-purple-700/10"]
const ALL_TEXT = ["text-green-700", "text-red-700", "text-purple-700"]

export default class extends Controller {
  static targets = ["pill", "label"]

  connect() {
    const checked = this.element.querySelector("input:checked")
    if (checked) {
      const label = checked.closest("[data-role-selector-target='label']")
      this.pillTarget.style.transition = "none"
      this.update(label)
      requestAnimationFrame(() => { this.pillTarget.style.transition = "" })
    }
  }

  change(event) {
    this.update(event.target.closest("[data-role-selector-target='label']"))
  }

  update(label) {
    const role = label.dataset.role
    const styles = ROLE_STYLES[role]

    this.pillTarget.style.left  = label.offsetLeft + "px"
    this.pillTarget.style.width = label.offsetWidth + "px"

    this.pillTarget.classList.remove(...ALL_BG, ...ALL_RING)
    this.pillTarget.classList.add(styles.bg, styles.ring)

    this.labelTargets.forEach(l => l.classList.remove(...ALL_TEXT))
    label.classList.add(styles.text)
  }
}
