<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="md:flex md:items-center md:justify-between">
        <div class="flex-1 min-w-0">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            Data Management
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            Manage your family tree data, including import/export and backup options
          </p>
        </div>
      </div>

      <div class="mt-8 space-y-6">
        <!-- Export Data -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              Export Data
            </h3>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <div class="space-y-6">
              <div>
                <label for="exportFormat" class="block text-sm font-medium text-gray-700">
                  Export Format
                </label>
                <select
                  id="exportFormat"
                  v-model="exportSettings.format"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                >
                  <option value="gedcom">GEDCOM</option>
                  <option value="json">JSON</option>
                  <option value="csv">CSV</option>
                </select>
              </div>

              <div class="space-y-4">
                <div class="flex items-start">
                  <div class="flex items-center h-5">
                    <input
                      id="exportPhotos"
                      v-model="exportSettings.includePhotos"
                      type="checkbox"
                      class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                    />
                  </div>
                  <div class="ml-3 text-sm">
                    <label for="exportPhotos" class="font-medium text-gray-700">
                      Include Photos
                    </label>
                    <p class="text-gray-500">
                      Export all photos associated with family members
                    </p>
                  </div>
                </div>

                <div class="flex items-start">
                  <div class="flex items-center h-5">
                    <input
                      id="exportNotes"
                      v-model="exportSettings.includeNotes"
                      type="checkbox"
                      class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                    />
                  </div>
                  <div class="ml-3 text-sm">
                    <label for="exportNotes" class="font-medium text-gray-700">
                      Include Notes
                    </label>
                    <p class="text-gray-500">
                      Export all notes and comments
                    </p>
                  </div>
                </div>
              </div>

              <div>
                <button
                  type="button"
                  @click="exportData"
                  class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Export Data
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Import Data -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              Import Data
            </h3>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <div class="space-y-6">
              <div>
                <label for="importFormat" class="block text-sm font-medium text-gray-700">
                  Import Format
                </label>
                <select
                  id="importFormat"
                  v-model="importSettings.format"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                >
                  <option value="gedcom">GEDCOM</option>
                  <option value="json">JSON</option>
                  <option value="csv">CSV</option>
                </select>
              </div>

              <div class="space-y-4">
                <div class="flex items-start">
                  <div class="flex items-center h-5">
                    <input
                      id="importPhotos"
                      v-model="importSettings.includePhotos"
                      type="checkbox"
                      class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                    />
                  </div>
                  <div class="ml-3 text-sm">
                    <label for="importPhotos" class="font-medium text-gray-700">
                      Import Photos
                    </label>
                    <p class="text-gray-500">
                      Import photos associated with family members
                    </p>
                  </div>
                </div>

                <div class="flex items-start">
                  <div class="flex items-center h-5">
                    <input
                      id="importNotes"
                      v-model="importSettings.includeNotes"
                      type="checkbox"
                      class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                    />
                  </div>
                  <div class="ml-3 text-sm">
                    <label for="importNotes" class="font-medium text-gray-700">
                      Import Notes
                    </label>
                    <p class="text-gray-500">
                      Import notes and comments
                    </p>
                  </div>
                </div>

                <div class="flex items-start">
                  <div class="flex items-center h-5">
                    <input
                      id="mergeDuplicates"
                      v-model="importSettings.mergeDuplicates"
                      type="checkbox"
                      class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                    />
                  </div>
                  <div class="ml-3 text-sm">
                    <label for="mergeDuplicates" class="font-medium text-gray-700">
                      Merge Duplicates
                    </label>
                    <p class="text-gray-500">
                      Automatically merge duplicate family members
                    </p>
                  </div>
                </div>
              </div>

              <div>
                <label
                  for="file-upload"
                  class="cursor-pointer inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Choose File
                  <input
                    id="file-upload"
                    type="file"
                    class="hidden"
                    @change="handleFileUpload"
                  />
                </label>
                <span v-if="importSettings.file" class="ml-3 text-sm text-gray-500">
                  {{ importSettings.file.name }}
                </span>
              </div>

              <div>
                <button
                  type="button"
                  @click="importData"
                  :disabled="!importSettings.file"
                  class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Import Data
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Backup Settings -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              Backup Settings
            </h3>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
            <div class="space-y-6">
              <div class="flex items-start">
                <div class="flex items-center h-5">
                  <input
                    id="autoBackup"
                    v-model="backupSettings.autoBackup"
                    type="checkbox"
                    class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                  />
                </div>
                <div class="ml-3 text-sm">
                  <label for="autoBackup" class="font-medium text-gray-700">
                    Automatic Backup
                  </label>
                  <p class="text-gray-500">
                    Automatically backup your data
                  </p>
                </div>
              </div>

              <div v-if="backupSettings.autoBackup">
                <label for="backupFrequency" class="block text-sm font-medium text-gray-700">
                  Backup Frequency
                </label>
                <select
                  id="backupFrequency"
                  v-model="backupSettings.frequency"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                >
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                  <option value="monthly">Monthly</option>
                </select>
              </div>

              <div>
                <button
                  type="button"
                  @click="createBackup"
                  class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Create Backup Now
                </button>
              </div>

              <!-- Backup History -->
              <div v-if="backups.length > 0">
                <h4 class="text-sm font-medium text-gray-900">Backup History</h4>
                <div class="mt-4 flow-root">
                  <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
                    <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                      <table class="min-w-full divide-y divide-gray-300">
                        <thead>
                          <tr>
                            <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">
                              Date
                            </th>
                            <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                              Size
                            </th>
                            <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                              Status
                            </th>
                            <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                              <span class="sr-only">Actions</span>
                            </th>
                          </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-200">
                          <tr v-for="backup in backups" :key="backup.id">
                            <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                              {{ backup.date }}
                            </td>
                            <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                              {{ backup.size }}
                            </td>
                            <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                              <span
                                :class="{
                                  'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium': true,
                                  'bg-green-100 text-green-800': backup.status === 'completed',
                                  'bg-yellow-100 text-yellow-800': backup.status === 'in_progress',
                                  'bg-red-100 text-red-800': backup.status === 'failed'
                                }"
                              >
                                {{ backup.status }}
                              </span>
                            </td>
                            <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                              <button
                                @click="restoreBackup(backup)"
                                class="text-indigo-600 hover:text-indigo-900"
                              >
                                Restore
                              </button>
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
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

