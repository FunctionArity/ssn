let _resolve = null

function open(message) {
  return new Promise((resolve) => {
    _resolve = resolve
    document.getElementById("confirm-dialog-message").textContent = message
    document.getElementById("confirm-dialog").classList.remove("hidden")
    document.getElementById("confirm-dialog").classList.add("flex")
  })
}

function close() {
  document.getElementById("confirm-dialog").classList.remove("flex")
  document.getElementById("confirm-dialog").classList.add("hidden")
}

document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("confirm-dialog-confirm").addEventListener("click", () => {
    close()
    _resolve?.(true)
    _resolve = null
  })

  document.getElementById("confirm-dialog-cancel").addEventListener("click", () => {
    close()
    _resolve?.(false)
    _resolve = null
  })

  document.getElementById("confirm-dialog").addEventListener("click", (e) => {
    if (e.target === e.currentTarget) {
      close()
      _resolve?.(false)
      _resolve = null
    }
  })
})

export { open }
