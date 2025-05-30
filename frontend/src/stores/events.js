import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useEventsStore = defineStore('events', () => {
  const events = ref([])
  const currentEvent = ref(null)
  const loading = ref(false)
  const error = ref(null)

  const getEvents = async (treeId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/events/`)
      events.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch events'
      return false
    } finally {
      loading.value = false
    }
  }

  const getEvent = async (treeId, eventId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/events/${eventId}/`)
      currentEvent.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch event'
      return false
    } finally {
      loading.value = false
    }
  }

  const createEvent = async (treeId, eventData) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post(`/trees/${treeId}/events/`, eventData)
      events.value.push(response.data)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to create event'
      return null
    } finally {
      loading.value = false
    }
  }

  const updateEvent = async (treeId, eventId, eventData) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put(`/trees/${treeId}/events/${eventId}/`, eventData)
      const index = events.value.findIndex(event => event.id === eventId)
      if (index !== -1) {
        events.value[index] = response.data
      }
      if (currentEvent.value?.id === eventId) {
        currentEvent.value = response.data
      }
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update event'
      return null
    } finally {
      loading.value = false
    }
  }

  const deleteEvent = async (treeId, eventId) => {
    try {
      loading.value = true
      error.value = null
      await api.delete(`/trees/${treeId}/events/${eventId}/`)
      events.value = events.value.filter(event => event.id !== eventId)
      if (currentEvent.value?.id === eventId) {
        currentEvent.value = null
      }
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to delete event'
      return false
    } finally {
      loading.value = false
    }
  }

  const addPersonToEvent = async (treeId, eventId, personId, role) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post(`/trees/${treeId}/events/${eventId}/people/`, {
        person_id: personId,
        role: role
      })
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to add person to event'
      return null
    } finally {
      loading.value = false
    }
  }

  const removePersonFromEvent = async (treeId, eventId, personId) => {
    try {
      loading.value = true
      error.value = null
      await api.delete(`/trees/${treeId}/events/${eventId}/people/${personId}/`)
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to remove person from event'
      return false
    } finally {
      loading.value = false
    }
  }

  const getPersonEvents = async (treeId, personId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/people/${personId}/events/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch person events'
      return []
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

  const getTimeline = async (treeId, startDate, endDate) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/timeline/`, {
        params: {
          start_date: startDate,
          end_date: endDate
        }
      })
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch timeline'
      return []
    } finally {
      loading.value = false
    }
  }

  return {
    events,
    currentEvent,
    loading,
    error,
    getEvents,
    getEvent,
    createEvent,
    updateEvent,
    deleteEvent,
    addPersonToEvent,
    removePersonFromEvent,
    getPersonEvents,
    getEventPeople,
    getTimeline
  }
}) 