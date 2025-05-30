<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="mb-8">
        <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
          Advanced Search
        </h2>
        <p class="mt-1 text-sm text-gray-500">
          Use advanced filters to search for people, events, and media in your family tree
        </p>
      </div>

      <!-- Search Form -->
      <form @submit.prevent="performSearch" class="bg-white shadow rounded-lg p-6 space-y-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Name -->
          <div>
            <label for="name" class="block text-sm font-medium text-gray-700">Name</label>
            <input
              type="text"
              id="name"
              v-model="filters.name"
              placeholder="Enter name..."
              class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            />
          </div>

          <!-- Event Type -->
          <div>
            <label for="eventType" class="block text-sm font-medium text-gray-700">Event Type</label>
            <select
              id="eventType"
              v-model="filters.eventType"
              class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            >
              <option value="">Any</option>
              <option value="birth">Birth</option>
              <option value="marriage">Marriage</option>
              <option value="death">Death</option>
              <option value="other">Other</option>
            </select>
          </div>

          <!-- Date Range -->
          <div>
            <label class="block text-sm font-medium text-gray-700">Date Range</label>
            <div class="flex space-x-2">
              <input
                type="date"
                v-model="filters.dateFrom"
                class="mt-1 block w-1/2 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                placeholder="From"
              />
              <input
                type="date"
                v-model="filters.dateTo"
                class="mt-1 block w-1/2 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                placeholder="To"
              />
            </div>
          </div>

          <!-- Location -->
          <div>
            <label for="location" class="block text-sm font-medium text-gray-700">Location</label>
            <input
              type="text"
              id="location"
              v-model="filters.location"
              placeholder="Enter location..."
              class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            />
          </div>

          <!-- Media Type -->
          <div>
            <label for="mediaType" class="block text-sm font-medium text-gray-700">Media Type</label>
            <select
              id="mediaType"
              v-model="filters.mediaType"
              class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            >
              <option value="">Any</option>
              <option value="photo">Photo</option>
              <option value="video">Video</option>
              <option value="document">Document</option>
            </select>
          </div>
        </div>

        <!-- Selected Filters Summary -->
        <div v-if="hasActiveFilters" class="bg-gray-50 rounded-md p-4 mt-4">
          <h4 class="text-sm font-medium text-gray-700 mb-2">Selected Filters:</h4>
          <ul class="flex flex-wrap gap-2">
            <li v-if="filters.name" class="bg-indigo-100 text-indigo-700 px-2 py-1 rounded">Name: {{ filters.name }}</li>
            <li v-if="filters.eventType" class="bg-indigo-100 text-indigo-700 px-2 py-1 rounded">Event: {{ filters.eventType }}</li>
            <li v-if="filters.dateFrom" class="bg-indigo-100 text-indigo-700 px-2 py-1 rounded">From: {{ filters.dateFrom }}</li>
            <li v-if="filters.dateTo" class="bg-indigo-100 text-indigo-700 px-2 py-1 rounded">To: {{ filters.dateTo }}</li>
            <li v-if="filters.location" class="bg-indigo-100 text-indigo-700 px-2 py-1 rounded">Location: {{ filters.location }}</li>
            <li v-if="filters.mediaType" class="bg-indigo-100 text-indigo-700 px-2 py-1 rounded">Media: {{ filters.mediaType }}</li>
          </ul>
        </div>

        <!-- Search Button -->
        <div class="flex justify-end">
          <button
            type="submit"
            class="inline-flex items-center px-6 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Search
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'

const router = useRouter()
const toast = useToast()

const filters = ref({
  name: '',
  eventType: '',
  dateFrom: '',
  dateTo: '',
  location: '',
  mediaType: ''
})

const hasActiveFilters = computed(() => {
  return (
    filters.value.name ||
    filters.value.eventType ||
    filters.value.dateFrom ||
    filters.value.dateTo ||
    filters.value.location ||
    filters.value.mediaType
  )
})

const performSearch = () => {
  // TODO: Implement search logic or route to results page with filters
  toast.info('Performing search...')
  router.push({
    name: 'SearchResultsPage',
    query: { ...filters.value }
  })
}
</script> 