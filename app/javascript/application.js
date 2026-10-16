// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import "@37signals/lexxy"
import { open as openConfirmDialog, optionsFrom as confirmOptionsFrom } from "./confirm_dialog"

Turbo.config.forms.confirm = (message, element, submitter) =>
  openConfirmDialog(message, confirmOptionsFrom(element, submitter))
