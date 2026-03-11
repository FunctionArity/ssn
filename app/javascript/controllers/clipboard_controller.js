import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }
  static targets = ["icon"]

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      this.iconTarget.className = "ph ph-check text-green-500"
      setTimeout(() => {
        this.iconTarget.className = "ph ph-copy"
      }, 2000)
    })
  }
}
