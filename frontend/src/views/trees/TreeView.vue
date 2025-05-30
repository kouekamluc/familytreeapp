<template>
  <div class="min-h-screen bg-gray-100">
    <div class="py-10">
      <header>
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between">
            <h1 class="text-3xl font-bold leading-tight tracking-tight text-gray-900">
              {{ treeStore.currentTree?.name || 'Family Tree' }}
            </h1>
            <div class="flex space-x-4">
              <button
                @click="toggleViewMode"
                class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                </svg>
                {{ viewMode === 'tree' ? 'Timeline View' : 'Tree View' }}
              </button>
              <button
                @click="showAddPersonModal = true"
                class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                </svg>
                Add Person
              </button>
            </div>
          </div>
        </div>
      </header>
      <main>
        <div class="mx-auto max-w-7xl sm:px-6 lg:px-8">
          <!-- Tree Controls -->
          <div class="bg-white shadow rounded-lg mb-6">
            <div class="px-4 py-5 sm:p-6">
              <div class="flex items-center justify-between">
                <div class="flex space-x-4">
                  <button
                    @click="zoomIn"
                    class="inline-flex items-center p-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                    </svg>
                  </button>
                  <button
                    @click="zoomOut"
                    class="inline-flex items-center p-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4" />
                    </svg>
                  </button>
                  <button
                    @click="resetView"
                    class="inline-flex items-center p-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                    </svg>
                  </button>
                </div>
                <div class="flex items-center space-x-4">
                  <span class="text-sm text-gray-500">Zoom: {{ zoomLevel }}%</span>
                  <div class="relative">
                    <select
                      v-model="selectedLayout"
                      class="block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                    >
                      <option value="horizontal">Horizontal Layout</option>
                      <option value="vertical">Vertical Layout</option>
                      <option value="radial">Radial Layout</option>
                    </select>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Tree Visualization -->
          <div class="bg-white shadow rounded-lg">
            <div class="p-4">
              <div
                ref="treeContainer"
                class="w-full h-[calc(100vh-300px)] border border-gray-200 rounded-lg"
              >
                <!-- Tree visualization will be rendered here -->
                <div v-if="viewMode === 'tree'" class="w-full h-full">
                  <!-- Tree visualization component will be mounted here -->
                </div>
                <div v-else class="w-full h-full">
                  <!-- Timeline visualization component will be mounted here -->
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>

    <!-- Add Person Modal -->
    <div v-if="showAddPersonModal" class="fixed z-10 inset-0 overflow-y-auto">
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
        <div class="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
          <div>
            <div class="mt-3 text-center sm:mt-5">
              <h3 class="text-lg leading-6 font-medium text-gray-900">Add New Person</h3>
              <div class="mt-2">
                <form @submit.prevent="addPerson" class="space-y-4">
                  <div>
                    <label for="firstName" class="block text-sm font-medium text-gray-700">First Name</label>
                    <input
                      type="text"
                      id="firstName"
                      v-model="newPerson.firstName"
                      class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      required
                    />
                  </div>
                  <div>
                    <label for="lastName" class="block text-sm font-medium text-gray-700">Last Name</label>
                    <input
                      type="text"
                      id="lastName"
                      v-model="newPerson.lastName"
                      class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      required
                    />
                  </div>
                  <div>
                    <label for="birthDate" class="block text-sm font-medium text-gray-700">Birth Date</label>
                    <input
                      type="date"
                      id="birthDate"
                      v-model="newPerson.birthDate"
                      class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    />
                  </div>
                  <div>
                    <label for="gender" class="block text-sm font-medium text-gray-700">Gender</label>
                    <select
                      id="gender"
                      v-model="newPerson.gender"
                      class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    >
                      <option value="male">Male</option>
                      <option value="female">Female</option>
                      <option value="other">Other</option>
                    </select>
                  </div>
                </form>
              </div>
            </div>
          </div>
          <div class="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense">
            <button
              type="button"
              @click="addPerson"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:col-start-2 sm:text-sm"
            >
              Add Person
            </button>
            <button
              type="button"
              @click="showAddPersonModal = false"
              class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:col-start-1 sm:text-sm"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { useTreeStore } from '@/stores/trees'
import { usePeopleStore } from '@/stores/people'

const route = useRoute()
const treeStore = useTreeStore()
const peopleStore = usePeopleStore()

const viewMode = ref('tree')
const zoomLevel = ref(100)
const selectedLayout = ref('horizontal')
const showAddPersonModal = ref(false)
const treeContainer = ref(null)

const newPerson = ref({
  firstName: '',
  lastName: '',
  birthDate: '',
  gender: 'male'
})

const toggleViewMode = () => {
  viewMode.value = viewMode.value === 'tree' ? 'timeline' : 'tree'
}

const zoomIn = () => {
  if (zoomLevel.value < 200) {
    zoomLevel.value += 10
    // Implement zoom logic
  }
}

const zoomOut = () => {
  if (zoomLevel.value > 50) {
    zoomLevel.value -= 10
    // Implement zoom logic
  }
}

const resetView = () => {
  zoomLevel.value = 100
  // Implement reset view logic
}

const addPerson = async () => {
  try {
    await peopleStore.addPerson({
      ...newPerson.value,
      treeId: route.params.id
    })
    showAddPersonModal.value = false
    newPerson.value = {
      firstName: '',
      lastName: '',
      birthDate: '',
      gender: 'male'
    }
  } catch (error) {
    console.error('Error adding person:', error)
  }
}

onMounted(async () => {
  try {
    await treeStore.fetchTree(route.params.id)
    // Initialize tree visualization
  } catch (error) {
    console.error('Error fetching tree:', error)
  }
})

onUnmounted(() => {
  // Clean up tree visualization
})
</script> 