import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useImportExportStore = defineStore('importExport', () => {
  const importStatus = ref(null)
  const exportStatus = ref(null)
  const importProgress = ref(0)
  const exportProgress = ref(0)
  const loading = ref(false)
  const error = ref(null)

  const importData = async (treeId, file, options = {}) => {
    try {
      loading.value = true
      error.value = null
      importProgress.value = 0
      importStatus.value = 'uploading'

      const formData = new FormData()
      formData.append('file', file)
      formData.append('options', JSON.stringify(options))

      const response = await api.post(`/trees/${treeId}/import/`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        },
        onUploadProgress: (progressEvent) => {
          importProgress.value = Math.round((progressEvent.loaded * 100) / progressEvent.total)
        }
      })

      importStatus.value = 'processing'
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to import data'
      importStatus.value = 'error'
      return null
    } finally {
      loading.value = false
    }
  }

  const exportData = async (treeId, format = 'json', options = {}) => {
    try {
      loading.value = true
      error.value = null
      exportProgress.value = 0
      exportStatus.value = 'preparing'

      const response = await api.get(`/trees/${treeId}/export/`, {
        params: {
          format,
          ...options
        },
        responseType: 'blob',
        onDownloadProgress: (progressEvent) => {
          exportProgress.value = Math.round((progressEvent.loaded * 100) / progressEvent.total)
        }
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

      exportStatus.value = 'completed'
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to export data'
      exportStatus.value = 'error'
      return false
    } finally {
      loading.value = false
    }
  }

  const getImportStatus = async (treeId, importId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/import/${importId}/status/`)
      importStatus.value = response.data.status
      importProgress.value = response.data.progress
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to get import status'
      return null
    } finally {
      loading.value = false
    }
  }

  const getExportStatus = async (treeId, exportId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/export/${exportId}/status/`)
      exportStatus.value = response.data.status
      exportProgress.value = response.data.progress
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to get export status'
      return null
    } finally {
      loading.value = false
    }
  }

  const cancelImport = async (treeId, importId) => {
    try {
      loading.value = true
      error.value = null
      await api.post(`/trees/${treeId}/import/${importId}/cancel/`)
      importStatus.value = 'cancelled'
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to cancel import'
      return false
    } finally {
      loading.value = false
    }
  }

  const cancelExport = async (treeId, exportId) => {
    try {
      loading.value = true
      error.value = null
      await api.post(`/trees/${treeId}/export/${exportId}/cancel/`)
      exportStatus.value = 'cancelled'
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to cancel export'
      return false
    } finally {
      loading.value = false
    }
  }

  const validateImportFile = async (file) => {
    try {
      loading.value = true
      error.value = null
      const formData = new FormData()
      formData.append('file', file)

      const response = await api.post('/validate-import/', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      })
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to validate import file'
      return null
    } finally {
      loading.value = false
    }
  }

  const getSupportedFormats = async () => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get('/supported-formats/')
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to get supported formats'
      return []
    } finally {
      loading.value = false
    }
  }

  const resetStatus = () => {
    importStatus.value = null
    exportStatus.value = null
    importProgress.value = 0
    exportProgress.value = 0
    error.value = null
  }

  return {
    importStatus,
    exportStatus,
    importProgress,
    exportProgress,
    loading,
    error,
    importData,
    exportData,
    getImportStatus,
    getExportStatus,
    cancelImport,
    cancelExport,
    validateImportFile,
    getSupportedFormats,
    resetStatus
  }
}) 