const exportSettings = ref({
  format: 'gedcom',
  includePhotos: true,
  includeNotes: true
})

const importSettings = ref({
  format: 'gedcom',
  includePhotos: true,
  includeNotes: true,
  mergeDuplicates: true,
  file: null
})

const backupSettings = ref({
  autoBackup: true,
  frequency: 'weekly'
})

const backups = ref([
  {
    id: 1,
    date: '2024-03-15 14:30',
    size: '2.5 MB',
    status: 'completed'
  },
  {
    id: 2,
    date: '2024-03-08 14:30',
    size: '2.4 MB',
    status: 'completed'
  },
  {
    id: 3,
    date: '2024-03-01 14:30',
    size: '2.3 MB',
    status: 'completed'
  }
])

const handleFileUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    importSettings.value.file = file
  }
}

const exportData = async () => {
  try {
    // TODO: Implement API call to export data
    await new Promise(resolve => setTimeout(resolve, 1000))
    toast.success('Data exported successfully')
  } catch (error) {
    toast.error('Failed to export data')
    console.error('Error exporting data:', error)
  }
}

const importData = async () => {
  try {
    // TODO: Implement API call to import data
    await new Promise(resolve => setTimeout(resolve, 1000))
    toast.success('Data imported successfully')
    importSettings.value.file = null
  } catch (error) {
    toast.error('Failed to import data')
    console.error('Error importing data:', error)
  }
}

const createBackup = async () => {
  try {
    // TODO: Implement API call to create backup
    await new Promise(resolve => setTimeout(resolve, 1000))
    toast.success('Backup created successfully')
  } catch (error) {
    toast.error('Failed to create backup')
    console.error('Error creating backup:', error)
  }
}

const restoreBackup = async (backup) => {
  try {
    // TODO: Implement API call to restore backup
    await new Promise(resolve => setTimeout(resolve, 1000))
    toast.success('Backup restored successfully')
  } catch (error) {
    toast.error('Failed to restore backup')
    console.error('Error restoring backup:', error)
  }
}
</script> 