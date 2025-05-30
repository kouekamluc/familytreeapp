<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="mb-8">
        <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
          Export Options
        </h2>
        <p class="mt-1 text-sm text-gray-500">
          Choose what data to export and in which format
        </p>
      </div>
      <form @submit.prevent="exportData" class="bg-white shadow rounded-lg p-6 space-y-6">
        <div>
          <label for="format" class="block text-sm font-medium text-gray-700">Export Format</label>
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
            <input id="people" type="checkbox" v-model="options.people" class="h-4 w-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" />
            <label for="people" class="ml-2 block text-sm text-gray-700">People</label>
          </div>
          <div class="flex items-center">
            <input id="events" type="checkbox" v-model="options.events" class="h-4 w-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" />
            <label for="events" class="ml-2 block text-sm text-gray-700">Events</label>
          </div>
          <div class="flex items-center">
            <input id="media" type="checkbox" v-model="options.media" class="h-4 w-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" />
            <label for="media" class="ml-2 block text-sm text-gray-700">Media</label>
          </div>
          <div class="flex items-center">
            <input id="notes" type="checkbox" v-model="options.notes" class="h-4 w-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500" />
            <label for="notes" class="ml-2 block text-sm text-gray-700">Notes</label>
          </div>
        </div>
        <div class="flex justify-end">
          <button type="submit" class="inline-flex items-center px-6 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
            Export
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
const options = ref({
  format: 'gedcom',
  people: true,
  events: true,
  media: true,
  notes: true
})
const exportData = async () => {
  try {
    // TODO: Implement export logic
    await new Promise(resolve => setTimeout(resolve, 1000))
    toast.success('Export started!')
  } catch (error) {
    toast.error('Failed to start export')
  }
}
</script> 