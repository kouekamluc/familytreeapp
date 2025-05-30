<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="mb-8">
        <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
          Search Results
        </h2>
        <p class="mt-1 text-sm text-gray-500">
          Results matching your search filters
        </p>
      </div>

      <!-- Filter Summary -->
      <div v-if="hasActiveFilters" class="bg-gray-50 rounded-md p-4 mb-6">
        <h4 class="text-sm font-medium text-gray-700 mb-2">Active Filters:</h4>
        <ul class="flex flex-wrap gap-2">
          <li v-if="filters.name" class="bg-indigo-100 text-indigo-700 px-2 py-1 rounded">Name: {{ filters.name }}</li>
          <li v-if="filters.eventType" class="bg-indigo-100 text-indigo-700 px-2 py-1 rounded">Event: {{ filters.eventType }}</li>
          <li v-if="filters.dateFrom" class="bg-indigo-100 text-indigo-700 px-2 py-1 rounded">From: {{ filters.dateFrom }}</li>
          <li v-if="filters.dateTo" class="bg-indigo-100 text-indigo-700 px-2 py-1 rounded">To: {{ filters.dateTo }}</li>
          <li v-if="filters.location" class="bg-indigo-100 text-indigo-700 px-2 py-1 rounded">Location: {{ filters.location }}</li>
          <li v-if="filters.mediaType" class="bg-indigo-100 text-indigo-700 px-2 py-1 rounded">Media: {{ filters.mediaType }}</li>
        </ul>
      </div>

      <!-- Results -->
      <div class="space-y-10">
        <!-- People Results -->
        <div v-if="results.people.length">
          <h3 class="text-lg font-semibold text-gray-800 mb-4">People</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div v-for="person in results.people" :key="person.id" class="bg-white rounded-lg shadow p-4 flex items-center space-x-4">
              <img :src="person.photo || '/placeholder-user.png'" alt="Photo" class="h-16 w-16 rounded-full object-cover" />
              <div>
                <h4 class="text-md font-bold text-gray-900">{{ person.name }}</h4>
                <p class="text-sm text-gray-500">{{ person.birthDate }} - {{ person.deathDate || 'Present' }}</p>
                <p class="text-sm text-gray-500">{{ person.location }}</p>
                <router-link :to="`/people/${person.id}`" class="text-indigo-600 hover:underline text-sm">View Profile</router-link>
              </div>
            </div>
          </div>
        </div>

        <!-- Event Results -->
        <div v-if="results.events.length">
          <h3 class="text-lg font-semibold text-gray-800 mb-4">Events</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div v-for="event in results.events" :key="event.id" class="bg-white rounded-lg shadow p-4">
              <h4 class="text-md font-bold text-gray-900">{{ event.title }}</h4>
              <p class="text-sm text-gray-500">{{ event.date }} &mdash; {{ event.type }}</p>
              <p class="text-sm text-gray-500">{{ event.location }}</p>
              <p class="text-sm text-gray-700 mt-2">{{ event.description }}</p>
            </div>
          </div>
        </div>

        <!-- Media Results -->
        <div v-if="results.media.length">
          <h3 class="text-lg font-semibold text-gray-800 mb-4">Media</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div v-for="media in results.media" :key="media.id" class="bg-white rounded-lg shadow p-4">
              <img :src="media.thumbnail || '/placeholder-media.png'" alt="Media" class="h-32 w-full object-cover rounded mb-2" />
              <h4 class="text-md font-bold text-gray-900">{{ media.title }}</h4>
              <p class="text-sm text-gray-500">Type: {{ media.type }}</p>
              <p class="text-sm text-gray-500">Date: {{ media.date }}</p>
              <router-link :to="`/media/${media.id}`" class="text-indigo-600 hover:underline text-sm">View Media</router-link>
            </div>
          </div>
        </div>

        <!-- No Results -->
        <div v-if="!results.people.length && !results.events.length && !results.media.length">
          <div class="text-center py-16">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2a4 4 0 014-4h3m4 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V6a3 3 0 013-3h7a3 3 0 013 3v1" />
            </svg>
            <h4 class="mt-2 text-lg font-medium text-gray-700">No results found</h4>
            <p class="mt-1 text-sm text-gray-500">Try adjusting your search filters.</p>
          </div>
        </div>
      </div>

      <!-- Pagination -->
      <div v-if="totalPages > 1" class="mt-10 flex justify-center">
        <nav class="inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
          <button
            @click="prevPage"
            :disabled="page === 1"
            class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
          >
            Prev
          </button>
          <span class="px-4 py-2 border-t border-b border-gray-300 bg-white text-sm font-medium text-gray-700">
            Page {{ page }} of {{ totalPages }}
          </span>
          <button
            @click="nextPage"
            :disabled="page === totalPages"
            class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50 disabled:opacity-50"
          >
            Next
          </button>
        </nav>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

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

const results = ref({
  people: [],
  events: [],
  media: []
})

const page = ref(1)
const totalPages = ref(1)

const fetchResults = () => {
  // TODO: Replace with actual API call using filters and page
  // Simulate results for demonstration
  results.value = {
    people: page.value === 1 ? [
      { id: 1, name: 'John Smith', birthDate: '1950-01-15', deathDate: '', location: 'New York', photo: '/photos/john.jpg' },
      { id: 2, name: 'Sarah Johnson', birthDate: '1952-03-20', deathDate: '', location: 'Boston', photo: '/photos/sarah.jpg' }
    ] : [],
    events: page.value === 1 ? [
      { id: 1, title: 'John & Sarah Married', date: '1975-06-10', type: 'marriage', location: 'New York', description: 'Wedding event' }
    ] : [],
    media: page.value === 1 ? [
      { id: 1, title: 'Wedding Photo', type: 'photo', date: '1975-06-10', thumbnail: '/media/wedding.jpg' }
    ] : []
  }
  totalPages.value = 1
}

onMounted(() => {
  Object.assign(filters.value, route.query)
  fetchResults()
})

const prevPage = () => {
  if (page.value > 1) {
    page.value--
    fetchResults()
  }
}

const nextPage = () => {
  if (page.value < totalPages.value) {
    page.value++
    fetchResults()
  }
}
</script> 