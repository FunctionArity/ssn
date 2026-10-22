import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "modal", "cropImage", "signedId", "status"]
  static values = { directUploadUrl: String, uploadingText: String, errorText: String }

  connect() {
    this.cropper = null
    this.uploading = false
    this.form = this.element.closest("form")
    this.blockSubmit = (event) => {
      if (this.uploading) event.preventDefault()
    }
    this.form?.addEventListener("submit", this.blockSubmit)
  }

  disconnect() {
    this.destroyCropper()
    this.form?.removeEventListener("submit", this.blockSubmit)
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
      this.upload(file)

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

  // Uploads the cropped picture straight to S3; the form only submits the signed blob id.
  upload(file) {
    this.uploading = true
    this.signedIdTarget.value = ""
    this.setSubmitDisabled(true)
    this.showStatus(this.uploadingTextValue, false)

    new DirectUpload(file, this.directUploadUrlValue).create((error, blob) => {
      this.uploading = false
      this.setSubmitDisabled(false)
      this.inputTarget.value = ""

      if (error) {
        this.showStatus(this.errorTextValue, true)
      } else {
        this.signedIdTarget.value = blob.signed_id
        this.hideStatus()
      }
    })
  }

  setSubmitDisabled(disabled) {
    this.form?.querySelectorAll("[type=submit]").forEach((button) => (button.disabled = disabled))
  }

  showStatus(text, isError) {
    if (!this.hasStatusTarget) return
    this.statusTarget.textContent = text
    this.statusTarget.classList.toggle("text-red-600", isError)
    this.statusTarget.classList.toggle("text-gray-500", !isError)
    this.statusTarget.classList.remove("hidden")
  }

  hideStatus() {
    if (this.hasStatusTarget) this.statusTarget.classList.add("hidden")
  }
}
