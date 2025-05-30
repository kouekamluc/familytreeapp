<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="mb-8 flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            Media Gallery
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            Browse all your family photos, videos, and documents
          </p>
        </div>
        <div class="flex gap-2 items-center">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search media..."
            class="block w-48 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
          />
          <select
            v-model="filterType"
            class="block w-32 border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
          >
            <option value="">All Types</option>
            <option value="photo">Photo</option>
            <option value="video">Video</option>
            <option value="document">Document</option>
          </select>
        </div>
      </div>
      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
        <div
          v-for="media in filteredMedia"
          :key="media.id"
          class="bg-white rounded-lg shadow hover:shadow-lg transition p-4 cursor-pointer flex flex-col"
          @click="goToDetail(media.id)"
        >
          <img
            :src="media.thumbnail || '/placeholder-media.png'"
            :alt="media.title"
            class="h-40 w-full object-cover rounded mb-2"
          />
          <h4 class="text-md font-bold text-gray-900 truncate">{{ media.title }}</h4>
          <p class="text-xs text-gray-500">Type: {{ media.type }}</p>
          <p class="text-xs text-gray-500">Date: {{ media.date }}</p>
        </div>
      </div>
      <div v-if="!filteredMedia.length" class="text-center py-16">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2a4 4 0 014-4h3m4 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V6a3 3 0 013-3h7a3 3 0 013 3v1" />
        </svg>
        <h4 class="mt-2 text-lg font-medium text-gray-700">No media found</h4>
        <p class="mt-1 text-sm text-gray-500">Try adjusting your search or filters.</p>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const searchQuery = ref('')
const filterType = ref('')
const mediaItems = ref([
  { id: 1, title: 'Wedding Photo', type: 'photo', date: '1975-06-10', thumbnail: '/media/wedding.jpg' },
  { id: 2, title: 'Family Reunion Video', type: 'video', date: '1990-08-15', thumbnail: '/media/reunion.jpg' },
  { id: 3, title: 'Birth Certificate', type: 'document', date: '1950-01-15', thumbnail: '/media/birth-cert.jpg' }
])
const filteredMedia = computed(() => {
  return mediaItems.value.filter(item => {
    const matchesType = !filterType.value || item.type === filterType.value
    const matchesQuery = !searchQuery.value || item.title.toLowerCase().includes(searchQuery.value.toLowerCase())
    return matchesType && matchesQuery
  })
})
const goToDetail = (id) => {
  router.push(`/media/${id}`)
}
</script> 