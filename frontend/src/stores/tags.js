import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useTagsStore = defineStore('tags', () => {
  const tags = ref([])
  const loading = ref(false)
  const error = ref(null)

  const getTags = async (treeId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/tags/`)
      tags.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch tags'
      return false
    } finally {
      loading.value = false
    }
  }

  const createTag = async (treeId, tagData) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post(`/trees/${treeId}/tags/`, tagData)
      tags.value.push(response.data)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to create tag'
      return null
    } finally {
      loading.value = false
    }
  }

  const updateTag = async (treeId, tagId, tagData) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put(`/trees/${treeId}/tags/${tagId}/`, tagData)
      const index = tags.value.findIndex(tag => tag.id === tagId)
      if (index !== -1) {
        tags.value[index] = response.data
      }
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update tag'
      return null
    } finally {
      loading.value = false
    }
  }

  const deleteTag = async (treeId, tagId) => {
    try {
      loading.value = true
      error.value = null
      await api.delete(`/trees/${treeId}/tags/${tagId}/`)
      tags.value = tags.value.filter(tag => tag.id !== tagId)
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to delete tag'
      return false
    } finally {
      loading.value = false
    }
  }

  const addTagToPerson = async (treeId, tagId, personId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post(`/trees/${treeId}/tags/${tagId}/people/`, {
        person_id: personId
      })
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to add tag to person'
      return null
    } finally {
      loading.value = false
    }
  }

  const removeTagFromPerson = async (treeId, tagId, personId) => {
    try {
      loading.value = true
      error.value = null
      await api.delete(`/trees/${treeId}/tags/${tagId}/people/${personId}/`)
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to remove tag from person'
      return false
    } finally {
      loading.value = false
    }
  }

  const getPersonTags = async (treeId, personId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/people/${personId}/tags/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch person tags'
      return []
    } finally {
      loading.value = false
    }
  }

  const getTaggedPeople = async (treeId, tagId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/tags/${tagId}/people/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch tagged people'
      return []
    } finally {
      loading.value = false
    }
  }

  return {
    tags,
    loading,
    error,
    getTags,
    createTag,
    updateTag,
    deleteTag,
    addTagToPerson,
    removeTagFromPerson,
    getPersonTags,
    getTaggedPeople
  }
}) 