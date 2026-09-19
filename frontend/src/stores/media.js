import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/api'
import { mediaService } from '@/services/api'

export const useMediaStore = defineStore('media', {
  state: () => ({
    mediaItems: [],
    currentMedia: null,
    loading: false,
    error: null,
    filters: {
      search: '',
      mediaType: '',
      dateRange: null,
      relatedPerson: null,
    },
    pagination: {
      page: 1,
      pageSize: 12, // Using 12 for grid layout (3x4 or 4x3)
      total: 0,
    },
    uploadProgress: {},
  }),

  getters: {
    filteredMedia: (state) => {
      let filtered = [...state.mediaItems];
      
      if (state.filters.search) {
        const search = state.filters.search.toLowerCase();
        filtered = filtered.filter(media => 
          media.title.toLowerCase().includes(search) ||
          media.description?.toLowerCase().includes(search) ||
          media.location?.toLowerCase().includes(search)
        );
      }
      
      if (state.filters.mediaType) {
        filtered = filtered.filter(media => media.media_type === state.filters.mediaType);
      }
      
      if (state.filters.dateRange) {
        const { start, end } = state.filters.dateRange;
        filtered = filtered.filter(media => {
          const mediaDate = new Date(media.date);
          return mediaDate >= start && mediaDate <= end;
        });
      }
      
      if (state.filters.relatedPerson) {
        filtered = filtered.filter(media => 
          media.related_people.some(person => person.id === state.filters.relatedPerson)
        );
      }
      
      return filtered;
    },

    uploadProgressPercentage: (state) => (mediaId) => {
      return state.uploadProgress[mediaId] || 0;
    },
  },

  actions: {
    async fetchMedia(treeId) {
      this.loading = true
      this.error = null
      try {
        const response = await api.get('/media/', { params: { tree_id: treeId } })
        const data = response.data
        this.mediaItems = Array.isArray(data) ? data : (data.results || [])
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch media'
        console.error('Error fetching media:', error)
      } finally {
        this.loading = false
      }
    },

    async fetchPersonMedia(personId, mediaType = null) {
      this.loading = true
      this.error = null
      try {
        const params = { person_id: personId }
        if (mediaType) params.media_type = mediaType
        const response = await api.get('/media/', { params })
        const data = response.data
        return Array.isArray(data) ? data : (data.results || [])
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch person media'
        console.error('Error fetching person media:', error)
        return []
      } finally {
        this.loading = false
      }
    },

    async fetchMediaItem(id) {
      this.loading = true;
      this.error = null;
      try {
        const response = await mediaService.getById(id);
        this.currentMedia = response.data;
        return response.data;
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch media item';
        throw error;
      } finally {
        this.loading = false;
      }
    },

    async uploadMedia(mediaData) {
      this.loading = true
      this.error = null
      try {
        const formData = new FormData()
        Object.keys(mediaData).forEach(key => {
          if (key === 'file') {
            formData.append(key, mediaData[key])
          } else if (Array.isArray(mediaData[key])) {
            mediaData[key].forEach(value => {
              formData.append(`${key}[]`, value)
            })
          } else {
            formData.append(key, mediaData[key])
          }
        })

        const response = await api.post('/media/', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        })
        this.mediaItems.push(response.data)
        return response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to upload media'
        console.error('Error uploading media:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async updateMedia(mediaId, mediaData) {
      this.loading = true
      this.error = null
      try {
        const formData = new FormData()
        Object.keys(mediaData).forEach(key => {
          if (key === 'file' && mediaData[key]) {
            formData.append(key, mediaData[key])
          } else if (Array.isArray(mediaData[key])) {
            mediaData[key].forEach(value => {
              formData.append(`${key}[]`, value)
            })
          } else {
            formData.append(key, mediaData[key])
          }
        })

        const response = await api.put(`/media/${mediaId}/`, formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        })
        const index = this.mediaItems.findIndex(m => m.id === mediaId)
        if (index !== -1) {
          this.mediaItems[index] = response.data
        }
        if (this.currentMedia?.id === mediaId) {
          this.currentMedia = response.data
        }
        return response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to update media'
        console.error('Error updating media:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async deleteMedia(mediaId) {
      this.loading = true
      this.error = null
      try {
        await api.delete(`/media/${mediaId}/`)
        this.mediaItems = this.mediaItems.filter(m => m.id !== mediaId)
        if (this.currentMedia?.id === mediaId) {
          this.currentMedia = null
        }
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to delete media'
        console.error('Error deleting media:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    setFilters(filters) {
      this.filters = { ...this.filters, ...filters };
      this.pagination.page = 1; // Reset to first page when filters change
    },

    setPagination(pagination) {
      this.pagination = { ...this.pagination, ...pagination };
    },

    clearUploadProgress() {
      this.uploadProgress = {};
    },
  },
}) 