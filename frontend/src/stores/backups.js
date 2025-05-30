import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useBackupsStore = defineStore('backups', () => {
  const backups = ref([])
  const loading = ref(false)
  const error = ref(null)

  const getBackups = async (treeId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/backups/`)
      backups.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch backups'
      return false
    } finally {
      loading.value = false
    }
  }

  const createBackup = async (treeId, backupData = {}) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post(`/trees/${treeId}/backups/`, backupData)
      backups.value.push(response.data)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to create backup'
      return null
    } finally {
      loading.value = false
    }
  }

  const deleteBackup = async (treeId, backupId) => {
    try {
      loading.value = true
      error.value = null
      await api.delete(`/trees/${treeId}/backups/${backupId}/`)
      backups.value = backups.value.filter(backup => backup.id !== backupId)
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to delete backup'
      return false
    } finally {
      loading.value = false
    }
  }

  const restoreBackup = async (treeId, backupId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post(`/trees/${treeId}/backups/${backupId}/restore/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to restore backup'
      return null
    } finally {
      loading.value = false
    }
  }

  const downloadBackup = async (treeId, backupId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/backups/${backupId}/download/`, {
        responseType: 'blob'
      })
      
      // Create a download link
      const url = window.URL.createObjectURL(new Blob([response.data]))
      const link = document.createElement('a')
      link.href = url
      link.setAttribute('download', `backup-${backupId}.json`)
      document.body.appendChild(link)
      link.click()
      link.remove()
      window.URL.revokeObjectURL(url)
      
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to download backup'
      return false
    } finally {
      loading.value = false
    }
  }

  const uploadBackup = async (treeId, file) => {
    try {
      loading.value = true
      error.value = null
      const formData = new FormData()
      formData.append('file', file)
      
      const response = await api.post(`/trees/${treeId}/backups/upload/`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      })
      backups.value.push(response.data)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to upload backup'
      return null
    } finally {
      loading.value = false
    }
  }

  const getBackupStatus = async (treeId, backupId) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get(`/trees/${treeId}/backups/${backupId}/status/`)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch backup status'
      return null
    } finally {
      loading.value = false
    }
  }

  return {
    backups,
    loading,
    error,
    getBackups,
    createBackup,
    deleteBackup,
    restoreBackup,
    downloadBackup,
    uploadBackup,
    getBackupStatus
  }
}) 