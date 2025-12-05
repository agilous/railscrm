import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    title: String,
    description: String,
    location: String,
    startTime: String,
    duration: Number
  }

  generateICS() {
    // Parse the ISO date string - this will be in UTC from Rails
    const startDate = new Date(this.startTimeValue)
    const endDate = new Date(startDate.getTime() + (this.durationValue || 60) * 60000)

    // Format date in local timezone (browser's timezone)
    // This creates a "floating" time that will be interpreted in the user's calendar timezone
    const formatLocalDate = (date) => {
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, '0')
      const day = String(date.getDate()).padStart(2, '0')
      const hours = String(date.getHours()).padStart(2, '0')
      const minutes = String(date.getMinutes()).padStart(2, '0')
      const seconds = String(date.getSeconds()).padStart(2, '0')
      return `${year}${month}${day}T${hours}${minutes}${seconds}`
    }

    // Format UTC date for DTSTAMP (which should always be UTC)
    const formatUTCDate = (date) => {
      return date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '')
    }

    const icsContent = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Wendell CRM//Activity//EN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      `UID:${Date.now()}@wendellcrm.local`,
      `DTSTAMP:${formatUTCDate(new Date())}`,
      `DTSTART:${formatLocalDate(startDate)}`,
      `DTEND:${formatLocalDate(endDate)}`,
      `SUMMARY:${this.escapeICS(this.titleValue)}`,
      this.descriptionValue ? `DESCRIPTION:${this.escapeICS(this.descriptionValue)}` : '',
      this.locationValue ? `LOCATION:${this.escapeICS(this.locationValue)}` : '',
      'END:VEVENT',
      'END:VCALENDAR'
    ].filter(line => line).join('\r\n')

    this.downloadICS(icsContent, 'activity.ics')
  }

  generateGoogleCalendar() {
    const startDate = new Date(this.startTimeValue)
    const endDate = new Date(startDate.getTime() + (this.durationValue || 60) * 60000)

    const formatGoogleDate = (date) => {
      return date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '')
    }

    const params = new URLSearchParams({
      action: 'TEMPLATE',
      text: this.titleValue,
      dates: `${formatGoogleDate(startDate)}/${formatGoogleDate(endDate)}`,
      details: this.descriptionValue || '',
      location: this.locationValue || ''
    })

    window.open(`https://calendar.google.com/calendar/render?${params}`, '_blank')
  }

  generateOutlookWeb() {
    const startDate = new Date(this.startTimeValue)
    const endDate = new Date(startDate.getTime() + (this.durationValue || 60) * 60000)

    const params = new URLSearchParams({
      path: '/calendar/action/compose',
      rru: 'addevent',
      subject: this.titleValue,
      body: this.descriptionValue || '',
      location: this.locationValue || '',
      startdt: startDate.toISOString(),
      enddt: endDate.toISOString()
    })

    window.open(`https://outlook.live.com/calendar/0/deeplink/compose?${params}`, '_blank')
  }

  escapeICS(str) {
    return str
      .replace(/\\/g, '\\\\')
      .replace(/;/g, '\\;')
      .replace(/,/g, '\\,')
      .replace(/\n/g, '\\n')
  }

  downloadICS(content, filename) {
    const blob = new Blob([content], { type: 'text/calendar;charset=utf-8' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = filename
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    URL.revokeObjectURL(url)
  }
}