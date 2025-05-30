<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="md:flex md:items-center md:justify-between">
        <div class="flex-1 min-w-0">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            Application Settings
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            Customize your application preferences
          </p>
        </div>
        <div class="mt-4 flex md:mt-0 md:ml-4">
          <button
            type="button"
            @click="saveChanges"
            class="ml-3 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Save Changes
          </button>
        </div>
      </div>

      <div class="mt-8 space-y-6">
        <!-- Display Settings -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              Display Settings
            </h3>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <div class="space-y-6">
              <!-- Theme -->
              <div>
                <label class="block text-sm font-medium text-gray-700">
                  Theme
                </label>
                <div class="mt-2 space-y-4">
                  <div class="flex items-center">
                    <input
                      id="theme-light"
                      v-model="settings.theme"
                      value="light"
                      type="radio"
                      class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300"
                    />
                    <label for="theme-light" class="ml-3 block text-sm font-medium text-gray-700">
                      Light
                    </label>
                  </div>
                  <div class="flex items-center">
                    <input
                      id="theme-dark"
                      v-model="settings.theme"
                      value="dark"
                      type="radio"
                      class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300"
                    />
                    <label for="theme-dark" class="ml-3 block text-sm font-medium text-gray-700">
                      Dark
                    </label>
                  </div>
                  <div class="flex items-center">
                    <input
                      id="theme-system"
                      v-model="settings.theme"
                      value="system"
                      type="radio"
                      class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300"
                    />
                    <label for="theme-system" class="ml-3 block text-sm font-medium text-gray-700">
                      System
                    </label>
                  </div>
                </div>
              </div>

              <!-- Date Format -->
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

              <!-- Time Format -->
              <div>
                <label for="timeFormat" class="block text-sm font-medium text-gray-700">
                  Time Format
                </label>
                <select
                  id="timeFormat"
                  v-model="settings.timeFormat"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                >
                  <option value="12h">12-hour</option>
                  <option value="24h">24-hour</option>
                </select>
              </div>
            </div>
          </div>
        </div>

        <!-- Tree Settings -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              Tree Settings
            </h3>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <div class="space-y-6">
              <!-- Default Tree View -->
              <div>
                <label for="defaultTreeView" class="block text-sm font-medium text-gray-700">
                  Default Tree View
                </label>
                <select
                  id="defaultTreeView"
                  v-model="settings.defaultTreeView"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                >
                  <option value="horizontal">Horizontal</option>
                  <option value="vertical">Vertical</option>
                </select>
              </div>

              <!-- Show Photos -->
              <div class="flex items-start">
                <div class="flex items-center h-5">
                  <input
                    id="showPhotos"
                    v-model="settings.showPhotos"
                    type="checkbox"
                    class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                  />
                </div>
                <div class="ml-3 text-sm">
                  <label for="showPhotos" class="font-medium text-gray-700">
                    Show Photos
                  </label>
                  <p class="text-gray-500">
                    Display profile photos in the family tree
                  </p>
                </div>
              </div>

              <!-- Show Dates -->
              <div class="flex items-start">
                <div class="flex items-center h-5">
                  <input
                    id="showDates"
                    v-model="settings.showDates"
                    type="checkbox"
                    class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                  />
                </div>
                <div class="ml-3 text-sm">
                  <label for="showDates" class="font-medium text-gray-700">
                    Show Dates
                  </label>
                  <p class="text-gray-500">
                    Display birth and death dates in the family tree
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Privacy Settings -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              Privacy Settings
            </h3>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <div class="space-y-6">
              <!-- Hide Living People -->
              <div class="flex items-start">
                <div class="flex items-center h-5">
                  <input
                    id="hideLivingPeople"
                    v-model="settings.hideLivingPeople"
                    type="checkbox"
                    class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                  />
                </div>
                <div class="ml-3 text-sm">
                  <label for="hideLivingPeople" class="font-medium text-gray-700">
                    Hide Living People
                  </label>
                  <p class="text-gray-500">
                    Hide information about living people from other users
                  </p>
                </div>
              </div>

              <!-- Private Notes -->
              <div class="flex items-start">
                <div class="flex items-center h-5">
                  <input
                    id="privateNotes"
                    v-model="settings.privateNotes"
                    type="checkbox"
                    class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                  />
                </div>
                <div class="ml-3 text-sm">
                  <label for="privateNotes" class="font-medium text-gray-700">
                    Private Notes
                  </label>
                  <p class="text-gray-500">
                    Keep notes private and only visible to you
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Language Settings -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              Language Settings
            </h3>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <div class="space-y-6">
              <!-- Interface Language -->
              <div>
                <label for="language" class="block text-sm font-medium text-gray-700">
                  Interface Language
                </label>
                <select
                  id="language"
                  v-model="settings.language"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                >
                  <option value="en">English</option>
                  <option value="es">Español</option>
                  <option value="fr">Français</option>
                  <option value="de">Deutsch</option>
                  <option value="it">Italiano</option>
                  <option value="pt">Português</option>
                  <option value="ru">Русский</option>
                  <option value="zh">中文</option>
                  <option value="ja">日本語</option>
                </select>
              </div>
            </div>
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

const settings = ref({
  theme: 'system',
  dateFormat: 'MM/DD/YYYY',
  timeFormat: '12h',
  defaultTreeView: 'horizontal',
  showPhotos: true,
  showDates: true,
  hideLivingPeople: true,
  privateNotes: true,
  language: 'en'
})

const saveChanges = async () => {
  try {
    // TODO: Implement API call to save settings
    await new Promise(resolve => setTimeout(resolve, 1000))
    toast.success('Settings saved successfully')
  } catch (error) {
    toast.error('Failed to save settings')
    console.error('Error saving settings:', error)
  }
}
</script> 