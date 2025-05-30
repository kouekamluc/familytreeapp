<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="mb-8">
        <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
          Import Wizard
        </h2>
        <p class="mt-1 text-sm text-gray-500">
          Import your family tree data from a file
        </p>
      </div>
      <form @submit.prevent="importData" class="bg-white shadow rounded-lg p-6 space-y-6">
        <div>
          <label for="file-upload" class="block text-sm font-medium text-gray-700">File</label>
          <input id="file-upload" type="file" @change="handleFileUpload" class="mt-1 block w-full text-sm text-gray-700" />
          <span v-if="file" class="text-xs text-gray-500 mt-1 block">{{ file.name }}</span>
        </div>
        <div>
          <label for="format" class="block text-sm font-medium text-gray-700">Import Format</label>
          <select
            id="format"
            v-model="options.format"
            class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
          >
            <option value="gedcom">GEDCOM</option>
            <option value="json">JSON</option>
            <option value="csv">CSV</option>
          </select>
        </div>
        <div class="space-y-4">
          <div class="flex items-center">
            <input id="mergeDuplicates" type="checkbox" v-model="options.mergeDuplicates" class="h-4 w-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" />
            <label for="mergeDuplicates" class="ml-2 block text-sm text-gray-700">Merge Duplicates</label>
          </div>
          <div class="flex items-center">
            <input id="includeMedia" type="checkbox" v-model="options.includeMedia" class="h-4 w-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" />
            <label for="includeMedia" class="ml-2 block text-sm text-gray-700">Include Media</label>
          </div>
          <div class="flex items-center">
            <input id="includeNotes" type="checkbox" v-model="options.includeNotes" class="h-4 w-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" />
            <label for="includeNotes" class="ml-2 block text-sm text-gray-700">Include Notes</label>
          </div>
        </div>
        <div class="flex justify-end">
          <button type="submit" class="inline-flex items-center px-6 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
            Import
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
<script setup>
import { ref } from 'vue'
import { useToast } from 'vue-toastification'

const toast = useToast()
const file = ref(null)
const options = ref({
  format: 'gedcom',
  mergeDuplicates: true,
  includeMedia: true,
  includeNotes: true
})
const handleFileUpload = (event) => {
  file.value = event.target.files[0]
}
const importData = async () => {
  try {
    // TODO: Implement import logic
    await new Promise(resolve => setTimeout(resolve, 1000))
    toast.success('Import started!')
  } catch (error) {
    toast.error('Failed to start import')
  }
}
</script> 