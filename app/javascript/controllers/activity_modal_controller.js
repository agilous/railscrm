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

  async submit(event) {
    event.preventDefault()

    const form = this.formTarget

    try {
      // Get CSRF token
      let csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

      if (!csrfToken) {
        csrfToken = document.querySelector('input[name="authenticity_token"]')?.value
      }

      if (!csrfToken) {
        throw new Error('CSRF token not found')
      }

      const formData = new FormData(form)

      const response = await fetch(form.action, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json'
        },
        body: formData
      })

      if (response.ok) {
        window.location.reload()
      } else {
        const errorText = await response.text()
        console.error('Failed to save activity:', response.status, errorText)
        alert(`Failed to save activity: ${response.status}`)
      }
    } catch (error) {
      console.error('Error saving activity:', error)
      alert(`An error occurred: ${error.message}`)
    }
  }
}
