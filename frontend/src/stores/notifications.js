import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useNotificationsStore = defineStore('notifications', () => {
  const notifications = ref([])
  const unreadCount = ref(0)
  const loading = ref(false)
  const error = ref(null)

  const getNotifications = async () => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get('/notifications/')
      notifications.value = response.data.notifications
      unreadCount.value = response.data.unread_count
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch notifications'
      return false
    } finally {
      loading.value = false
    }
  }

  const markAsRead = async (notificationId) => {
    try {
      loading.value = true
      error.value = null
      await api.put(`/notifications/${notificationId}/read/`)
      const notification = notifications.value.find(n => n.id === notificationId)
      if (notification && !notification.read) {
        notification.read = true
        unreadCount.value = Math.max(0, unreadCount.value - 1)
      }
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to mark notification as read'
      return false
    } finally {
      loading.value = false
    }
  }

  const markAllAsRead = async () => {
    try {
      loading.value = true
      error.value = null
      await api.put('/notifications/mark-all-read/')
      notifications.value.forEach(notification => {
        notification.read = true
      })
      unreadCount.value = 0
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to mark all notifications as read'
      return false
    } finally {
      loading.value = false
    }
  }

  const deleteNotification = async (notificationId) => {
    try {
      loading.value = true
      error.value = null
      await api.delete(`/notifications/${notificationId}/`)
      const notification = notifications.value.find(n => n.id === notificationId)
      if (notification && !notification.read) {
        unreadCount.value = Math.max(0, unreadCount.value - 1)
      }
      notifications.value = notifications.value.filter(n => n.id !== notificationId)
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to delete notification'
      return false
    } finally {
      loading.value = false
    }
  }

  const deleteAllNotifications = async () => {
    try {
      loading.value = true
      error.value = null
      await api.delete('/notifications/delete-all/')
      notifications.value = []
      unreadCount.value = 0
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to delete all notifications'
      return false
    } finally {
      loading.value = false
    }
  }

  const getNotificationPreferences = async () => {
    try {
      loading.value = true
      error.value = null
      const response = await api.get('/notifications/preferences/')
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch notification preferences'
      return null
    } finally {
      loading.value = false
    }
  }

  const updateNotificationPreferences = async (preferences) => {
    try {
      loading.value = true
      error.value = null
      const response = await api.put('/notifications/preferences/', preferences)
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to update notification preferences'
      return null
    } finally {
      loading.value = false
    }
  }

  const subscribeToNotifications = async () => {
    try {
      loading.value = true
      error.value = null
      const response = await api.post('/notifications/subscribe/')
      return response.data
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to subscribe to notifications'
      return null
    } finally {
      loading.value = false
    }
  }

  const unsubscribeFromNotifications = async () => {
    try {
      loading.value = true
      error.value = null
      await api.post('/notifications/unsubscribe/')
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to unsubscribe from notifications'
      return false
    } finally {
      loading.value = false
    }
  }

  return {
    notifications,
    unreadCount,
    loading,
    error,
    getNotifications,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    deleteAllNotifications,
    getNotificationPreferences,
    updateNotificationPreferences,
    subscribeToNotifications,
    unsubscribeFromNotifications
  }
}) 