import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "modal", "cropImage"]

  connect() {
    this.cropper = null
  }

  disconnect() {
    this.destroyCropper()
  }

  openFilePicker() {
    this.inputTarget.click()
  }

  fileSelected(event) {
    const file = event.target.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      this.cropImageTarget.src = e.target.result
      this.showModal()
      // Wait for image to render before initializing cropper
      this.cropImageTarget.onload = () => this.initCropper()
    }
    reader.readAsDataURL(file)
  }

  showModal() {
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  hideModal() {
    this.modalTarget.classList.add("hidden")
    document.body.style.overflow = ""
    this.destroyCropper()
    this.cropImageTarget.src = ""
  }

  initCropper() {
    this.destroyCropper()
    this.cropper = new Cropper(this.cropImageTarget, {
      aspectRatio: 1,
      viewMode: 1,
      autoCropArea: 0.8,
      responsive: true,
      background: false,
    })
  }

  destroyCropper() {
    if (this.cropper) {
      this.cropper.destroy()
      this.cropper = null
    }
  }

  applyCrop() {
    if (!this.cropper) return

    this.cropper.getCroppedCanvas({ width: 400, height: 400 }).toBlob((blob) => {
      const file = new File([blob], "avatar.jpg", { type: "image/jpeg" })
      const dt = new DataTransfer()
      dt.items.add(file)
      this.inputTarget.files = dt.files

      const url = URL.createObjectURL(blob)
      if (this.hasPreviewTarget) {
        this.previewTarget.src = url
        this.previewTarget.classList.remove("hidden")
      }
      if (this.hasPlaceholderTarget) {
        this.placeholderTarget.classList.add("hidden")
      }

      this.hideModal()
    }, "image/jpeg", 0.92)
  }

  cancel() {
    this.inputTarget.value = ""
    this.hideModal()
  }
}
