import { Controller } from "@hotwired/stimulus"

// Starts a reply to a comment: fills the conversation's editor with the comment's mentions and focuses it.
export default class extends Controller {
  static targets = ["form"]

  reply({ params: { body } }) {
    const editor = this.formTarget.querySelector("lexxy-editor")
    if (!editor) return

    editor.value = body
    this.formTarget.scrollIntoView({ behavior: "smooth", block: "center" })
    editor.focus()
  }
}
