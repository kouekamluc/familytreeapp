import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/api'
import { personService } from '@/services/api'

export const usePeopleStore = defineStore('people', {
  state: () => ({
    people: [],
    currentPerson: null,
    loading: false,
    error: null,
    filters: {
      search: '',
      gender: '',
      isLiving: null,
    },
    pagination: {
      page: 1,
      pageSize: 10,
      total: 0,
    },
  }),

  getters: {
    filteredPeople: (state) => {
      let filtered = [...state.people]
      
      if (state.filters.search) {
        const search = state.filters.search.toLowerCase()
        filtered = filtered.filter(person => 
          person.first_name.toLowerCase().includes(search) ||
          person.last_name.toLowerCase().includes(search) ||
          person.biography?.toLowerCase().includes(search)
        )
      }
      
      if (state.filters.gender) {
        filtered = filtered.filter(person => person.gender === state.filters.gender)
      }
      
      if (state.filters.isLiving !== null) {
        filtered = filtered.filter(person => person.is_living === state.filters.isLiving)
      }
      
      return filtered
    },
  },

  actions: {
    async fetchPeople(treeId) {
      this.loading = true
      this.error = null
      try {
        const params = treeId ? { tree_id: treeId } : {}
        const response = await api.get('/people/', { params })
        this.people = Array.isArray(response.data) ? response.data : (response.data.results || [])
        return this.people
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch people'
        console.error('Error fetching people:', error)
        return []
      } finally {
        this.loading = false
      }
    },

    async getAvailableParents(treeId) {
      if (!this.people.length) {
        await this.fetchPeople(treeId)
      }
      return this.people.map(p => ({
        id: p.id,
        name: `${p.first_name || p.firstName || ''} ${p.last_name || p.lastName || ''}`.trim(),
        gender: p.gender
      }))
    },

    async getAvailableSpouses(treeId) {
      if (!this.people.length) {
        await this.fetchPeople(treeId)
      }
      return this.people.map(p => ({
        id: p.id,
        name: `${p.first_name || p.firstName || ''} ${p.last_name || p.lastName || ''}`.trim(),
        gender: p.gender
      }))
    },

    async fetchPersonDetails(personId) {
      this.loading = true
      this.error = null
      try {
        const response = await api.get(`/people/${personId}/`)
        this.currentPerson = response.data
        return response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch person details'
        console.error('Error fetching person details:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async createPerson(personData) {
      this.loading = true
      this.error = null
      try {
        const payload = { ...personData }
        const fatherId = payload.fatherId
        const motherId = payload.motherId
        const spouseId = payload.spouseId
        delete payload.fatherId
        delete payload.motherId
        delete payload.spouseId

        const response = await api.post('/people/', payload)
        const createdPerson = response.data
        this.people.push(createdPerson)

        if (fatherId) {
          try {
            await api.post('/relationships/', {
              person1: fatherId,
              person2: createdPerson.id,
              relationship_type: 'PARENT'
            })
          } catch (e) {
            console.warn('Auto-create father relationship failed:', e)
          }
        }
        if (motherId) {
          try {
            await api.post('/relationships/', {
              person1: motherId,
              person2: createdPerson.id,
              relationship_type: 'PARENT'
            })
          } catch (e) {
            console.warn('Auto-create mother relationship failed:', e)
          }
        }
        if (spouseId) {
          try {
            await api.post('/relationships/', {
              person1: spouseId,
              person2: createdPerson.id,
              relationship_type: 'SPOUSE'
            })
          } catch (e) {
            console.warn('Auto-create spouse relationship failed:', e)
          }
        }

        return createdPerson
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to create person'
        console.error('Error creating person:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async updatePerson(personId, personData) {
      this.loading = true
      this.error = null
      try {
        const response = await api.put(`/people/${personId}/`, personData)
        const index = this.people.findIndex(p => p.id === personId)
        if (index !== -1) {
          this.people[index] = response.data
        }
        return response.data
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to update person'
        console.error('Error updating person:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    async deletePerson(personId) {
      this.loading = true
      this.error = null
      try {
        await api.delete(`/people/${personId}/`)
        this.people = this.people.filter(p => p.id !== personId)
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to delete person'
        console.error('Error deleting person:', error)
        throw error
      } finally {
        this.loading = false
      }
    },

    setFilters(filters) {
      this.filters = { ...this.filters, ...filters }
      this.pagination.page = 1 // Reset to first page when filters change
    },

    setPagination(pagination) {
      this.pagination = { ...this.pagination, ...pagination }
    },

    async addRelationship(treeId, personId, relationshipData) {
      try {
        this.loading = true
        this.error = null
        const response = await api.post(`/trees/${treeId}/people/${personId}/relationships/`, relationshipData)
        return response.data
      } catch (err) {
        this.error = err.response?.data?.message || 'Failed to add relationship'
        return null
      } finally {
        this.loading = false
      }
    },

    async updateRelationship(treeId, personId, relationshipId, relationshipData) {
      try {
        this.loading = true
        this.error = null
        const response = await api.put(`/trees/${treeId}/people/${personId}/relationships/${relationshipId}/`, relationshipData)
        return response.data
      } catch (err) {
        this.error = err.response?.data?.message || 'Failed to update relationship'
        return null
      } finally {
        this.loading = false
      }
    },

    async deleteRelationship(treeId, personId, relationshipId) {
      try {
        this.loading = true
        this.error = null
        await api.delete(`/trees/${treeId}/people/${personId}/relationships/${relationshipId}/`)
        return true
      } catch (err) {
        this.error = err.response?.data?.message || 'Failed to delete relationship'
        return false
      } finally {
        this.loading = false
      }
    },

    async getFamilyGroup(treeId, personId) {
      try {
        this.loading = true
        this.error = null
        const response = await api.get(`/trees/${treeId}/people/${personId}/family-group/`)
        return response.data
      } catch (err) {
        this.error = err.response?.data?.message || 'Failed to fetch family group'
        return null
      } finally {
        this.loading = false
      }
    },

    async mergePeople(treeId, sourceId, targetId) {
      try {
        this.loading = true
        this.error = null
        const response = await api.post(`/trees/${treeId}/people/merge/`, {
          source_person_id: sourceId,
          target_person_id: targetId
        })
        return response.data
      } catch (err) {
        this.error = err.response?.data?.message || 'Failed to merge people'
        return null
      } finally {
        this.loading = false
      }
    },
  }
})

export const usePersonStore = usePeopleStore
 