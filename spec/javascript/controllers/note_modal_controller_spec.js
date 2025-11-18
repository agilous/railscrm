import { Application } from '@hotwired/stimulus'
import NoteModalController from '../../../app/javascript/controllers/note_modal_controller'

describe('NoteModalController', () => {
  let application
  let controller
  let element

  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = `
      <div id="noteModal" 
           class="hidden fixed z-50 inset-0 overflow-y-auto"
           data-controller="note-modal"
           data-note-modal-target="modal"
           data-note-modal-contact-id="123">
        <form data-note-modal-target="form">
          <textarea data-note-modal-target="content" id="note_content"></textarea>
        </form>
      </div>
    `

    element = document.querySelector('#noteModal')

    // Set up Stimulus
    application = Application.start()
    application.register('note-modal', NoteModalController)

    // Get controller instance
    controller = application.getControllerForElementAndIdentifier(element, 'note-modal')
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ''
    delete window.openNoteModal
  })

  describe('connect', () => {
    it('sets up global openNoteModal function', () => {
      expect(window.openNoteModal).toBeDefined()
      expect(typeof window.openNoteModal).toBe('function')
    })
  })

  describe('disconnect', () => {
    it('removes global openNoteModal function', () => {
      controller.disconnect()
      expect(window.openNoteModal).toBeUndefined()
    })
  })

  describe('open', () => {
    it('removes hidden class from modal', () => {
      expect(element.classList.contains('hidden')).toBe(true)

      controller.open()

      expect(element.classList.contains('hidden')).toBe(false)
    })

    it('focuses the content textarea', () => {
      const textarea = document.querySelector('#note_content')
      const focusSpy = jest.spyOn(textarea, 'focus')

      controller.open()

      expect(focusSpy).toHaveBeenCalled()
    })

    it('can be called via global function', () => {
      expect(element.classList.contains('hidden')).toBe(true)

      window.openNoteModal()

      expect(element.classList.contains('hidden')).toBe(false)
    })
  })

  describe('close', () => {
    it('adds hidden class to modal', () => {
      element.classList.remove('hidden')
      expect(element.classList.contains('hidden')).toBe(false)

      controller.close()

      expect(element.classList.contains('hidden')).toBe(true)
    })

    it('resets the form', () => {
      const form = element.querySelector('form')
      const resetSpy = jest.spyOn(form, 'reset')

      controller.close()

      expect(resetSpy).toHaveBeenCalled()
    })
  })

  describe('submit', () => {
    let fetchMock
    let event

    beforeEach(() => {
      event = new Event('submit')
      event.preventDefault = jest.fn()

      fetchMock = jest.spyOn(global, 'fetch').mockResolvedValue({
        ok: true,
        json: async () => ({ success: true })
      })

      // Mock location.reload
      delete window.location
      window.location = { reload: jest.fn() }

      // Add CSRF token
      document.head.innerHTML = '<meta name="csrf-token" content="test-token">'
    })

    afterEach(() => {
      fetchMock.mockRestore()
    })

    it('prevents default form submission', async () => {
      await controller.submit(event)

      expect(event.preventDefault).toHaveBeenCalled()
    })

    it('sends POST request to /notes', async () => {
      await controller.submit(event)

      expect(fetchMock).toHaveBeenCalledWith('/notes', expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          'X-CSRF-Token': 'test-token'
        })
      }))
    })

    it('includes contact ID in form data when present', async () => {
      await controller.submit(event)

      const call = fetchMock.mock.calls[0]
      const formData = call[1].body

      expect(formData).toBeInstanceOf(FormData)
      expect(formData.get('note[notable_ids][]')).toBe('Contact-123')
    })

    it('reloads page on successful submission', async () => {
      await controller.submit(event)

      expect(window.location.reload).toHaveBeenCalled()
    })

    it('shows alert on failed submission', async () => {
      fetchMock.mockResolvedValue({
        ok: false,
        json: async () => ({ error: 'Failed' })
      })

      const alertSpy = jest.spyOn(window, 'alert').mockImplementation()

      await controller.submit(event)

      expect(alertSpy).toHaveBeenCalledWith('Failed to save note')
      alertSpy.mockRestore()
    })

    it('handles network errors', async () => {
      fetchMock.mockRejectedValue(new Error('Network error'))

      const alertSpy = jest.spyOn(window, 'alert').mockImplementation()

      await controller.submit(event)

      expect(alertSpy).toHaveBeenCalledWith('An error occurred while saving the note')

      alertSpy.mockRestore()
    })
  })
})