<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="mb-8 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            Relationships
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            Manage connections between family members
          </p>
        </div>
        <div class="flex gap-2">
          <button
            @click="router.push('/relationships/add')"
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <svg class="h-5 w-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Add Relationship
          </button>
        </div>
      </div>

      <!-- Filters -->
      <div class="bg-white rounded-lg shadow mb-6">
        <div class="p-4">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">Search</label>
              <input
                v-model="filters.search"
                type="text"
                placeholder="Search relationships..."
                class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700">Type</label>
              <select
                v-model="filters.type"
                class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              >
                <option value="">All Types</option>
                <option value="parent">Parent</option>
                <option value="child">Child</option>
                <option value="spouse">Spouse</option>
                <option value="sibling">Sibling</option>
                <option value="grandparent">Grandparent</option>
                <option value="grandchild">Grandchild</option>
                <option value="aunt_uncle">Aunt/Uncle</option>
                <option value="niece_nephew">Niece/Nephew</option>
                <option value="cousin">Cousin</option>
                <option value="in_law">In-law</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700">Status</label>
              <select
                v-model="filters.status"
                class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              >
                <option value="">All Status</option>
                <option value="active">Active</option>
                <option value="ended">Ended</option>
                <option value="private">Private</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <!-- Relationships List -->
      <div class="bg-white rounded-lg shadow overflow-hidden">
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Person 1
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Relationship
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Person 2
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date Range
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="relationship in filteredRelationships" :key="relationship.id">
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <img
                      :src="relationship.person1.avatar"
                      :alt="relationship.person1.name"
                      class="h-10 w-10 rounded-full"
                    />
                    <div class="ml-4">
                      <div class="text-sm font-medium text-gray-900">
                        {{ relationship.person1.name }}
                      </div>
                      <div class="text-sm text-gray-500">
                        {{ relationship.person1.birthDate }}
                      </div>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-900 capitalize">{{ relationship.type }}</div>
                  <div class="text-sm text-gray-500">{{ relationship.details }}</div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <img
                      :src="relationship.person2.avatar"
                      :alt="relationship.person2.name"
                      class="h-10 w-10 rounded-full"
                    />
                    <div class="ml-4">
                      <div class="text-sm font-medium text-gray-900">
                        {{ relationship.person2.name }}
                      </div>
                      <div class="text-sm text-gray-500">
                        {{ relationship.person2.birthDate }}
                      </div>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="text-sm text-gray-900">
                    {{ formatDate(relationship.startDate) }}
                  </div>
                  <div class="text-sm text-gray-500">
                    {{ relationship.endDate ? `to ${formatDate(relationship.endDate)}` : 'Present' }}
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span
                    class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                    :class="{
                      'bg-green-100 text-green-800': relationship.status === 'active',
                      'bg-gray-100 text-gray-800': relationship.status === 'ended',
                      'bg-yellow-100 text-yellow-800': relationship.status === 'private'
                    }"
                  >
                    {{ relationship.status }}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <button
                    @click="editRelationship(relationship.id)"
                    class="text-indigo-600 hover:text-indigo-900 mr-4"
                  >
                    Edit
                  </button>
                  <button
                    @click="deleteRelationship(relationship.id)"
                    class="text-red-600 hover:text-red-900"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Empty State -->
        <div
          v-if="!filteredRelationships.length"
          class="text-center py-12"
        >
          <svg
            class="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No relationships found</h3>
          <p class="mt-1 text-sm text-gray-500">
            Get started by adding a new relationship.
          </p>
          <div class="mt-6">
            <button
              @click="router.push('/relationships/add')"
              class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              <svg class="h-5 w-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              Add Relationship
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

const filters = ref({
  search: '',
  type: '',
  status: ''
})

const relationships = ref([
  {
    id: 1,
    person1: {
      id: 1,
      name: 'John Smith',
      birthDate: '1950-01-15',
      avatar: '/avatars/john.jpg'
    },
    person2: {
      id: 2,
      name: 'Mary Smith',
      birthDate: '1952-03-20',
      avatar: '/avatars/mary.jpg'
    },
    type: 'spouse',
    details: 'Married in 1975',
    startDate: '1975-06-10',
    endDate: null,
    status: 'active'
  },
  {
    id: 2,
    person1: {
      id: 1,
      name: 'John Smith',
      birthDate: '1950-01-15',
      avatar: '/avatars/john.jpg'
    },
    person2: {
      id: 3,
      name: 'James Smith',
      birthDate: '1978-05-12',
      avatar: '/avatars/james.jpg'
    },
    type: 'parent',
    details: 'Father and son',
    startDate: '1978-05-12',
    endDate: null,
    status: 'active'
  }
])

const filteredRelationships = computed(() => {
  return relationships.value.filter(relationship => {
    const matchesSearch = !filters.value.search ||
      relationship.person1.name.toLowerCase().includes(filters.value.search.toLowerCase()) ||
      relationship.person2.name.toLowerCase().includes(filters.value.search.toLowerCase()) ||
      relationship.details.toLowerCase().includes(filters.value.search.toLowerCase())

    const matchesType = !filters.value.type || relationship.type === filters.value.type
    const matchesStatus = !filters.value.status || relationship.status === filters.value.status

    return matchesSearch && matchesType && matchesStatus
  })
})

const formatDate = (date) => {
  if (!date) return ''
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const editRelationship = (id) => {
  router.push(`/relationships/${id}/edit`)
}

const deleteRelationship = async (id) => {
  if (confirm('Are you sure you want to delete this relationship?')) {
    try {
      // TODO: Implement relationship deletion logic
      console.log('Deleting relationship:', id)
      relationships.value = relationships.value.filter(r => r.id !== id)
    } catch (error) {
      console.error('Error deleting relationship:', error)
      // TODO: Show error message to user
    }
  }
}
</script> 