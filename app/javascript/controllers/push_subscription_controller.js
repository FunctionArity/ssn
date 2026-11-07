import { Controller } from "@hotwired/stimulus"

// Turns push notifications on or off in this browser or phone. The service worker shows them
// (app/views/pwa/service-worker.js) and the server keeps one PushSubscription per device.
// Shows one target at a time: off, on, blocked, or install (iPhone outside the Home Screen app).
export default class extends Controller {
  static targets = ["off", "on", "blocked", "install"]
  static values = { publicKey: String, url: String }

  async connect() {
    if (!this.supported) return this.show(this.iphoneInBrowser ? "install" : null)
    if (Notification.permission === "denied") return this.show("blocked")

    this.registration = await navigator.serviceWorker.register("/service-worker.js", { scope: "/" })
    const subscription = await this.registration.pushManager.getSubscription()

    if (subscription) {
      // Saved again on each visit, in case the server dropped it or someone else signed in here.
      this.save(subscription)
      this.show("on")
    } else {
      this.show("off")
    }
  }

  async enable() {
    try {
      // subscribe() asks for permission itself. Safari only allows it right from the click,
      // so nothing is awaited before it (waiting for a separate permission prompt fails there).
      const subscription = await this.registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.applicationServerKey
      })
      this.show(await this.save(subscription) ? "on" : "off")
    } catch (error) {
      console.error("Push notifications couldn't be turned on", error)
      this.show(Notification.permission === "denied" ? "blocked" : "off")
    }
  }

  async disable() {
    const subscription = await this.registration.pushManager.getSubscription()
    if (subscription) {
      await this.request("DELETE", { endpoint: subscription.endpoint })
      await subscription.unsubscribe()
    }
    this.show("off")
  }

  async save(subscription) {
    const response = await this.request("POST", { push_subscription: subscription.toJSON() })
    return response.ok
  }

  request(method, body) {
    return fetch(this.urlValue, {
      method,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify(body)
    })
  }

  show(name) {
    for (const state of this.constructor.targets) {
      const has = this[`has${state[0].toUpperCase()}${state.slice(1)}Target`]
      if (has) this[`${state}Target`].hidden = state !== name
    }
  }

  get supported() {
    return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window
  }

  // On iPhone, Web Push only works in the app added to the Home Screen.
  get iphoneInBrowser() {
    return /iPhone|iPad|iPod/.test(navigator.userAgent) && !navigator.standalone
  }

  // The VAPID public key, from base64url to the bytes the browser expects.
  get applicationServerKey() {
    const base64 = (this.publicKeyValue + "=".repeat((4 - this.publicKeyValue.length % 4) % 4))
      .replace(/-/g, "+").replace(/_/g, "/")
    return Uint8Array.from(atob(base64), (char) => char.charCodeAt(0))
  }
}
