import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useSearchStore = defineStore('search', () => {
  const searchResults = ref([])
  const loading = ref(false)
  const error = ref(null)
  const searchQuery = ref('')
  const searchFilters = ref({
    type: 'all', // all, people, events, media
    dateRange: null,
    tags: [],
    mediaTypes: []
  })

  const search = async (treeId, query, filters = {}) => {
    try {
      loading.value = true
      error.value = null
      searchQuery.value = query
      searchFilters.value = { ...searchFilters.value, ...filters }

      const response = await api.get(`/trees/${treeId}/search/`, {
        params: {
          q: query,
          ...searchFilters.value
        }
      })
      searchResults.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to perform search'
      return false
    } finally {
      loading.value = false
    }
  }

  const searchPeople = async (treeId, query, filters = {}) => {
    try {
      loading.value = true
      error.value = null
      searchQuery.value = query
      searchFilters.value = { ...searchFilters.value, ...filters, type: 'people' }

      const response = await api.get(`/trees/${treeId}/search/people/`, {
        params: {
          q: query,
          ...filters
        }
      })
      searchResults.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to search people'
      return false
    } finally {
      loading.value = false
    }
  }

  const searchEvents = async (treeId, query, filters = {}) => {
    try {
      loading.value = true
      error.value = null
      searchQuery.value = query
      searchFilters.value = { ...searchFilters.value, ...filters, type: 'events' }

      const response = await api.get(`/trees/${treeId}/search/events/`, {
        params: {
          q: query,
          ...filters
        }
      })
      searchResults.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to search events'
      return false
    } finally {
      loading.value = false
    }
  }

  const searchMedia = async (treeId, query, filters = {}) => {
    try {
      loading.value = true
      error.value = null
      searchQuery.value = query
      searchFilters.value = { ...searchFilters.value, ...filters, type: 'media' }

      const response = await api.get(`/trees/${treeId}/search/media/`, {
        params: {
          q: query,
          ...filters
        }
      })
      searchResults.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to search media'
      return false
    } finally {
      loading.value = false
    }
  }

  const getSuggestions = async (treeId, query) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/search/suggestions/`, {
        params: { q: query }
      })
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to get suggestions'
      return []
    } finally {
      loading.value = false
    }
  }

  const clearSearch = () => {
    searchResults.value = []
    searchQuery.value = ''
    searchFilters.value = {
      type: 'all',
      dateRange: null,
      tags: [],
      mediaTypes: []
    }
  }

  return {
    searchResults,
    loading,
    error,
    searchQuery,
    searchFilters,
    search,
    searchPeople,
    searchEvents,
    searchMedia,
    getSuggestions,
    clearSearch
  }
}) 