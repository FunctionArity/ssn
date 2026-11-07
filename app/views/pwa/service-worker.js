// Shows the push notifications sent by the server (PushSubscription#deliver), e.g. when a user is mentioned.
self.addEventListener("push", (event) => {
  const { title, options } = event.data.json()
  event.waitUntil(self.registration.showNotification(title, options))
})

// Opens the comment: in a tab of the app that is already open, or in a new one.
// The same for a click on the notification and on its "open" button (event.action is "open" then).
self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const url = new URL(event.notification.data?.path || "/", self.location.origin).href

  event.waitUntil((async () => {
    const windows = await clients.matchAll({ type: "window", includeUncontrolled: true })
    const client = windows.find((window) => new URL(window.url).origin === self.location.origin)

    if (client) {
      try {
        await client.focus()
        return await client.navigate(url)
      } catch {
        // A tab this worker doesn't control can't be navigated from here.
      }
    }
    return clients.openWindow(url)
  })())
})

// Takes control of the open tabs right away, so a click on a notification can reuse them.
self.addEventListener("activate", (event) => event.waitUntil(clients.claim()))
