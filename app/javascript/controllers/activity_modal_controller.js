import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="activity-modal"
export default class extends Controller {
  static targets = [ 'modal', 'form' ]

  connect() {
    // Set up global listener for opening the modal
    window.openActivityModal = () => {
      this.open()
    }
  }

  disconnect() {
    delete window.openActivityModal
  }

  open() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove('hidden')
    }
  }

  close() {
    this.modalTarget.classList.add('hidden')
    if (this.hasFormTarget) {
      this.formTarget.reset()
    }
  }

  submit(event) {
    event.preventDefault()

    const form = this.formTarget

    // Use native form submission which handles CSRF automatically
    form.submit()
  }
}
