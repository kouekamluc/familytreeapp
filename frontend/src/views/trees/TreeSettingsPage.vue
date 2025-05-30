<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="md:flex md:items-center md:justify-between">
        <div class="flex-1 min-w-0">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            Tree Settings
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            Configure your family tree preferences and settings
          </p>
        </div>
        <div class="mt-4 flex md:mt-0 md:ml-4">
          <button
            type="button"
            @click="saveSettings"
            class="ml-3 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Save Changes
          </button>
        </div>
      </div>

      <!-- General Settings -->
      <div class="mt-8 bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            General Settings
          </h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            Basic information about your family tree
          </p>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
            <div class="sm:col-span-3">
              <label for="treeName" class="block text-sm font-medium text-gray-700">
                Tree Name
              </label>
              <input
                type="text"
                v-model="settings.treeName"
                class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              />
            </div>
            <div class="sm:col-span-3">
              <label for="language" class="block text-sm font-medium text-gray-700">
                Language
              </label>
              <select
                v-model="settings.language"
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="en">English</option>
                <option value="es">Spanish</option>
                <option value="fr">French</option>
                <option value="de">German</option>
                <option value="zh">Chinese</option>
              </select>
            </div>
            <div class="sm:col-span-6">
              <label for="description" class="block text-sm font-medium text-gray-700">
                Description
              </label>
              <textarea
                v-model="settings.description"
                rows="3"
                class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Privacy Settings -->
      <div class="mt-8 bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            Privacy Settings
          </h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            Control who can see your family tree information
          </p>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <div class="space-y-6">
            <div class="flex items-start">
              <div class="flex items-center h-5">
                <input
                  type="checkbox"
                  v-model="settings.privacy.livingPeople"
                  class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                />
              </div>
              <div class="ml-3 text-sm">
                <label for="livingPeople" class="font-medium text-gray-700">
                  Hide information about living people
                </label>
                <p class="text-gray-500">
                  Only show basic information for living family members
                </p>
              </div>
            </div>
            <div class="flex items-start">
              <div class="flex items-center h-5">
                <input
                  type="checkbox"
                  v-model="settings.privacy.privateNotes"
                  class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                />
              </div>
              <div class="ml-3 text-sm">
                <label for="privateNotes" class="font-medium text-gray-700">
                  Keep notes private
                </label>
                <p class="text-gray-500">
                  Only show notes to administrators
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Display Settings -->
      <div class="mt-8 bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            Display Settings
          </h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            Customize how your family tree is displayed
          </p>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
            <div class="sm:col-span-3">
              <label for="dateFormat" class="block text-sm font-medium text-gray-700">
                Date Format
              </label>
              <select
                v-model="settings.display.dateFormat"
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="MM/DD/YYYY">MM/DD/YYYY</option>
                <option value="DD/MM/YYYY">DD/MM/YYYY</option>
                <option value="YYYY-MM-DD">YYYY-MM-DD</option>
              </select>
            </div>
            <div class="sm:col-span-3">
              <label for="nameFormat" class="block text-sm font-medium text-gray-700">
                Name Format
              </label>
              <select
                v-model="settings.display.nameFormat"
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="firstName">First Name First</option>
                <option value="lastName">Last Name First</option>
              </select>
            </div>
          </div>
        </div>
      </div>

      <!-- Danger Zone -->
      <div class="mt-8 bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-red-600">
            Danger Zone
          </h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            Irreversible and destructive actions
          </p>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <div class="space-y-4">
            <div>
              <button
                type="button"
                @click="showDeleteModal = true"
                class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
              >
                Delete Tree
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Delete Confirmation Modal -->
      <div
        v-if="showDeleteModal"
        class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center"
      >
        <div class="bg-white rounded-lg max-w-md w-full mx-4 p-6">
          <h3 class="text-lg font-medium text-red-600 mb-4">
            Delete Family Tree
          </h3>
          <p class="text-sm text-gray-500 mb-4">
            Are you sure you want to delete this family tree? This action cannot be undone.
          </p>
          <div class="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense">
            <button
              type="button"
              @click="deleteTree"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:col-start-2 sm:text-sm"
            >
              Delete
            </button>
            <button
              type="button"
              @click="showDeleteModal = false"
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
const showDeleteModal = ref(false)

const settings = ref({
  treeName: 'Smith Family Tree',
  language: 'en',
  description: 'Our family history and genealogy',
  privacy: {
    livingPeople: true,
    privateNotes: true
  },
  display: {
    dateFormat: 'MM/DD/YYYY',
    nameFormat: 'firstName'
  }
})

const saveSettings = () => {
  // TODO: Implement API call to save settings
  toast.success('Settings saved successfully')
}

const deleteTree = () => {
  // TODO: Implement API call to delete tree
  showDeleteModal.value = false
  toast.success('Family tree deleted successfully')
  // Redirect to dashboard or tree list
}
</script> 