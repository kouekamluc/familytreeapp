import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api'

// Create axios instance with default config
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: true, // Important for handling cookies/sessions
})

// Request interceptor
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('accessToken') || localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config
    if (error.response?.status === 401 && !originalRequest?._retry) {
      originalRequest._retry = true
      try {
        const refreshToken = localStorage.getItem('refreshToken')
        if (!refreshToken) {
          throw new Error('No refresh token available')
        }

        const refreshResponse = await axios.post(`${API_URL}/token/refresh/`, {
          refresh: refreshToken
        })

        const { access } = refreshResponse.data
        localStorage.setItem('accessToken', access)
        localStorage.setItem('token', access)
        originalRequest.headers.Authorization = `Bearer ${access}`
        return api(originalRequest)
      } catch (refreshError) {
        localStorage.removeItem('accessToken')
        localStorage.removeItem('token')
        localStorage.removeItem('refreshToken')
        const path = window.location.pathname
        if (path !== '/login' && path !== '/register' && path !== '/') {
          window.location.href = '/login'
        }
        return Promise.reject(refreshError)
      }
    }
    return Promise.reject(error)
  }
)

// Auth services
export const authService = {
  login: (credentials) => api.post('/auth/login/', credentials),
  register: (userData) => api.post('/auth/register/', userData),
  logout: () => api.post('/auth/logout/'),
  getCurrentUser: () => api.get('/auth/user/'),
  refreshToken: () => api.post('/auth/token/refresh/'),
}

// Person services
export const personService = {
  getAll: (params) => api.get('/people/', { params }),
  getById: (id) => api.get(`/people/${id}/`),
  create: (data) => api.post('/people/', data),
  update: (id, data) => api.put(`/people/${id}/`, data),
  delete: (id) => api.delete(`/people/${id}/`),
  getRelationships: (id) => api.get(`/people/${id}/relationships/`),
  getEvents: (id) => api.get(`/people/${id}/events/`),
  getMedia: (id) => api.get(`/people/${id}/media/`),
  search: (query) => api.get('/people/search/', { params: { q: query } }),
}

// Relationship services
export const relationshipService = {
  getAll: (params) => api.get('/relationships/', { params }),
  getById: (id) => api.get(`/relationships/${id}/`),
  create: (data) => api.post('/relationships/', data),
  update: (id, data) => api.put(`/relationships/${id}/`, data),
  delete: (id) => api.delete(`/relationships/${id}/`),
  getTypes: () => api.get('/relationships/types/'),
}

// Event services
export const eventService = {
  getAll: (params) => api.get('/events/', { params }),
  getById: (id) => api.get(`/events/${id}/`),
  create: (data) => api.post('/events/', data),
  update: (id, data) => api.put(`/events/${id}/`, data),
  delete: (id) => api.delete(`/events/${id}/`),
  addPerson: (eventId, personId) => api.post(`/events/${eventId}/people/`, { person_id: personId }),
  removePerson: (eventId, personId) => api.delete(`/events/${eventId}/people/${personId}/`),
  getTypes: () => api.get('/events/types/'),
}

// Media services
export const mediaService = {
  getAll: (params) => api.get('/media/', { params }),
  getById: (id) => api.get(`/media/${id}/`),
  create: (data) => {
    const formData = new FormData()
    Object.keys(data).forEach(key => {
      formData.append(key, data[key])
    })
    return api.post('/media/', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
  },
  update: (id, data) => {
    const formData = new FormData()
    Object.keys(data).forEach(key => {
      formData.append(key, data[key])
    })
    return api.put(`/media/${id}/`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
  },
  delete: (id) => api.delete(`/media/${id}/`),
  upload: (file, onProgress) => {
    const formData = new FormData()
    formData.append('file', file)
    return api.post('/media/upload/', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
      onUploadProgress: (progressEvent) => {
        const percentCompleted = Math.round((progressEvent.loaded * 100) / progressEvent.total)
        onProgress(percentCompleted)
      },
    })
  },
}

export default api 