import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/api'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    loading: false,
    error: null,
    accessToken: localStorage.getItem('accessToken'),
    refreshToken: localStorage.getItem('refreshToken'),
  }),

  getters: {
    isAuthenticated: (state) => !!state.accessToken,
    currentUser: (state) => state.user,
    isAdmin: (state) => state.user?.is_staff || false
  },

  actions: {
    async login(credentials) {
      this.loading = true
      this.error = null
      try {
        const response = await api.post('/users/login/', credentials)
        const { user, access, refresh } = response.data
        
        // Store tokens
        this.accessToken = access
        this.refreshToken = refresh
        localStorage.setItem('accessToken', access)
        localStorage.setItem('refreshToken', refresh)
        
        // Set default authorization header
        api.defaults.headers.common['Authorization'] = `Bearer ${access}`
        
        // Store user data
        this.user = user
        return user
      } catch (error) {
        this.error = error.response?.data?.error || 'Login failed'
        throw error
      } finally {
        this.loading = false
      }
    },

    async logout() {
      try {
        if (this.refreshToken) {
          await api.post('/users/logout/', { refresh: this.refreshToken })
        }
      } catch (error) {
        console.error('Logout error:', error)
      } finally {
        // Clear tokens and user data
        this.accessToken = null
        this.refreshToken = null
        this.user = null
        localStorage.removeItem('accessToken')
        localStorage.removeItem('refreshToken')
        delete api.defaults.headers.common['Authorization']
      }
    },

    async register(userData) {
      this.loading = true
      this.error = null
      try {
        const response = await api.post('/users/register/', userData)
        return response.data
      } catch (error) {
        this.error = error.response?.data?.error || 'Registration failed'
        throw error
      } finally {
        this.loading = false
      }
    },

    async fetchCurrentUser() {
      if (!this.accessToken) return null
      
      try {
        const response = await api.get('/users/user/')
        this.user = response.data
        return response.data
      } catch (error) {
        if (error.response?.status === 401) {
          // Token might be expired, try to refresh
          await this.refreshAccessToken()
          // Retry fetching user data
          const response = await api.get('/users/user/')
          this.user = response.data
          return response.data
        }
        throw error
      }
    },

    async refreshAccessToken() {
      if (!this.refreshToken) {
        throw new Error('No refresh token available')
      }

      try {
        const response = await api.post('/api/token/refresh/', {
          refresh: this.refreshToken
        })
        
        const { access } = response.data
        this.accessToken = access
        localStorage.setItem('accessToken', access)
        api.defaults.headers.common['Authorization'] = `Bearer ${access}`
        
        return access
      } catch (error) {
        // If refresh fails, clear tokens and user data
        this.accessToken = null
        this.refreshToken = null
        this.user = null
        localStorage.removeItem('accessToken')
        localStorage.removeItem('refreshToken')
        delete api.defaults.headers.common['Authorization']
        throw error
      }
    },

    async checkAuth() {
      if (!this.accessToken) return false
      
      try {
        await this.fetchCurrentUser()
        return true
      } catch (error) {
        return false
      }
    },

    requestPasswordReset(email) {
      // Implementation needed
    },

    resetPassword(token, newPassword) {
      // Implementation needed
    },

    fetchUserProfile() {
      // Implementation needed
    },
  },
}) 