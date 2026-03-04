import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["map", "select"]
  static values = { addresses: Object, initialAddress: String }

  connect() {
    if (!this.element.classList.contains("hidden")) {
      this.initMap()
    }
  }

  show() {
    if (!this.map) {
      this.initMap()
    } else {
      google.maps.event.trigger(this.map, "resize")
    }
  }

  async initMap() {
    const apiKey = document.querySelector('meta[name="google-maps-api-key"]')?.content
    if (!apiKey) return

    await this.loadScript(apiKey)

    const { Map } = await google.maps.importLibrary("maps")
    const { AdvancedMarkerElement } = await google.maps.importLibrary("marker")

    this.map = new Map(this.mapTarget, {
      center: { lat: -32.8908, lng: -68.8272 },
      zoom: 12,
      mapTypeControl: false,
      mapId: "DEMO_MAP_ID",
    })

    this.geocoder = new google.maps.Geocoder()
    this.marker = new AdvancedMarkerElement({ map: null })

    if (this.initialAddressValue) {
      this.geocode(this.initialAddressValue)
    } else if (this.hasSelectTarget && this.selectTarget.value) {
      const address = this.addressesValue[this.selectTarget.value]
      if (address) this.geocode(address)
    }
  }

  selectChurch(event) {
    const address = this.addressesValue[event.target.value]
    if (address) this.geocode(address)
  }

  geocode(address) {
    this.geocoder.geocode(
      { address: `${address}, Mendoza, Argentina`, componentRestrictions: { country: "ar" } },
      (results, status) => {
        if (status === "OK" && results[0]) {
          const location = results[0].geometry.location
          this.map.setCenter(location)
          this.map.setZoom(15)
          this.marker.position = location
          this.marker.map = this.map
        }
      }
    )
  }

  loadScript(apiKey) {
    if (window.google?.maps) return Promise.resolve()
    if (window.__googleMapsPromise) return window.__googleMapsPromise

    window.__googleMapsPromise = new Promise((resolve, reject) => {
      window.__googleMapsReady = () => {
        delete window.__googleMapsReady
        resolve()
      }
      const script = document.createElement("script")
      script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&callback=__googleMapsReady&loading=async`
      script.onerror = () => {
        delete window.__googleMapsPromise
        reject(new Error("Failed to load Google Maps API"))
      }
      document.head.appendChild(script)
    })

    return window.__googleMapsPromise
  }
}
