import { Controller } from "@hotwired/stimulus"

// Starts a reply to a comment: links the new comment to it, fills the conversation's editor with the comment's
// mentions and focuses it. Cancelling makes it a top-level comment again.
export default class extends Controller {
  static targets = ["form", "parent", "replying", "author"]

  reply({ params: { body, parentId, author } }) {
    const editor = this.formTarget.querySelector("lexxy-editor")
    if (!editor) return

    this.parentTarget.value = parentId
    this.authorTarget.textContent = author
    this.replyingTarget.hidden = false

    editor.value = body
    this.formTarget.scrollIntoView({ behavior: "smooth", block: "center" })
    editor.focus()
  }

  cancel() {
    this.parentTarget.value = ""
    this.replyingTarget.hidden = true
  }
}
