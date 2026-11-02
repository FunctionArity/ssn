import { Controller } from "@hotwired/stimulus"

// Marks an unread comment as read when the user clicks it. The response replaces the comment
// and the unread count in the top nav.
export default class extends Controller {
  static values = { url: String }

  read(event) {
    // Links and forms inside the comment, like a mention or delete, keep their own behavior. Replying marks it read too.
    if (this.sent || event.target.closest("a, form")) return
    this.sent = true

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
      .then((response) => response.text())
      .then((html) => Turbo.renderStreamMessage(html))
      .catch(() => { this.sent = false })
  }
}
