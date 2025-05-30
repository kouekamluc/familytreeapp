<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="bg-white shadow rounded-lg">
        <!-- Header -->
        <div class="px-4 py-5 border-b border-gray-200 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            Tree Settings
          </h3>
          <p class="mt-1 text-sm text-gray-500">
            Configure your family tree settings and preferences
          </p>
        </div>

        <!-- Settings Form -->
        <form @submit.prevent="handleSave" class="space-y-6 p-6">
          <!-- Basic Information -->
          <div class="space-y-4">
            <h4 class="text-md font-medium text-gray-900">Basic Information</h4>
            
            <div>
              <label for="treeName" class="block text-sm font-medium text-gray-700">
                Tree Name
              </label>
              <input
                type="text"
                id="treeName"
                v-model="settings.name"
                class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              />
            </div>

            <div>
              <label for="description" class="block text-sm font-medium text-gray-700">
                Description
              </label>
              <textarea
                id="description"
                v-model="settings.description"
                rows="3"
                class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              ></textarea>
            </div>
          </div>

          <!-- Privacy Settings -->
          <div class="space-y-4">
            <h4 class="text-md font-medium text-gray-900">Privacy Settings</h4>
            
            <div>
              <label class="block text-sm font-medium text-gray-700">
                Tree Visibility
              </label>
              <div class="mt-2 space-y-4">
                <div class="flex items-center">
                  <input
                    type="radio"
                    id="private"
                    v-model="settings.visibility"
                    value="private"
                    class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300"
                  />
                  <label for="private" class="ml-3 block text-sm font-medium text-gray-700">
                    Private - Only invited members can view
                  </label>
                </div>
                <div class="flex items-center">
                  <input
                    type="radio"
                    id="public"
                    v-model="settings.visibility"
                    value="public"
                    class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300"
                  />
                  <label for="public" class="ml-3 block text-sm font-medium text-gray-700">
                    Public - Anyone can view
                  </label>
                </div>
              </div>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">
                Member Permissions
              </label>
              <div class="mt-2 space-y-4">
                <div class="flex items-center">
                  <input
                    type="checkbox"
                    id="allowMemberEdit"
                    v-model="settings.allowMemberEdit"
                    class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                  />
                  <label for="allowMemberEdit" class="ml-3 block text-sm font-medium text-gray-700">
                    Allow members to edit tree
                  </label>
                </div>
                <div class="flex items-center">
                  <input
                    type="checkbox"
                    id="allowMemberInvite"
                    v-model="settings.allowMemberInvite"
                    class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                  />
                  <label for="allowMemberInvite" class="ml-3 block text-sm font-medium text-gray-700">
                    Allow members to invite others
                  </label>
                </div>
              </div>
            </div>
          </div>

          <!-- Display Settings -->
          <div class="space-y-4">
            <h4 class="text-md font-medium text-gray-900">Display Settings</h4>
            
            <div>
              <label for="defaultLayout" class="block text-sm font-medium text-gray-700">
                Default Tree Layout
              </label>
              <select
                id="defaultLayout"
                v-model="settings.defaultLayout"
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="horizontal">Horizontal</option>
                <option value="vertical">Vertical</option>
                <option value="radial">Radial</option>
              </select>
            </div>

            <div>
              <label for="dateFormat" class="block text-sm font-medium text-gray-700">
                Date Format
              </label>
              <select
                id="dateFormat"
                v-model="settings.dateFormat"
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="MM/DD/YYYY">MM/DD/YYYY</option>
                <option value="DD/MM/YYYY">DD/MM/YYYY</option>
                <option value="YYYY-MM-DD">YYYY-MM-DD</option>
              </select>
            </div>
          </div>

          <!-- Danger Zone -->
          <div class="space-y-4 border-t border-gray-200 pt-6">
            <h4 class="text-md font-medium text-red-600">Danger Zone</h4>
            
            <div class="flex items-center justify-between">
              <div>
                <h5 class="text-sm font-medium text-gray-900">Delete Tree</h5>
                <p class="text-sm text-gray-500">
                  Permanently delete this tree and all its data
                </p>
              </div>
              <button
                type="button"
                @click="showDeleteConfirm = true"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
              >
                Delete Tree
              </button>
            </div>
          </div>

          <!-- Save Button -->
          <div class="flex justify-end">
            <button
              type="submit"
              :disabled="loading"
              class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
            >
              <svg
                v-if="loading"
                class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path
                  class="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                ></path>
              </svg>
              {{ loading ? 'Saving...' : 'Save Changes' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div v-if="showDeleteConfirm" class="fixed z-10 inset-0 overflow-y-auto">
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>

        <div class="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
          <div class="sm:flex sm:items-start">
            <div class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10">
              <svg class="h-6 w-6 text-red-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
              </svg>
            </div>
            <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Delete Tree
              </h3>
              <div class="mt-2">
                <p class="text-sm text-gray-500">
                  Are you sure you want to delete this tree? This action cannot be undone.
                </p>
              </div>
            </div>
          </div>
          <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
            <button
              type="button"
              @click="handleDelete"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm"
            >
              Delete
            </button>
            <button
              type="button"
              @click="showDeleteConfirm = false"
              class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm"
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
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useTreeStore } from '@/stores/tree'

const router = useRouter()
const treeStore = useTreeStore()

const settings = ref({
  name: '',
  description: '',
  visibility: 'private',
  allowMemberEdit: false,
  allowMemberInvite: false,
  defaultLayout: 'horizontal',
  dateFormat: 'MM/DD/YYYY'
})

const loading = ref(false)
const showDeleteConfirm = ref(false)

onMounted(async () => {
  try {
    const treeSettings = await treeStore.getTreeSettings()
    settings.value = { ...settings.value, ...treeSettings }
  } catch (error) {
    console.error('Error fetching tree settings:', error)
    // Handle error (show notification, etc.)
  }
})

const handleSave = async () => {
  try {
    loading.value = true
    await treeStore.updateTreeSettings(settings.value)
    // Show success notification
  } catch (error) {
    console.error('Error saving tree settings:', error)
    // Handle error (show notification, etc.)
  } finally {
    loading.value = false
  }
}

const handleDelete = async () => {
  try {
    loading.value = true
    await treeStore.deleteTree()
    router.push('/dashboard')
  } catch (error) {
    console.error('Error deleting tree:', error)
    // Handle error (show notification, etc.)
  } finally {
    loading.value = false
    showDeleteConfirm.value = false
  }
}
</script> 