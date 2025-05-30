import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useTreesStore = defineStore('trees', () => {
  const trees = ref([])
  const currentTree = ref(null)
  const loading = ref(false)
  const error = ref(null)

  const getTrees = async () => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get('/trees/')
      trees.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch trees'
      return false
    } finally {
      loading.value = false
    }
  }

  const getTree = async (id) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${id}/`)
      currentTree.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch tree'
      return false
    } finally {
      loading.value = false
    }
  }

  const createTree = async (treeData) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post('/trees/', treeData)
      trees.value.push(response.data)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to create tree'
      return null
    } finally {
      loading.value = false
    }
  }

  const updateTree = async (id, treeData) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put(`/trees/${id}/`, treeData)
      const index = trees.value.findIndex(tree => tree.id === id)
      if (index !== -1) {
        trees.value[index] = response.data
      }
      if (currentTree.value?.id === id) {
        currentTree.value = response.data
      }
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update tree'
      return null
    } finally {
      loading.value = false
    }
  }

  const deleteTree = async (id) => {
    try {
      loading.value = true
      error.value = null
      await api.delete(`/trees/${id}/`)
      trees.value = trees.value.filter(tree => tree.id !== id)
      if (currentTree.value?.id === id) {
        currentTree.value = null
      }
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to delete tree'
      return false
    } finally {
      loading.value = false
    }
  }

  const shareTree = async (id, shareData) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post(`/trees/${id}/share/`, shareData)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to share tree'
      return null
    } finally {
      loading.value = false
    }
  }

  const getTreeMembers = async (id) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${id}/members/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch tree members'
      return []
    } finally {
      loading.value = false
    }
  }

  const updateMemberRole = async (treeId, memberId, role) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put(`/trees/${treeId}/members/${memberId}/`, { role })
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update member role'
      return null
    } finally {
      loading.value = false
    }
  }

  const removeMember = async (treeId, memberId) => {
    try {
      loading.value = true
      error.value = null
      await api.delete(`/trees/${treeId}/members/${memberId}/`)
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to remove member'
      return false
    } finally {
      loading.value = false
    }
  }

  const getTreeSettings = async (id) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${id}/settings/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch tree settings'
      return null
    } finally {
      loading.value = false
    }
  }

  const updateTreeSettings = async (id, settings) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put(`/trees/${id}/settings/`, settings)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update tree settings'
      return null
    } finally {
      loading.value = false
    }
  }

  return {
    trees,
    currentTree,
    loading,
    error,
    getTrees,
    getTree,
    createTree,
    updateTree,
    deleteTree,
    shareTree,
    getTreeMembers,
    updateMemberRole,
    removeMember,
    getTreeSettings,
    updateTreeSettings
  }
}) 