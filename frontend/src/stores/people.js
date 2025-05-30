import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const usePeopleStore = defineStore('people', () => {
  const people = ref([])
  const currentPerson = ref(null)
  const loading = ref(false)
  const error = ref(null)

  const getPeople = async (treeId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/people/`)
      people.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch people'
      return false
    } finally {
      loading.value = false
    }
  }

  const getPerson = async (treeId, personId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/people/${personId}/`)
      currentPerson.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch person'
      return false
    } finally {
      loading.value = false
    }
  }

  const createPerson = async (treeId, personData) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post(`/trees/${treeId}/people/`, personData)
      people.value.push(response.data)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to create person'
      return null
    } finally {
      loading.value = false
    }
  }

  const updatePerson = async (treeId, personId, personData) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put(`/trees/${treeId}/people/${personId}/`, personData)
      const index = people.value.findIndex(person => person.id === personId)
      if (index !== -1) {
        people.value[index] = response.data
      }
      if (currentPerson.value?.id === personId) {
        currentPerson.value = response.data
      }
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update person'
      return null
    } finally {
      loading.value = false
    }
  }

  const deletePerson = async (treeId, personId) => {
    try {
      loading.value = true
      error.value = null
      await api.delete(`/trees/${treeId}/people/${personId}/`)
      people.value = people.value.filter(person => person.id !== personId)
      if (currentPerson.value?.id === personId) {
        currentPerson.value = null
      }
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to delete person'
      return false
    } finally {
      loading.value = false
    }
  }

  const addRelationship = async (treeId, personId, relationshipData) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post(`/trees/${treeId}/people/${personId}/relationships/`, relationshipData)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to add relationship'
      return null
    } finally {
      loading.value = false
    }
  }

  const updateRelationship = async (treeId, personId, relationshipId, relationshipData) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put(`/trees/${treeId}/people/${personId}/relationships/${relationshipId}/`, relationshipData)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update relationship'
      return null
    } finally {
      loading.value = false
    }
  }

  const deleteRelationship = async (treeId, personId, relationshipId) => {
    try {
      loading.value = true
      error.value = null
      await api.delete(`/trees/${treeId}/people/${personId}/relationships/${relationshipId}/`)
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to delete relationship'
      return false
    } finally {
      loading.value = false
    }
  }

  const getFamilyGroup = async (treeId, personId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/people/${personId}/family-group/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch family group'
      return null
    } finally {
      loading.value = false
    }
  }

  const mergePeople = async (treeId, sourceId, targetId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post(`/trees/${treeId}/people/merge/`, {
        source_person_id: sourceId,
        target_person_id: targetId
      })
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to merge people'
      return null
    } finally {
      loading.value = false
    }
  }

  return {
    people,
    currentPerson,
    loading,
    error,
    getPeople,
    getPerson,
    createPerson,
    updatePerson,
    deletePerson,
    addRelationship,
    updateRelationship,
    deleteRelationship,
    getFamilyGroup,
    mergePeople
  }
}) 