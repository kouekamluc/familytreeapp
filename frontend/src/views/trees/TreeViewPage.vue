<template>
  <div class="min-h-screen bg-gray-100">
    <!-- Toolbar -->
    <div class="bg-white shadow">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex">
            <div class="flex-shrink-0 flex items-center">
              <h1 class="text-xl font-semibold text-gray-900">
                {{ treeName }}
              </h1>
            </div>
          </div>
          <div class="flex items-center space-x-4">
            <!-- Zoom Controls -->
            <div class="flex items-center space-x-2">
              <button
                @click="zoomOut"
                class="p-2 rounded-md text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4" />
                </svg>
              </button>
              <span class="text-sm text-gray-500">{{ zoomLevel }}%</span>
              <button
                @click="zoomIn"
                class="p-2 rounded-md text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                </svg>
              </button>
            </div>

            <!-- View Controls -->
            <div class="flex items-center space-x-2">
              <button
                @click="toggleView('horizontal')"
                :class="[
                  'p-2 rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500',
                  viewMode === 'horizontal' ? 'bg-indigo-100 text-indigo-600' : 'text-gray-400 hover:text-gray-500'
                ]"
              >
                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                </svg>
              </button>
              <button
                @click="toggleView('vertical')"
                :class="[
                  'p-2 rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500',
                  viewMode === 'vertical' ? 'bg-indigo-100 text-indigo-600' : 'text-gray-400 hover:text-gray-500'
                ]"
              >
                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v14M5 12h14" />
                </svg>
              </button>
            </div>

            <!-- Search -->
            <div class="flex-1 max-w-lg">
              <div class="relative">
                <input
                  type="text"
                  v-model="searchQuery"
                  placeholder="Search family members..."
                  class="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:placeholder-gray-400 focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                />
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                </div>
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="flex items-center space-x-4">
              <button
                @click="showAddPersonModal = true"
                class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <svg class="-ml-1 mr-2 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                </svg>
                Add Person
              </button>
              <button
                @click="showSettingsModal = true"
                class="p-2 rounded-md text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Tree Visualization -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <div
        ref="treeContainer"
        class="bg-white shadow rounded-lg overflow-hidden"
        style="height: calc(100vh - 12rem)"
      >
        <!-- Tree visualization will be rendered here -->
        <div class="p-4 text-center text-gray-500">
          Tree visualization component will be integrated here
        </div>
      </div>
    </div>

    <!-- Add Person Modal -->
    <div
      v-if="showAddPersonModal"
      class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center"
    >
      <div class="bg-white rounded-lg max-w-md w-full mx-4 p-6">
        <h3 class="text-lg font-medium text-gray-900 mb-4">
          Add Family Member
        </h3>
        <div class="space-y-4">
          <div>
            <label for="firstName" class="block text-sm font-medium text-gray-700">
              First Name
            </label>
            <input
              type="text"
              v-model="newPerson.firstName"
              class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            />
          </div>
          <div>
            <label for="lastName" class="block text-sm font-medium text-gray-700">
              Last Name
            </label>
            <input
              type="text"
              v-model="newPerson.lastName"
              class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            />
          </div>
          <div>
            <label for="birthDate" class="block text-sm font-medium text-gray-700">
              Birth Date
            </label>
            <input
              type="date"
              v-model="newPerson.birthDate"
              class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            />
          </div>
          <div class="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense">
            <button
              type="button"
              @click="addPerson"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:col-start-2 sm:text-sm"
            >
              Add
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

    <!-- Settings Modal -->
    <div
      v-if="showSettingsModal"
      class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center"
    >
      <div class="bg-white rounded-lg max-w-md w-full mx-4 p-6">
        <h3 class="text-lg font-medium text-gray-900 mb-4">
          Tree View Settings
        </h3>
        <div class="space-y-4">
          <div>
            <label for="showPhotos" class="flex items-center">
              <input
                type="checkbox"
                v-model="settings.showPhotos"
                class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
              />
              <span class="ml-2 text-sm text-gray-700">Show Photos</span>
            </label>
          </div>
          <div>
            <label for="showDates" class="flex items-center">
              <input
                type="checkbox"
                v-model="settings.showDates"
                class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
              />
              <span class="ml-2 text-sm text-gray-700">Show Dates</span>
            </label>
          </div>
          <div>
            <label for="showRelationships" class="flex items-center">
              <input
                type="checkbox"
                v-model="settings.showRelationships"
                class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
              />
              <span class="ml-2 text-sm text-gray-700">Show Relationships</span>
            </label>
          </div>
          <div class="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense">
            <button
              type="button"
              @click="saveSettings"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:col-start-2 sm:text-sm"
            >
              Save
            </button>
            <button
              type="button"
              @click="showSettingsModal = false"
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
import { ref } from 'vue'
import { useToast } from 'vue-toastification'

const toast = useToast()
const treeContainer = ref(null)
const treeName = ref('Smith Family Tree')
const zoomLevel = ref(100)
const viewMode = ref('horizontal')
const searchQuery = ref('')
const showAddPersonModal = ref(false)
const showSettingsModal = ref(false)

const newPerson = ref({
  firstName: '',
  lastName: '',
  birthDate: ''
})

const settings = ref({
  showPhotos: true,
  showDates: true,
  showRelationships: true
})

const zoomIn = () => {
  if (zoomLevel.value < 200) {
    zoomLevel.value += 10
    // TODO: Implement zoom functionality
  }
}

const zoomOut = () => {
  if (zoomLevel.value > 50) {
    zoomLevel.value -= 10
    // TODO: Implement zoom functionality
  }
}

const toggleView = (mode) => {
  viewMode.value = mode
  // TODO: Implement view mode change
}

const addPerson = () => {
  // TODO: Implement API call to add person
  showAddPersonModal.value = false
  newPerson.value = { firstName: '', lastName: '', birthDate: '' }
  toast.success('Family member added successfully')
}

const saveSettings = () => {
  // TODO: Implement API call to save settings
  showSettingsModal.value = false
  toast.success('Settings saved successfully')
}
</script> 