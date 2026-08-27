import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form", "frame", "spinner"]
  static values = { minLength: { type: Number, default: 3 }, delay: { type: Number, default: 300 } }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const length = this.inputTarget.value.trim().length
      if (length === 0 || length >= this.minLengthValue) this.formTarget.requestSubmit()
    }, this.delayValue)
  }

  showSpinner() {
    this.spinnerTarget.classList.remove("hidden")
  }

  onFrameLoad() {
    this.spinnerTarget.classList.add("hidden")
    this.frameTarget.querySelectorAll("details").forEach((details) => { details.open = true })
    this.animateCards()
  }

  animateCards() {
    this.frameTarget.querySelectorAll(".user-card").forEach((card, index) => {
      card.classList.remove("card-filter-in")
      void card.offsetWidth
      card.style.animationDelay = `${Math.min(index, 12) * 25}ms`
      card.classList.add("card-filter-in")
      card.addEventListener("animationend", () => {
        card.classList.remove("card-filter-in")
        card.style.animationDelay = ""
      }, { once: true })
    })
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
