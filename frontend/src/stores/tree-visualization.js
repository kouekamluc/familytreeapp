import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useTreeVisualizationStore = defineStore('treeVisualization', () => {
  const treeData = ref(null)
  const layout = ref('horizontal')
  const zoom = ref(1)
  const pan = ref({ x: 0, y: 0 })
  const selectedNode = ref(null)
  const highlightedNodes = ref([])
  const loading = ref(false)
  const error = ref(null)

  const getTreeData = async (treeId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/visualization/`)
      treeData.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch tree data'
      return false
    } finally {
      loading.value = false
    }
  }

  const updateLayout = (newLayout) => {
    layout.value = newLayout
  }

  const setZoom = (newZoom) => {
    zoom.value = Math.max(0.1, Math.min(2, newZoom))
  }

  const setPan = (newPan) => {
    pan.value = newPan
  }

  const resetView = () => {
    zoom.value = 1
    pan.value = { x: 0, y: 0 }
  }

  const selectNode = (node) => {
    selectedNode.value = node
  }

  const clearSelection = () => {
    selectedNode.value = null
  }

  const highlightNodes = (nodes) => {
    highlightedNodes.value = nodes
  }

  const clearHighlights = () => {
    highlightedNodes.value = []
  }

  const getNodeDetails = async (treeId, nodeId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/nodes/${nodeId}/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch node details'
      return null
    } finally {
      loading.value = false
    }
  }

  const getNodeRelationships = async (treeId, nodeId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/nodes/${nodeId}/relationships/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch node relationships'
      return []
    } finally {
      loading.value = false
    }
  }

  const getNodeEvents = async (treeId, nodeId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/nodes/${nodeId}/events/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch node events'
      return []
    } finally {
      loading.value = false
    }
  }

  const getNodeMedia = async (treeId, nodeId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/nodes/${nodeId}/media/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch node media'
      return []
    } finally {
      loading.value = false
    }
  }

  const exportTreeImage = async (treeId, format = 'png') => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/export/image/`, {
        params: { format },
        responseType: 'blob'
      })
      
      // Create a download link
      const url = window.URL.createObjectURL(new Blob([response.data]))
      const link = document.createElement('a')
      link.href = url
      link.setAttribute('download', `tree-${treeId}.${format}`)
      document.body.appendChild(link)
      link.click()
      link.remove()
      window.URL.revokeObjectURL(url)
      
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to export tree image'
      return false
    } finally {
      loading.value = false
    }
  }

  const exportTreePDF = async (treeId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/export/pdf/`, {
        responseType: 'blob'
      })
      
      // Create a download link
      const url = window.URL.createObjectURL(new Blob([response.data]))
      const link = document.createElement('a')
      link.href = url
      link.setAttribute('download', `tree-${treeId}.pdf`)
      document.body.appendChild(link)
      link.click()
      link.remove()
      window.URL.revokeObjectURL(url)
      
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to export tree PDF'
      return false
    } finally {
      loading.value = false
    }
  }

  return {
    treeData,
    layout,
    zoom,
    pan,
    selectedNode,
    highlightedNodes,
    loading,
    error,
    getTreeData,
    updateLayout,
    setZoom,
    setPan,
    resetView,
    selectNode,
    clearSelection,
    highlightNodes,
    clearHighlights,
    getNodeDetails,
    getNodeRelationships,
    getNodeEvents,
    getNodeMedia,
    exportTreeImage,
    exportTreePDF
  }
}) 