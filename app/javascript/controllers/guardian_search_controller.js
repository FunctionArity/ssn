import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "selectedList"]
  static values = { guardians: Array, selected: Array }

  connect() {
    this.selectedGuardians = new Map()
    this.highlightedIndex = -1
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
      this.highlightedIndex = -1
    }
  }

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    this.highlightedIndex = -1
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

  navigate(event) {
    const isOpen = !this.dropdownTarget.classList.contains("hidden")
    const items = this.dropdownTarget.querySelectorAll("button[data-id]")

    if (event.key === "ArrowDown") {
      event.preventDefault()
      if (!isOpen) return
      this.highlightedIndex = Math.min(this.highlightedIndex + 1, items.length - 1)
      this.updateHighlight(items)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      if (!isOpen) return
      this.highlightedIndex = Math.max(this.highlightedIndex - 1, 0)
      this.updateHighlight(items)
    } else if (event.key === "Enter") {
      if (isOpen && this.highlightedIndex >= 0 && items[this.highlightedIndex]) {
        event.preventDefault()
        items[this.highlightedIndex].click()
      } else if (isOpen && items.length > 0) {
        event.preventDefault()
      }
    } else if (event.key === "Escape") {
      this.dropdownTarget.classList.add("hidden")
      this.highlightedIndex = -1
    }
  }

  updateHighlight(items) {
    items.forEach((item, i) => {
      if (i === this.highlightedIndex) {
        item.classList.add("bg-blue-50", "text-blue-700")
        item.scrollIntoView({ block: "nearest" })
      } else {
        item.classList.remove("bg-blue-50", "text-blue-700")
      }
    })
  }

  select(event) {
    const id = parseInt(event.currentTarget.dataset.id, 10)
    const name = event.currentTarget.dataset.name
    this.addGuardian({ id, name })
    this.inputTarget.value = ""
    this.dropdownTarget.classList.add("hidden")
    this.highlightedIndex = -1
    this.inputTarget.focus()
  }

  addGuardian({ id, name }) {
    if (this.selectedGuardians.has(id)) return
    this.selectedGuardians.set(id, name)

    const chip = document.createElement("div")
    chip.className = "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium badge_green"
    chip.dataset.guardianId = id
    chip.innerHTML = `
      <span>${this.escapeHtml(name)}</span>
      <input type="hidden" name="guard[guardian_ids][]" value="${id}">
      <button type="button" data-action="click->guardian-search#remove" data-id="${id}" class="ml-1 text-green-600 hover:text-green-900 cursor-pointer">&times;</button>
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
