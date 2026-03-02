import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "hiddenField"]
  static values = { facilities: Array, selectedId: Number, selectedName: String }

  connect() {
    if (this.selectedIdValue) {
      this.inputTarget.value = this.selectedNameValue
    }
    document.addEventListener("click", this.closeDropdown)
  }

  disconnect() {
    document.removeEventListener("click", this.closeDropdown)
  }

  closeDropdown = (event) => {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden")
    }
  }

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    if (query.length === 0) {
      this.hiddenFieldTarget.value = ""
      this.dropdownTarget.classList.add("hidden")
      return
    }

    const matches = this.facilitiesValue.filter(f =>
      f.name.toLowerCase().includes(query)
    )

    if (matches.length === 0) {
      this.dropdownTarget.innerHTML = '<div class="px-3 py-2 text-sm text-gray-500">No results</div>'
    } else {
      this.dropdownTarget.innerHTML = matches.map(f =>
        `<button type="button" class="w-full text-left px-3 py-2 text-sm text-gray-700 hover:bg-blue-50 hover:text-blue-700 cursor-pointer" data-action="click->health-facility-search#select" data-id="${f.id}" data-name="${this.escapeHtml(f.name)}" data-address="${this.escapeHtml(f.address || "")}">${this.escapeHtml(f.name)}</button>`
      ).join("")
    }

    this.dropdownTarget.classList.remove("hidden")
  }

  select(event) {
    const id = parseInt(event.currentTarget.dataset.id, 10)
    const name = event.currentTarget.dataset.name
    const address = event.currentTarget.dataset.address
    this.hiddenFieldTarget.value = id
    this.inputTarget.value = name
    this.dropdownTarget.classList.add("hidden")

    if (address) {
      this.dispatch("select", { detail: { address } })
    }
  }

  clearSelection() {
    this.hiddenFieldTarget.value = ""
    this.inputTarget.value = ""
  }

  escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
