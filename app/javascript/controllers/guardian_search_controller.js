import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "selectedList"]
  static values = { guardians: Array, selected: Array }

  connect() {
    this.selectedGuardians = new Map()
    this.selectedValue.forEach(id => {
      const guardian = this.guardiansValue.find(g => g.id === id)
      if (guardian) this.addGuardian(guardian)
    })
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
      this.dropdownTarget.classList.add("hidden")
      return
    }

    const matches = this.guardiansValue.filter(g =>
      !this.selectedGuardians.has(g.id) &&
      g.name.toLowerCase().includes(query)
    )

    if (matches.length === 0) {
      this.dropdownTarget.innerHTML = '<div class="px-3 py-2 text-sm text-gray-500">No results</div>'
    } else {
      this.dropdownTarget.innerHTML = matches.map(g =>
        `<button type="button" class="w-full text-left px-3 py-2 text-sm text-gray-700 hover:bg-blue-50 hover:text-blue-700 cursor-pointer" data-action="click->guardian-search#select" data-id="${g.id}" data-name="${this.escapeHtml(g.name)}">${this.escapeHtml(g.name)}</button>`
      ).join("")
    }

    this.dropdownTarget.classList.remove("hidden")
  }

  select(event) {
    const id = parseInt(event.currentTarget.dataset.id, 10)
    const name = event.currentTarget.dataset.name
    this.addGuardian({ id, name })
    this.inputTarget.value = ""
    this.dropdownTarget.classList.add("hidden")
  }

  addGuardian({ id, name }) {
    if (this.selectedGuardians.has(id)) return
    this.selectedGuardians.set(id, name)

    const chip = document.createElement("div")
    chip.className = "inline-flex items-center gap-1 rounded-full bg-blue-100 text-blue-800 px-3 py-1 text-sm"
    chip.dataset.guardianId = id
    chip.innerHTML = `
      <span>${this.escapeHtml(name)}</span>
      <input type="hidden" name="guard[guardian_ids][]" value="${id}">
      <button type="button" data-action="click->guardian-search#remove" data-id="${id}" class="ml-1 text-blue-600 hover:text-blue-900 cursor-pointer">&times;</button>
    `
    this.selectedListTarget.appendChild(chip)
  }

  remove(event) {
    const id = parseInt(event.currentTarget.dataset.id, 10)
    this.selectedGuardians.delete(id)
    const chip = this.selectedListTarget.querySelector(`[data-guardian-id="${id}"]`)
    if (chip) chip.remove()
  }

  escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
