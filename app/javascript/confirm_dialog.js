let _resolve = null

const DEFAULT_TITLE = "Confirmar acción"
const DEFAULT_LEVEL = "danger"
const DEFAULT_BUTTON = "Aceptar"

const LEVELS = {
  danger: {
    icon: "ph-warning",
    iconClass: "bg-red-100 text-red-600",
    buttonClass: "bg-red-600 hover:bg-red-500"
  },
  warning: {
    icon: "ph-warning",
    iconClass: "bg-amber-100 text-amber-600",
    buttonClass: "bg-amber-500 hover:bg-amber-400"
  },
  success: {
    icon: "ph-check-circle",
    iconClass: "bg-green-100 text-green-600",
    buttonClass: "bg-green-600 hover:bg-green-500"
  },
  info: {
    icon: "ph-info",
    iconClass: "bg-blue-100 text-blue-600",
    buttonClass: "bg-blue-600 hover:bg-blue-500"
  }
}

const BASE_ICON_CLASS = "flex items-center justify-center w-10 h-10 rounded-full shrink-0"
const BASE_BUTTON_CLASS = "cursor-pointer rounded-lg px-4 py-2 text-sm font-semibold uppercase text-white shadow-sm"

// Options are read from data-turbo-confirm-title / -level / -button,
// on the submitter button first, then on the form or link.
// Without -button, the confirm button reuses the clicked button's text.
function optionsFrom(element, submitter) {
  const read = (key) => submitter?.dataset?.[key] || element?.dataset?.[key]
  const submitterText = (submitter?.textContent || submitter?.value || "").replace(/\s+/g, " ").trim()
  return {
    title: read("turboConfirmTitle"),
    level: read("turboConfirmLevel"),
    button: read("turboConfirmButton") || submitterText
  }
}

function open(message, { title, level, button } = {}) {
  const config = LEVELS[level] || LEVELS[DEFAULT_LEVEL]

  return new Promise((resolve) => {
    _resolve = resolve
    document.getElementById("confirm-dialog-title").textContent = title || DEFAULT_TITLE
    document.getElementById("confirm-dialog-message").textContent = message
    document.getElementById("confirm-dialog-icon").className = `${BASE_ICON_CLASS} ${config.iconClass}`
    document.getElementById("confirm-dialog-icon-glyph").className = `ph ${config.icon} text-lg`
    document.getElementById("confirm-dialog-confirm").className = `${BASE_BUTTON_CLASS} ${config.buttonClass}`
    document.getElementById("confirm-dialog-confirm").textContent = button || DEFAULT_BUTTON
    document.getElementById("confirm-dialog").classList.remove("hidden")
    document.getElementById("confirm-dialog").classList.add("flex")
  })
}

function close() {
  document.getElementById("confirm-dialog").classList.remove("flex")
  document.getElementById("confirm-dialog").classList.add("hidden")
}

document.addEventListener("click", (e) => {
  if (e.target.closest("#confirm-dialog-confirm")) {
    close()
    _resolve?.(true)
    _resolve = null
  } else if (e.target.closest("#confirm-dialog-cancel")) {
    close()
    _resolve?.(false)
    _resolve = null
  } else if (e.target.id === "confirm-dialog") {
    close()
    _resolve?.(false)
    _resolve = null
  }
})

export { open, optionsFrom }
