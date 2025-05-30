import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import axios from 'axios'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const token = ref(localStorage.getItem('token'))
  const loading = ref(false)
  const error = ref(null)

  const isAuthenticated = computed(() => !!token.value)

  // Set axios default headers when token changes
  const setAuthHeader = (newToken) => {
    if (newToken) {
      axios.defaults.headers.common['Authorization'] = `Bearer ${newToken}`
    } else {
      delete axios.defaults.headers.common['Authorization']
    }
  }

  // Initialize auth state
  if (token.value) {
    setAuthHeader(token.value)
  }

  const login = async (credentials) => {
    try {
      loading.value = true
      error.value = null
      const response = await axios.post('/api/auth/login/', credentials)
      token.value = response.data.token
      user.value = response.data.user
      localStorage.setItem('token', token.value)
      setAuthHeader(token.value)
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Login failed'
      return false
    } finally {
      loading.value = false
    }
  }

  const register = async (userData) => {
    try {
      loading.value = true
      error.value = null
      const response = await axios.post('/api/auth/register/', userData)
      token.value = response.data.token
      user.value = response.data.user
      localStorage.setItem('token', token.value)
      setAuthHeader(token.value)
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Registration failed'
      return false
    } finally {
      loading.value = false
    }
  }

  const logout = () => {
    token.value = null
    user.value = null
    localStorage.removeItem('token')
    setAuthHeader(null)
  }

  const requestPasswordReset = async (email) => {
    try {
      loading.value = true
      error.value = null
      await axios.post('/api/auth/password-reset/', { email })
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Password reset request failed'
      return false
    } finally {
      loading.value = false
    }
  }

  const resetPassword = async (token, newPassword) => {
    try {
      loading.value = true
      error.value = null
      await axios.post('/api/auth/password-reset/confirm/', {
        token,
        password: newPassword
      })
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Password reset failed'
      return false
    } finally {
      loading.value = false
    }
  }

  const fetchUserProfile = async () => {
    try {
      loading.value = true
      error.value = null
      const response = await axios.get('/api/auth/profile/')
      user.value = response.data
      return true
    } catch (err) {
      error.value = err.response?.data?.message || 'Failed to fetch profile'
      return false
    } finally {
      loading.value = false
    }
  }

  return {
    user,
    token,
    loading,
    error,
    isAuthenticated,
    login,
    register,
    logout,
    requestPasswordReset,
    resetPassword,
    fetchUserProfile
  }
}) 