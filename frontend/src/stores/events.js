import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/api'
import { eventService } from '@/services/api'

export const useEventsStore = defineStore('events', {
  state: () => ({
    events: [],
    currentEvent: null,
    loading: false,
    error: null,
    filters: {
      search: '',
      eventType: '',
      dateRange: null,
      relatedPerson: null,
      location: '',
    },
    pagination: {
      page: 1,
      pageSize: 10,
      total: 0,
    },
  }),

  getters: {
    filteredEvents: (state) => {
      let filtered = [...state.events]
      
      if (state.filters.search) {
        const search = state.filters.search.toLowerCase()
        filtered = filtered.filter(event => 
          event.title.toLowerCase().includes(search) ||
          event.description?.toLowerCase().includes(search) ||
          event.location?.toLowerCase().includes(search)
        )
      }
      
      if (state.filters.eventType) {
        filtered = filtered.filter(event => event.event_type === state.filters.eventType)
      }
      
      if (state.filters.dateRange) {
        const { start, end } = state.filters.dateRange
        filtered = filtered.filter(event => {
          const eventDate = new Date(event.date)
          return eventDate >= start && eventDate <= end
        })
      }
      
      if (state.filters.relatedPerson) {
        filtered = filtered.filter(event => 
          event.related_people.some(person => person.id === state.filters.relatedPerson)
        )
      }

      if (state.filters.location) {
        const location = state.filters.location.toLowerCase()
        filtered = filtered.filter(event => 
          event.location?.toLowerCase().includes(location)
        )
      }
      
      return filtered
    },

    sortedEvents: (state) => {
      return [...state.events].sort((a, b) => {
        return new Date(b.date) - new Date(a.date)
      })
    },

    upcomingEvents: (state) => {
      const now = new Date()
      return state.events.filter(event => new Date(event.date) > now)
    },

    pastEvents: (state) => {
      const now = new Date()
      return state.events.filter(event => new Date(event.date) <= now)
    },
  },

  actions: {
    async fetchEvents(treeId) {
      this.loading = true
      try {
        const response = await api.get('/events/', { params: { tree_id: treeId } })
        const data = response.data
        this.events = Array.isArray(data) ? data : (data.results || [])
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch events'
        console.error('Error fetching events:', error)
      } finally {
        this.loading = false
      }
    },

    async fetchEvent(id) {
      this.loading = true
      this.error = null
      try {
        const response = await eventService.getById(id)
        this.currentEvent = response.data
        return response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch event'
        throw error
      } finally {
        this.loading = false
      }
    },

    async createEvent(eventData) {
      this.loading = true
      this.error = null
      try {
        const response = await api.post('/events/', eventData)
        this.events.push(response.data)
        return response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to create event'
        console.error('Error creating event:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async updateEvent(eventId, eventData) {
      this.loading = true
      this.error = null
      try {
        const response = await api.put(`/events/${eventId}/`, eventData)
        const index = this.events.findIndex(e => e.id === eventId)
        if (index !== -1) {
          this.events[index] = response.data
        }
        if (this.currentEvent?.id === eventId) {
          this.currentEvent = response.data
        }
        return response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to update event'
        console.error('Error updating event:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async deleteEvent(eventId) {
      this.loading = true
      this.error = null
      try {
        await api.delete(`/events/${eventId}/`)
        this.events = this.events.filter(e => e.id !== eventId)
        if (this.currentEvent?.id === eventId) {
          this.currentEvent = null
        }
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to delete event'
        console.error('Error deleting event:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    setFilters(filters) {
      this.filters = { ...this.filters, ...filters }
      this.pagination.page = 1 // Reset to first page when filters change
    },

    setPagination(pagination) {
      this.pagination = { ...this.pagination, ...pagination }
    },

    async addPersonToEvent(eventId, personId) {
      this.loading = true
      this.error = null
      try {
        const response = await eventService.addPerson(eventId, personId)
        const index = this.events.findIndex(e => e.id === eventId)
        if (index !== -1) {
          this.events[index] = response.data
        }
        if (this.currentEvent?.id === eventId) {
          this.currentEvent = response.data
        }
        return response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to add person to event'
        throw error
      } finally {
        this.loading = false
      }
    },

    async removePersonFromEvent(eventId, personId) {
      this.loading = true
      this.error = null
      try {
        const response = await eventService.removePerson(eventId, personId)
        const index = this.events.findIndex(e => e.id === eventId)
        if (index !== -1) {
          this.events[index] = response.data
        }
        if (this.currentEvent?.id === eventId) {
          this.currentEvent = response.data
        }
        return response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to remove person from event'
        throw error
      } finally {
        this.loading = false
      }
    },
  },
}) 