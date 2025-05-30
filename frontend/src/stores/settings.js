import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useSettingsStore = defineStore('settings', () => {
  const settings = ref({
    theme: 'light',
    language: 'en',
    dateFormat: 'MM/DD/YYYY',
    timeFormat: '12h',
    privacy: {
      profileVisibility: 'public',
      treeVisibility: 'private',
      showBirthDates: true,
      showDeathDates: true,
      showLivingPeople: true
    },
    notifications: {
      email: true,
      browser: true,
      treeUpdates: true,
      relationshipRequests: true,
      mediaUploads: true,
      comments: true
    },
    display: {
      showPhotos: true,
      showEvents: true,
      showTags: true,
      showTimeline: true,
      treeLayout: 'horizontal',
      personCardStyle: 'compact'
    },
    importExport: {
      defaultFormat: 'json',
      includeMedia: true,
      includeEvents: true,
      includeTags: true
    }
  })
  const loading = ref(false)
  const error = ref(null)

  const getSettings = async () => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get('/settings/')
      settings.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch settings'
      return false
    } finally {
      loading.value = false
    }
  }

  const updateSettings = async (newSettings) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put('/settings/', newSettings)
      settings.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update settings'
      return false
    } finally {
      loading.value = false
    }
  }

  const updateTheme = async (theme) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put('/settings/theme/', { theme })
      settings.value.theme = response.data.theme
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update theme'
      return false
    } finally {
      loading.value = false
    }
  }

  const updateLanguage = async (language) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put('/settings/language/', { language })
      settings.value.language = response.data.language
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update language'
      return false
    } finally {
      loading.value = false
    }
  }

  const updatePrivacySettings = async (privacySettings) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put('/settings/privacy/', privacySettings)
      settings.value.privacy = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update privacy settings'
      return false
    } finally {
      loading.value = false
    }
  }

  const updateNotificationSettings = async (notificationSettings) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put('/settings/notifications/', notificationSettings)
      settings.value.notifications = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update notification settings'
      return false
    } finally {
      loading.value = false
    }
  }

  const updateDisplaySettings = async (displaySettings) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put('/settings/display/', displaySettings)
      settings.value.display = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update display settings'
      return false
    } finally {
      loading.value = false
    }
  }

  const updateImportExportSettings = async (importExportSettings) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put('/settings/import-export/', importExportSettings)
      settings.value.importExport = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update import/export settings'
      return false
    } finally {
      loading.value = false
    }
  }

  const resetSettings = async () => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post('/settings/reset/')
      settings.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to reset settings'
      return false
    } finally {
      loading.value = false
    }
  }

  return {
    settings,
    loading,
    error,
    getSettings,
    updateSettings,
    updateTheme,
    updateLanguage,
    updatePrivacySettings,
    updateNotificationSettings,
    updateDisplaySettings,
    updateImportExportSettings,
    resetSettings
  }
}) 