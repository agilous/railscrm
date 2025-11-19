import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="note-modal"
export default class extends Controller {
  static targets = [ 'modal', 'content', 'form' ]

  connect() {
    // Set up global listener for opening the modal
    window.openNoteModal = () => {
      this.open()
    }
  }

  disconnect() {
    delete window.openNoteModal
  }

  open() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove('hidden')
      if (this.hasContentTarget) {
        this.contentTarget.focus()
      }
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

    const formData = new FormData(this.formTarget)

    // Add primary notable if in context
    const contactId = this.element.dataset.noteModalContactId
    const opportunityId = this.element.dataset.noteModalOpportunityId
    const accountId = this.element.dataset.noteModalAccountId
    const leadId = this.element.dataset.noteModalLeadId

    if (contactId) {
      formData.append('note[notable_ids][]', `Contact-${contactId}`)
    } else if (opportunityId) {
      formData.append('note[notable_ids][]', `Opportunity-${opportunityId}`)
    } else if (accountId) {
      formData.append('note[notable_ids][]', `Account-${accountId}`)
    } else if (leadId) {
      formData.append('note[notable_ids][]', `Lead-${leadId}`)
    }

    try {
      // Get CSRF token - try multiple methods
      let csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

      // If still not found, try getting from a form on the page
      if (!csrfToken) {
        csrfToken = document.querySelector('input[name="authenticity_token"]')?.value
      }

      if (!csrfToken) {
        throw new Error('CSRF token not found')
      }

      const response = await fetch('/notes', {
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
        console.error('Failed to save note:', response.status, errorText)
        alert(`Failed to save note: ${response.status}`)
      }
    } catch (error) {
      console.error('Error saving note:', error)
      alert(`An error occurred: ${error.message}`)
    }
  }
}