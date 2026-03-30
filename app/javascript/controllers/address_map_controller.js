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
    this.dispatch("input", { bubbles: true })
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

  handleFacilitySelect(event) {
    const address = event.detail.address
    if (address) {
      this.inputTarget.value = address
      this.geocode(address)
    }
  }

  reverseGeocode(latLng) {
    this.geocoder.geocode({ location: latLng }, (results, status) => {
      if (status === "OK" && results[0]) {
        this.inputTarget.value = results[0].formatted_address
      }
    })
  }

  /**
   * Dynamically loads the Google Maps API as a singleton Promise.
   *
   * Why do we load the Google Map API this way?
   * - The Google Maps script must only be loaded once; loading it multiple times can cause errors or conflicts.
   * - Scripts added after page load don't block rendering and load asynchronously, reducing initial page load time.
   * - This pattern ensures the script is loaded before running any code that depends on Google Maps, and prevents redundant loads, by duplicating the request if a second load comes before the first finishes.
   * - Using a global promise allows any part of the app that calls `loadScript` to receive the same resolved promise, eliminating race conditions.
   */
  loadScript(apiKey) {
    // Return immediately if already loaded
    if (window.google?.maps) return Promise.resolve();

    // If already loading, return the same promise to avoid duplicate requests
    if (window.__googleMapsPromise) return window.__googleMapsPromise;

    // Create and store a singleton Promise for script loading
    window.__googleMapsPromise = new Promise((resolve, reject) => {
      // Global callback for Google Maps API ready event
      window.__googleMapsReady = () => {
        delete window.__googleMapsReady;
        resolve();
      };

      const script = document.createElement("script");
      script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&callback=__googleMapsReady&loading=async`;
      script.onerror = () => {
        // Clean up so future calls can retry
        delete window.__googleMapsPromise;
        reject(new Error("Failed to load Google Maps API"));
      };
      document.head.appendChild(script);
    });

    return window.__googleMapsPromise;
  }
}
