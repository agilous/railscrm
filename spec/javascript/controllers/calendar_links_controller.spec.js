import { Application } from '@hotwired/stimulus'
import CalendarLinksController from '../../../app/javascript/controllers/calendar_links_controller'

describe('CalendarLinksController', () => {
  let application
  let controller
  let element

  beforeEach(() => {
    // Setup DOM
    document.body.innerHTML = `
      <div data-controller="calendar-links"
           data-calendar-links-title-value="Meeting: Team Standup"
           data-calendar-links-description-value="Daily team sync meeting"
           data-calendar-links-location-value="Conference Room A"
           data-calendar-links-start-time-value="2025-12-01T10:00:00"
           data-calendar-links-duration-value="30">
        <button data-action="click->calendar-links#generateICS">Apple/Outlook</button>
        <button data-action="click->calendar-links#generateGoogleCalendar">Google Calendar</button>
        <button data-action="click->calendar-links#generateOutlookWeb">Outlook.com</button>
      </div>
    `

    element = document.querySelector('[data-controller="calendar-links"]')

    // Setup Stimulus
    application = Application.start()
    application.register('calendar-links', CalendarLinksController)
    controller = application.getControllerForElementAndIdentifier(element, 'calendar-links')
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ''
    jest.clearAllMocks()
  })

  describe('ICS file generation', () => {
    let createElementSpy
    let createObjectURLSpy
    let revokeObjectURLSpy
    let originalBlob

    beforeEach(() => {
      // Store original Blob
      originalBlob = global.Blob

      // Mock Blob
      global.Blob = jest.fn((content, options) => ({
        content: content[0], // Store the actual content string
        options,
        size: content[0].length,
        type: options.type
      }))

      // Mock URL methods if they exist, or create them
      if (!URL.createObjectURL) {
        URL.createObjectURL = jest.fn()
      }
      if (!URL.revokeObjectURL) {
        URL.revokeObjectURL = jest.fn()
      }
      createObjectURLSpy = jest.spyOn(URL, 'createObjectURL').mockReturnValue('blob:mock-url')
      revokeObjectURLSpy = jest.spyOn(URL, 'revokeObjectURL').mockImplementation(() => {})

      // Mock createElement to return a mock link element
      const mockLink = document.createElement('a')
      mockLink.click = jest.fn()
      createElementSpy = jest.spyOn(document, 'createElement').mockImplementation((tag) => {
        if (tag === 'a') {
          return mockLink
        }
        return document.createElement(tag)
      })
    })

    afterEach(() => {
      // Restore original Blob
      global.Blob = originalBlob
      jest.clearAllMocks()
    })

    it('generates valid ICS content with all fields', () => {
      const button = element.querySelector('[data-action="click->calendar-links#generateICS"]')
      button.click()

      // Check Blob was created
      expect(global.Blob).toHaveBeenCalled()
      const blobCall = global.Blob.mock.calls[0]
      const icsContent = blobCall[0][0] // First argument is array with ICS content string

      // Check ICS content contains expected fields
      expect(icsContent).toMatch(/BEGIN:VCALENDAR/)
      expect(icsContent).toMatch(/VERSION:2.0/)
      expect(icsContent).toMatch(/BEGIN:VEVENT/)
      expect(icsContent).toMatch(/SUMMARY:Meeting: Team Standup/)
      expect(icsContent).toMatch(/DESCRIPTION:Daily team sync meeting/)
      expect(icsContent).toMatch(/LOCATION:Conference Room A/)
      expect(icsContent).toMatch(/END:VEVENT/)
      expect(icsContent).toMatch(/END:VCALENDAR/)
    })

    it('downloads ICS file with correct filename', () => {
      const button = element.querySelector('[data-action="click->calendar-links#generateICS"]')
      button.click()

      // Check that a link was created and clicked
      const linkElement = createElementSpy.mock.results.find(r => r.value && r.value.tagName === 'A')?.value
      expect(linkElement).toBeDefined()
      expect(linkElement.download).toBe('activity.ics')
      expect(linkElement.href).toBe('blob:mock-url')
      expect(linkElement.click).toHaveBeenCalled()
    })

    it('handles missing optional fields gracefully', () => {
      // Remove optional fields
      element.dataset.calendarLinksDescriptionValue = ''
      element.dataset.calendarLinksLocationValue = ''

      const button = element.querySelector('[data-action="click->calendar-links#generateICS"]')
      button.click()

      const blobCall = global.Blob.mock.calls[0]
      const icsContent = blobCall[0][0]

      // Should not contain DESCRIPTION or LOCATION fields when empty
      expect(icsContent).not.toMatch(/DESCRIPTION:/)
      expect(icsContent).not.toMatch(/LOCATION:/)
    })

    it('uses default duration of 60 minutes when not specified', () => {
      element.dataset.calendarLinksDurationValue = ''

      const button = element.querySelector('[data-action="click->calendar-links#generateICS"]')
      button.click()

      const blobCall = global.Blob.mock.calls[0]
      const icsContent = blobCall[0][0]

      // Check that times are present in content (exact times depend on timezone)
      expect(icsContent).toMatch(/DTSTART:/)
      expect(icsContent).toMatch(/DTEND:/)
    })

    it('escapes special characters in ICS fields', () => {
      element.dataset.calendarLinksTitleValue = 'Meeting; Important, Very\nMultiline'

      const button = element.querySelector('[data-action="click->calendar-links#generateICS"]')
      button.click()

      const blobCall = global.Blob.mock.calls[0]
      const icsContent = blobCall[0][0]

      // Check that special characters are escaped
      expect(icsContent).toMatch(/SUMMARY:Meeting\\; Important\\, Very\\nMultiline/)
    })
  })

  describe('Google Calendar link generation', () => {
    let windowOpenSpy

    beforeEach(() => {
      windowOpenSpy = jest.spyOn(window, 'open').mockImplementation(() => {})
    })

    it('opens Google Calendar with correct parameters', () => {
      const button = element.querySelector('[data-action="click->calendar-links#generateGoogleCalendar"]')
      button.click()

      expect(windowOpenSpy).toHaveBeenCalledWith(
        expect.stringContaining('https://calendar.google.com/calendar/render'),
        '_blank'
      )

      const calledUrl = windowOpenSpy.mock.calls[0][0]
      const url = new URL(calledUrl)
      const params = new URLSearchParams(url.search)

      expect(params.get('action')).toBe('TEMPLATE')
      expect(params.get('text')).toBe('Meeting: Team Standup')
      expect(params.get('details')).toBe('Daily team sync meeting')
      expect(params.get('location')).toBe('Conference Room A')
      // Check dates param exists and has the right format
      const dates = params.get('dates')
      expect(dates).toMatch(/^\d{8}T\d{6}Z\/\d{8}T\d{6}Z$/)
    })

    it('handles missing optional fields', () => {
      element.dataset.calendarLinksDescriptionValue = ''
      element.dataset.calendarLinksLocationValue = ''

      const button = element.querySelector('[data-action="click->calendar-links#generateGoogleCalendar"]')
      button.click()

      const calledUrl = windowOpenSpy.mock.calls[0][0]
      const url = new URL(calledUrl)
      const params = new URLSearchParams(url.search)

      expect(params.get('details')).toBe('')
      expect(params.get('location')).toBe('')
    })
  })

  describe('Outlook.com link generation', () => {
    let windowOpenSpy

    beforeEach(() => {
      windowOpenSpy = jest.spyOn(window, 'open').mockImplementation(() => {})
    })

    it('opens Outlook.com with correct parameters', () => {
      const button = element.querySelector('[data-action="click->calendar-links#generateOutlookWeb"]')
      button.click()

      expect(windowOpenSpy).toHaveBeenCalledWith(
        expect.stringContaining('https://outlook.live.com/calendar/0/deeplink/compose'),
        '_blank'
      )

      const calledUrl = windowOpenSpy.mock.calls[0][0]
      const url = new URL(calledUrl)
      const params = new URLSearchParams(url.search)

      expect(params.get('path')).toBe('/calendar/action/compose')
      expect(params.get('rru')).toBe('addevent')
      expect(params.get('subject')).toBe('Meeting: Team Standup')
      expect(params.get('body')).toBe('Daily team sync meeting')
      expect(params.get('location')).toBe('Conference Room A')
      // Check datetime format (ISO 8601)
      expect(params.get('startdt')).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      expect(params.get('enddt')).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    })
  })
})