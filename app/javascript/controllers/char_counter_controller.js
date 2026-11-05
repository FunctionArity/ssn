import { Controller } from "@hotwired/stimulus"

// Shows how many characters of visible text are left in a Lexxy editor. It turns red under 10% left,
// and when the text is too long the form can't be submitted.
export default class extends Controller {
  static targets = ["editor", "output"]
  static values = { max: Number, remaining: Object, over: Object }

  connect() {
    this.update()
  }

  update() {
    // Until Lexxy initializes, the element has no text of its own (it updates again on lexxy:initialize).
    const text = this.editorTarget.editor ? this.editorTarget.toString() ?? "" : ""
    const left = this.maxValue - text.length
    const messages = left < 0 ? this.overValue : this.remainingValue
    const count = Math.abs(left)

    this.outputTarget.textContent = (count === 1 ? messages.one : messages.other).replace("%{count}", count.toLocaleString(document.documentElement.lang || undefined))
    this.outputTarget.classList.toggle("text-red-600", left < this.maxValue * 0.1)
    this.outputTarget.classList.toggle("font-semibold", left < 0)
    this.outputTarget.classList.toggle("text-gray-400", left >= this.maxValue * 0.1)

    this.element.closest("form")?.querySelectorAll("[type=submit]").forEach((button) => { button.disabled = left < 0 })
  }
}
