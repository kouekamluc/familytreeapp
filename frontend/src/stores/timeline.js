import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useTimelineStore = defineStore('timeline', () => {
  const events = ref([])
  const dateRange = ref({ start: null, end: null })
  const selectedEvent = ref(null)
  const loading = ref(false)
  const error = ref(null)

  const getTimelineEvents = async (treeId, startDate, endDate) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/timeline/`, {
        params: {
          start_date: startDate,
          end_date: endDate
        }
      })
      events.value = response.data.events
      dateRange.value = response.data.date_range
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch timeline events'
      return false
    } finally {
      loading.value = false
    }
  }

  const selectEvent = (event) => {
    selectedEvent.value = event
  }

  const clearSelection = () => {
    selectedEvent.value = null
  }

  const getEventDetails = async (treeId, eventId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/events/${eventId}/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch event details'
      return null
    } finally {
      loading.value = false
    }
  }

  const getEventPeople = async (treeId, eventId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/events/${eventId}/people/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch event people'
      return []
    } finally {
      loading.value = false
    }
  }

  const getEventMedia = async (treeId, eventId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/events/${eventId}/media/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch event media'
      return []
    } finally {
      loading.value = false
    }
  }

  const filterEventsByType = (eventType) => {
    return events.value.filter(event => event.type === eventType)
  }

  const filterEventsByPerson = (personId) => {
    return events.value.filter(event => event.people.some(person => person.id === personId))
  }

  const filterEventsByDateRange = (start, end) => {
    return events.value.filter(event => {
      const eventDate = new Date(event.date)
      return eventDate >= start && eventDate <= end
    })
  }

  const groupEventsByYear = () => {
    const grouped = {}
    events.value.forEach(event => {
      const year = new Date(event.date).getFullYear()
      if (!grouped[year]) {
        grouped[year] = []
      }
      grouped[year].push(event)
    })
    return grouped
  }

  const groupEventsByType = () => {
    const grouped = {}
    events.value.forEach(event => {
      if (!grouped[event.type]) {
        grouped[event.type] = []
      }
      grouped[event.type].push(event)
    })
    return grouped
  }

  const exportTimeline = async (treeId, format = 'json') => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/timeline/export/`, {
        params: { format },
        responseType: 'blob'
      })
      
      // Create a download link
      const url = window.URL.createObjectURL(new Blob([response.data]))
      const link = document.createElement('a')
      link.href = url
      link.setAttribute('download', `timeline-${treeId}.${format}`)
      document.body.appendChild(link)
      link.click()
      link.remove()
      window.URL.revokeObjectURL(url)
      
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to export timeline'
      return false
    } finally {
      loading.value = false
    }
  }

  return {
    events,
    dateRange,
    selectedEvent,
    loading,
    error,
    getTimelineEvents,
    selectEvent,
    clearSelection,
    getEventDetails,
    getEventPeople,
    getEventMedia,
    filterEventsByType,
    filterEventsByPerson,
    filterEventsByDateRange,
    groupEventsByYear,
    groupEventsByType,
    exportTimeline
  }
}) 