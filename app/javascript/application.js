// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import { open as openConfirmDialog } from "./confirm_dialog"

Turbo.config.forms.confirm = (message) => openConfirmDialog(message)
