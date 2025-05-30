import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useAuthStore } from './auth'
import { useTreesStore } from './trees'
import { usePeopleStore } from './people'
import { useMediaStore } from './media'
import { useTagsStore } from './tags'
import { useEventsStore } from './events'
import { useBackupsStore } from './backups'
import { useSearchStore } from './search'
import { useNotificationsStore } from './notifications'
import { useSettingsStore } from './settings'
import { useTreeVisualizationStore } from './tree-visualization'
import { useTimelineStore } from './timeline'
import { useImportExportStore } from './import-export'

export const useAppStore = defineStore('app', () => {
  const isInitialized = ref(false)
  const isOnline = ref(navigator.onLine)
  const currentRoute = ref(null)
  const sidebarOpen = ref(false)
  const modalOpen = ref(false)
  const currentModal = ref(null)
  const loading = ref(false)
  const error = ref(null)

  // Initialize all stores
  const authStore = useAuthStore()
  const treesStore = useTreesStore()
  const peopleStore = usePeopleStore()
  const mediaStore = useMediaStore()
  const tagsStore = useTagsStore()
  const eventsStore = useEventsStore()
  const backupsStore = useBackupsStore()
  const searchStore = useSearchStore()
  const notificationsStore = useNotificationsStore()
  const settingsStore = useSettingsStore()
  const treeVisualizationStore = useTreeVisualizationStore()
  const timelineStore = useTimelineStore()
  const importExportStore = useImportExportStore()

  const initialize = async () => {
    try {
      loading.value = true
      error.value = null

      // Load user settings
      await settingsStore.getSettings()

      // Load notifications if user is authenticated
      if (authStore.isAuthenticated) {
        await notificationsStore.getNotifications()
      }

      isInitialized.value = true
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to initialize application'
      return false
    } finally {
      loading.value = false
    }
  }

  const setCurrentRoute = (route) => {
    currentRoute.value = route
  }

  const toggleSidebar = () => {
    sidebarOpen.value = !sidebarOpen.value
  }

  const openModal = (modalName) => {
    modalOpen.value = true
    currentModal.value = modalName
  }

  const closeModal = () => {
    modalOpen.value = false
    currentModal.value = null
  }

  const handleOnlineStatus = () => {
    isOnline.value = navigator.onLine
  }

  const clearError = () => {
    error.value = null
  }

  const resetState = () => {
    isInitialized.value = false
    currentRoute.value = null
    sidebarOpen.value = false
    modalOpen.value = false
    currentModal.value = null
    loading.value = false
    error.value = null

    // Reset all stores
    authStore.$reset()
    treesStore.$reset()
    peopleStore.$reset()
    mediaStore.$reset()
    tagsStore.$reset()
    eventsStore.$reset()
    backupsStore.$reset()
    searchStore.$reset()
    notificationsStore.$reset()
    settingsStore.$reset()
    treeVisualizationStore.$reset()
    timelineStore.$reset()
    importExportStore.$reset()
  }

  // Add event listeners
  window.addEventListener('online', handleOnlineStatus)
  window.addEventListener('offline', handleOnlineStatus)

  return {
    isInitialized,
    isOnline,
    currentRoute,
    sidebarOpen,
    modalOpen,
    currentModal,
    loading,
    error,
    initialize,
    setCurrentRoute,
    toggleSidebar,
    openModal,
    closeModal,
    clearError,
    resetState
  }
}) 