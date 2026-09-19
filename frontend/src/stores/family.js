import { defineStore } from 'pinia'
import api from '@/api'

export const useFamilyStore = defineStore('family', {
  state: () => ({
    trees: [],
    currentTree: null,
    loading: false,
    error: null
  }),

  actions: {
    async fetchTrees() {
      this.loading = true
      this.error = null
      try {
        const response = await api.get('/trees/')
        this.trees = response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch family trees'
        console.error('Error fetching trees:', error)
      } finally {
        this.loading = false
      }
    },

    async createTree(treeData) {
      this.loading = true
      this.error = null
      try {
        const response = await api.post('/trees/', treeData)
        this.trees.push(response.data)
        return response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to create family tree'
        console.error('Error creating tree:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchTreeDetails(treeId) {
      this.loading = true
      this.error = null
      try {
        const response = await api.get(`/trees/${treeId}/`)
        this.currentTree = response.data
        return response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch tree details'
        console.error('Error fetching tree details:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async addTreeMember(treeId, userId) {
      this.loading = true
      this.error = null
      try {
        const response = await api.post(`/trees/${treeId}/add_member/`, { user_id: userId })
        return response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to add member'
        console.error('Error adding member:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async removeTreeMember(treeId, userId) {
      this.loading = true
      this.error = null
      try {
        const response = await api.post(`/trees/${treeId}/remove_member/`, { user_id: userId })
        return response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to remove member'
        console.error('Error removing member:', error)
        throw error
      } finally {
        this.loading = false
      }
    }
  }
}) 