<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="mb-8">
        <button
          @click="router.back()"
          class="inline-flex items-center text-sm text-gray-600 hover:text-gray-900"
        >
          <svg class="h-5 w-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
          Back to Gallery
        </button>
      </div>

      <div class="bg-white rounded-lg shadow-lg overflow-hidden">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 p-6">
          <!-- Media Preview -->
          <div class="space-y-4">
            <div class="aspect-w-16 aspect-h-9 bg-gray-200 rounded-lg overflow-hidden">
              <img
                v-if="media.type === 'photo'"
                :src="media.url"
                :alt="media.title"
                class="object-cover w-full h-full"
              />
              <video
                v-else-if="media.type === 'video'"
                :src="media.url"
                controls
                class="w-full h-full"
              ></video>
              <div
                v-else
                class="flex items-center justify-center h-full bg-gray-100"
              >
                <svg class="h-16 w-16 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
            </div>
            <div class="flex gap-2">
              <button
                class="flex-1 bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700"
                @click="downloadMedia"
              >
                Download
              </button>
              <button
                class="flex-1 bg-white border border-gray-300 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-50"
                @click="shareMedia"
              >
                Share
              </button>
            </div>
          </div>

          <!-- Media Details -->
          <div class="space-y-6">
            <div>
              <h1 class="text-2xl font-bold text-gray-900">{{ media.title }}</h1>
              <p class="text-sm text-gray-500 mt-1">
                Added on {{ formatDate(media.createdAt) }}
              </p>
            </div>

            <div class="space-y-4">
              <div>
                <h3 class="text-sm font-medium text-gray-500">Description</h3>
                <p class="mt-1 text-gray-900">{{ media.description }}</p>
              </div>

              <div>
                <h3 class="text-sm font-medium text-gray-500">Metadata</h3>
                <dl class="mt-2 grid grid-cols-2 gap-4">
                  <div>
                    <dt class="text-sm text-gray-500">Type</dt>
                    <dd class="text-sm text-gray-900 capitalize">{{ media.type }}</dd>
                  </div>
                  <div>
                    <dt class="text-sm text-gray-500">Date</dt>
                    <dd class="text-sm text-gray-900">{{ formatDate(media.date) }}</dd>
                  </div>
                  <div>
                    <dt class="text-sm text-gray-500">Location</dt>
                    <dd class="text-sm text-gray-900">{{ media.location || 'Not specified' }}</dd>
                  </div>
                  <div>
                    <dt class="text-sm text-gray-500">File Size</dt>
                    <dd class="text-sm text-gray-900">{{ formatFileSize(media.fileSize) }}</dd>
                  </div>
                </dl>
              </div>

              <div>
                <h3 class="text-sm font-medium text-gray-500">Related People</h3>
                <div class="mt-2 grid grid-cols-2 sm:grid-cols-3 gap-4">
                  <div
                    v-for="person in media.relatedPeople"
                    :key="person.id"
                    class="flex items-center space-x-3 p-2 rounded-lg hover:bg-gray-50 cursor-pointer"
                    @click="viewPerson(person.id)"
                  >
                    <img
                      :src="person.avatar"
                      :alt="person.name"
                      class="h-10 w-10 rounded-full"
                    />
                    <div>
                      <p class="text-sm font-medium text-gray-900">{{ person.name }}</p>
                      <p class="text-xs text-gray-500">{{ person.relationship }}</p>
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
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()
const media = ref({
  id: 1,
  title: 'Wedding Photo',
  type: 'photo',
  description: 'Family wedding photo from 1975',
  date: '1975-06-10',
  location: 'New York, USA',
  fileSize: 2500000,
  url: '/media/wedding.jpg',
  createdAt: '2024-01-15',
  relatedPeople: [
    {
      id: 1,
      name: 'John Smith',
      relationship: 'Grandfather',
      avatar: '/avatars/john.jpg'
    },
    {
      id: 2,
      name: 'Mary Smith',
      relationship: 'Grandmother',
      avatar: '/avatars/mary.jpg'
    }
  ]
})

const formatDate = (date) => {
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

const downloadMedia = () => {
  // Implement download logic
  console.log('Downloading media:', media.value.id)
}

const shareMedia = () => {
  // Implement share logic
  console.log('Sharing media:', media.value.id)
}

const viewPerson = (personId) => {
  router.push(`/people/${personId}`)
}

onMounted(() => {
  // Fetch media details using route.params.id
  console.log('Loading media:', route.params.id)
})
</script> 