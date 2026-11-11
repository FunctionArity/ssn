import { Controller } from "@hotwired/stimulus"

// Google One Tap: offers signed out visitors who have a Google session in the browser to sign in as that
// account. The token Google returns is posted with this form, which the server checks before signing in.
// Google's script only loads on pages that use this.
const SCRIPT_URL = "https://accounts.google.com/gsi/client"
let scriptLoad

function loadScript() {
  scriptLoad ||= new Promise((resolve, reject) => {
    const script = document.createElement("script")
    script.src = SCRIPT_URL
    script.async = true
    script.onload = resolve
    script.onerror = () => {
      scriptLoad = null
      reject(new Error("Google Identity Services didn't load"))
    }
    document.head.append(script)
  })
  return scriptLoad
}

export default class extends Controller {
  static targets = ["credential"]
  static values = { clientId: String }

  async connect() {
    try {
      await loadScript()
    } catch (error) {
      console.warn(error.message)
      return
    }
    // The visitor may have left the page while the script loaded.
    if (!this.element.isConnected) return

    google.accounts.id.initialize({
      client_id: this.clientIdValue,
      callback: ({ credential }) => this.signIn(credential),
      context: "signin",
      use_fedcm_for_prompt: true,
      cancel_on_tap_outside: false,
      itp_support: true
    })
    google.accounts.id.prompt()
  }

  disconnect() {
    window.google?.accounts.id.cancel()
  }

  signIn(credential) {
    debugger
    this.credentialTarget.value = credential
    this.element.requestSubmit()
  }
}
