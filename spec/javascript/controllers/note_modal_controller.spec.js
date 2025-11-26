import { Application } from '@hotwired/stimulus'
import NoteModalController from '../../../app/javascript/controllers/note_modal_controller'

describe('NoteModalController', () => {
  let application
  let element

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="noteModal" 
           class="hidden"
           data-controller="note-modal"
           data-note-modal-target="modal"
           data-note-modal-contact-id="123">
        <form data-note-modal-target="form">
          <textarea data-note-modal-target="content" name="note[content]"></textarea>
          <button type="button" data-action="click->note-modal#submit">Save</button>
          <button type="button" data-action="click->note-modal#close">Cancel</button>
        </form>
      </div>
    `

    element = document.querySelector('#noteModal')
    application = Application.start()
    application.register('note-modal', NoteModalController)
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ''
    document.head.innerHTML = ''
    jest.clearAllMocks()
  })

  describe('#open', () => {
    it('removes hidden class from modal', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')

      expect(element.classList.contains('hidden')).toBe(true)
      controller.open()
      expect(element.classList.contains('hidden')).toBe(false)
    })

    it('focuses on content textarea when opened', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')
      const textarea = element.querySelector('textarea')
      const focusSpy = jest.spyOn(textarea, 'focus')

      controller.open()
      expect(focusSpy).toHaveBeenCalled()
    })

    it('sets up global openNoteModal function', () => {
      expect(window.openNoteModal).toBeDefined()
      expect(typeof window.openNoteModal).toBe('function')
    })
  })

  describe('#close', () => {
    it('adds hidden class to modal', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')

      element.classList.remove('hidden')
      expect(element.classList.contains('hidden')).toBe(false)

      controller.close()
      expect(element.classList.contains('hidden')).toBe(true)
    })

    it('resets the form when closing', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')
      const form = element.querySelector('form')
      const resetSpy = jest.spyOn(form, 'reset')

      controller.close()
      expect(resetSpy).toHaveBeenCalled()
    })
  })

  describe('#submit', () => {
    let fetchMock

    beforeEach(() => {
      // Mock fetch
      fetchMock = jest.fn(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ success: true })
        })
      )
      global.fetch = fetchMock

      // Mock location.reload
      delete window.location
      window.location = { reload: jest.fn() }

      // Add CSRF token meta tag
      const meta = document.createElement('meta')
      meta.setAttribute('name', 'csrf-token')
      meta.setAttribute('content', 'test-token')
      document.head.appendChild(meta)
    })

    it('prevents default form submission', async () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')
      const event = new Event('submit')
      const preventDefaultSpy = jest.spyOn(event, 'preventDefault')

      await controller.submit(event)
      expect(preventDefaultSpy).toHaveBeenCalled()
    })

    it('sends POST request with form data', async () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')
      const textarea = element.querySelector('textarea')
      textarea.value = 'Test note content'

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      expect(fetchMock).toHaveBeenCalledWith('/notes', expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          'X-CSRF-Token': 'test-token',
          'Accept': 'application/json'
        }),
        body: expect.any(FormData)
      }))
    })

    it('includes contact ID in form data when present', async () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      const formData = fetchMock.mock.calls[0][1].body
      expect(formData.get('note[notable_ids][]')).toBe('Contact-123')
    })

    it('includes opportunity ID when present', async () => {
      element.dataset.noteModalOpportunityId = '456'
      delete element.dataset.noteModalContactId

      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      const formData = fetchMock.mock.calls[0][1].body
      expect(formData.get('note[notable_ids][]')).toBe('Opportunity-456')
    })

    it('reloads page on successful submission', async () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      expect(window.location.reload).toHaveBeenCalled()
    })

    it('shows alert on failed submission', async () => {
      fetchMock.mockResolvedValueOnce({
        ok: false,
        status: 422,
        text: () => Promise.resolve('Validation error')
      })

      const alertSpy = jest.spyOn(window, 'alert').mockImplementation(() => {})
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      expect(alertSpy).toHaveBeenCalledWith('Failed to save note: 422')
      expect(window.location.reload).not.toHaveBeenCalled()

      consoleErrorSpy.mockRestore()
    })

    it('handles network errors', async () => {
      fetchMock.mockRejectedValueOnce(new Error('Network error'))

      const alertSpy = jest.spyOn(window, 'alert').mockImplementation(() => {})
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      expect(alertSpy).toHaveBeenCalledWith('An error occurred: Network error')
      expect(window.location.reload).not.toHaveBeenCalled()

      consoleErrorSpy.mockRestore()
    })

    it('handles missing CSRF token', async () => {
      // Remove CSRF token
      document.querySelector('meta[name="csrf-token"]').remove()

      // Ensure no authenticity token input exists either
      const authTokens = document.querySelectorAll('input[name="authenticity_token"]')
      authTokens.forEach(token => token.remove())

      const alertSpy = jest.spyOn(window, 'alert').mockImplementation(() => {})
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      expect(alertSpy).toHaveBeenCalledWith('An error occurred: CSRF token not found')
      expect(fetchMock).not.toHaveBeenCalled()

      consoleErrorSpy.mockRestore()
    })

    it('tries authenticity token as fallback for CSRF', async () => {
      // Remove CSRF meta tag
      document.querySelector('meta[name="csrf-token"]').remove()

      // Add authenticity token input
      const input = document.createElement('input')
      input.setAttribute('name', 'authenticity_token')
      input.setAttribute('value', 'fallback-token')
      document.body.appendChild(input)

      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      // Verify fetch was called with the fallback token
      expect(fetchMock).toHaveBeenCalled()
      const callArgs = fetchMock.mock.calls[0]
      expect(callArgs[0]).toBe('/notes')
      expect(callArgs[1].headers['X-CSRF-Token']).toBe('fallback-token')
    })
  })

  describe('#disconnect', () => {
    it('removes global openNoteModal function', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'note-modal')

      expect(window.openNoteModal).toBeDefined()

      controller.disconnect()

      expect(window.openNoteModal).toBeUndefined()
    })
  })
})
