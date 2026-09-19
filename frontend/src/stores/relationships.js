import { defineStore } from 'pinia';
import api from '@/api';

export const useRelationshipsStore = defineStore('relationships', {
  state: () => ({
    relationships: [],
    currentRelationship: null,
    loading: false,
    error: null,
    filters: {
      search: '',
      relationshipType: '',
      isCurrent: null,
    },
    pagination: {
      page: 1,
      pageSize: 10,
      total: 0,
    },
  }),

  getters: {
    filteredRelationships: (state) => {
      let filtered = [...state.relationships];
      
      if (state.filters.search) {
        const search = state.filters.search.toLowerCase();
        filtered = filtered.filter(rel => {
          const p1First = (rel.person1_details?.first_name || rel.person1?.first_name || '').toLowerCase();
          const p1Last = (rel.person1_details?.last_name || rel.person1?.last_name || '').toLowerCase();
          const p2First = (rel.person2_details?.first_name || rel.person2?.first_name || '').toLowerCase();
          const p2Last = (rel.person2_details?.last_name || rel.person2?.last_name || '').toLowerCase();
          const notes = (rel.notes || '').toLowerCase();
          return p1First.includes(search) || p1Last.includes(search) || p2First.includes(search) || p2Last.includes(search) || notes.includes(search);
        });
      }
      
      if (state.filters.relationshipType) {
        filtered = filtered.filter(rel => rel.relationship_type === state.filters.relationshipType);
      }
      
      if (state.filters.isCurrent !== null) {
        filtered = filtered.filter(rel => rel.is_current === state.filters.isCurrent);
      }
      
      return filtered;
    },
  },

  actions: {
    async fetchRelationships(treeId) {
      this.loading = true;
      this.error = null;
      try {
        const params = treeId ? { tree_id: treeId } : {};
        const response = await api.get('/relationships/', { params });
        const list = Array.isArray(response.data) ? response.data : (response.data.results || []);
        this.relationships = list.map(r => ({
          ...r,
          source: r.source !== undefined ? r.source : r.person1,
          target: r.target !== undefined ? r.target : r.person2
        }));
        return this.relationships;
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch relationships';
        console.error('Error fetching relationships:', error);
        return [];
      } finally {
        this.loading = false;
      }
    },

    async fetchRelationship(id) {
      this.loading = true;
      this.error = null;
      try {
        const response = await api.get(`/relationships/${id}/`);
        this.currentRelationship = response.data;
        return response.data;
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch relationship';
        throw error;
      } finally {
        this.loading = false;
      }
    },

    async createRelationship(relationshipData) {
      this.loading = true;
      this.error = null;
      try {
        const response = await api.post('/relationships/', relationshipData);
        this.relationships.push(response.data);
        return response.data;
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to create relationship';
        console.error('Error creating relationship:', error);
        throw error;
      } finally {
        this.loading = false;
      }
    },

    async updateRelationship(relationshipId, relationshipData) {
      this.loading = true;
      this.error = null;
      try {
        const response = await api.put(`/relationships/${relationshipId}/`, relationshipData);
        const index = this.relationships.findIndex(r => r.id === relationshipId);
        if (index !== -1) {
          this.relationships[index] = response.data;
        }
        if (this.currentRelationship?.id === relationshipId) {
          this.currentRelationship = response.data;
        }
        return response.data;
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to update relationship';
        console.error('Error updating relationship:', error);
        throw error;
      } finally {
        this.loading = false;
      }
    },

    async deleteRelationship(relationshipId) {
      this.loading = true;
      this.error = null;
      try {
        await api.delete(`/relationships/${relationshipId}/`);
        this.relationships = this.relationships.filter(r => r.id !== relationshipId);
        if (this.currentRelationship?.id === relationshipId) {
          this.currentRelationship = null;
        }
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to delete relationship';
        console.error('Error deleting relationship:', error);
        throw error;
      } finally {
        this.loading = false;
      }
    },

    setFilters(filters) {
      this.filters = { ...this.filters, ...filters };
      this.pagination.page = 1; // Reset to first page when filters change
    },

    setPagination(pagination) {
      this.pagination = { ...this.pagination, ...pagination };
    },
  },
}); 