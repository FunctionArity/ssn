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

export { open }
