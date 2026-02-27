import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["map", "input"]
  static values = { initialAddress: String }

  connect() {
    this.initMap()
  }

  disconnect() {
    clearTimeout(this._debounce)
  }

  async initMap() {
    const apiKey = document.querySelector('meta[name="google-maps-api-key"]')?.content
    if (!apiKey) return

    await this.loadScript(apiKey)

    const { Map } = await google.maps.importLibrary("maps")
    const { AdvancedMarkerElement } = await google.maps.importLibrary("marker")

    this.map = new Map(this.mapTarget, {
      center: { lat: -34.6, lng: -64.2 },
      zoom: 5,
      mapTypeControl: false,
      mapId: "DEMO_MAP_ID",
    })

    this.geocoder = new google.maps.Geocoder()

    this.marker = new AdvancedMarkerElement({
      map: null,
      gmpDraggable: true,
    })

    this.marker.addListener("dragend", () => {
      if (this.marker.position) this.reverseGeocode(this.marker.position)
    })

    this.map.addListener("click", (e) => {
      this.marker.position = e.latLng
      this.marker.map = this.map
      this.reverseGeocode(e.latLng)
    })

    if (this.initialAddressValue) {
      this.geocode(this.initialAddressValue)
    }
  }

  search(event) {
    clearTimeout(this._debounce)
    this._debounce = setTimeout(() => {
      const address = event.target.value.trim()
      if (address.length > 3) {
        this.geocode(address)
      } else {
        if (this.marker) this.marker.map = null
      }
    }, 600)
  }

  geocode(address) {
    this.geocoder.geocode(
      { address: `${address}, Argentina`, componentRestrictions: { country: "ar" } },
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

  reverseGeocode(latLng) {
    this.geocoder.geocode({ location: latLng }, (results, status) => {
      if (status === "OK" && results[0]) {
        this.inputTarget.value = results[0].formatted_address
      }
    })
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
