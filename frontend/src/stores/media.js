import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useMediaStore = defineStore('media', () => {
  const media = ref([])
  const currentMedia = ref(null)
  const loading = ref(false)
  const error = ref(null)

  const getMedia = async (treeId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/media/`)
      media.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch media'
      return false
    } finally {
      loading.value = false
    }
  }

  const getMediaItem = async (treeId, mediaId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/media/${mediaId}/`)
      currentMedia.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch media item'
      return false
    } finally {
      loading.value = false
    }
  }

  const uploadMedia = async (treeId, file, metadata) => {
    try {
      loading.value = true
      error.value = null
      const formData = new FormData()
      formData.append('file', file)
      formData.append('metadata', JSON.stringify(metadata))
      
      const response = await api.post(`/trees/${treeId}/media/upload/`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      })
      media.value.push(response.data)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to upload media'
      return null
    } finally {
      loading.value = false
    }
  }

  const updateMedia = async (treeId, mediaId, mediaData) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put(`/trees/${treeId}/media/${mediaId}/`, mediaData)
      const index = media.value.findIndex(item => item.id === mediaId)
      if (index !== -1) {
        media.value[index] = response.data
      }
      if (currentMedia.value?.id === mediaId) {
        currentMedia.value = response.data
      }
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update media'
      return null
    } finally {
      loading.value = false
    }
  }

  const deleteMedia = async (treeId, mediaId) => {
    try {
      loading.value = true
      error.value = null
      await api.delete(`/trees/${treeId}/media/${mediaId}/`)
      media.value = media.value.filter(item => item.id !== mediaId)
      if (currentMedia.value?.id === mediaId) {
        currentMedia.value = null
      }
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to delete media'
      return false
    } finally {
      loading.value = false
    }
  }

  const linkMediaToPerson = async (treeId, mediaId, personId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post(`/trees/${treeId}/media/${mediaId}/link/`, {
        person_id: personId
      })
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to link media to person'
      return null
    } finally {
      loading.value = false
    }
  }

  const unlinkMediaFromPerson = async (treeId, mediaId, personId) => {
    try {
      loading.value = true
      error.value = null
      await api.delete(`/trees/${treeId}/media/${mediaId}/link/${personId}/`)
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to unlink media from person'
      return false
    } finally {
      loading.value = false
    }
  }

  const getPersonMedia = async (treeId, personId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/people/${personId}/media/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch person media'
      return []
    } finally {
      loading.value = false
    }
  }

  const getMediaUrl = (mediaId) => {
    return `${api.defaults.baseURL}/media/${mediaId}/`
  }

  return {
    media,
    currentMedia,
    loading,
    error,
    getMedia,
    getMediaItem,
    uploadMedia,
    updateMedia,
    deleteMedia,
    linkMediaToPerson,
    unlinkMediaFromPerson,
    getPersonMedia,
    getMediaUrl
  }
}) 