<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          Video Tutorials
        </h1>
        <p class="mt-4 text-lg text-gray-500">
          Learn how to use Family Tree through our video tutorials
        </p>
      </div>

      <!-- Search -->
      <div class="max-w-2xl mx-auto mb-12">
        <div class="relative">
          <input
            type="text"
            v-model="searchQuery"
            placeholder="Search tutorials..."
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
          />
          <div class="absolute inset-y-0 right-0 flex items-center pr-3">
            <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
        </div>
      </div>

      <!-- Categories -->
      <div class="mb-8">
        <div class="flex flex-wrap gap-2">
          <button
            v-for="category in categories"
            :key="category.id"
            @click="selectedCategory = category.id"
            :class="[
              'px-4 py-2 text-sm font-medium rounded-md',
              selectedCategory === category.id
                ? 'bg-indigo-100 text-indigo-700'
                : 'bg-white text-gray-700 hover:bg-gray-50'
            ]"
          >
            {{ category.name }}
          </button>
        </div>
      </div>

      <!-- Video Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        <div
          v-for="video in filteredVideos"
          :key="video.id"
          class="bg-white rounded-lg shadow-lg overflow-hidden"
        >
          <!-- Video Thumbnail -->
          <div class="relative aspect-video">
            <img
              :src="video.thumbnail"
              :alt="video.title"
              class="w-full h-full object-cover"
            />
            <div class="absolute inset-0 flex items-center justify-center">
              <button
                @click="playVideo(video)"
                class="p-4 bg-black bg-opacity-50 rounded-full hover:bg-opacity-75 transition-opacity"
              >
                <svg class="h-8 w-8 text-white" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M8 5v14l11-7z" />
                </svg>
              </button>
            </div>
            <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black to-transparent p-4">
              <span class="text-white text-sm">{{ video.duration }}</span>
            </div>
          </div>

          <!-- Video Info -->
          <div class="p-6">
            <h3 class="text-lg font-medium text-gray-900 mb-2">
              {{ video.title }}
            </h3>
            <p class="text-gray-500 text-sm mb-4">
              {{ video.description }}
            </p>
            <div class="flex items-center justify-between">
              <div class="flex items-center">
                <img
                  :src="video.author.avatar"
                  :alt="video.author.name"
                  class="h-8 w-8 rounded-full"
                />
                <span class="ml-2 text-sm text-gray-600">
                  {{ video.author.name }}
                </span>
              </div>
              <div class="flex items-center space-x-4">
                <button
                  @click="toggleBookmark(video)"
                  class="text-gray-400 hover:text-indigo-600"
                >
                  <svg
                    class="h-5 w-5"
                    :class="{ 'text-indigo-600': video.isBookmarked }"
                    fill="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path d="M17 3H7c-1.1 0-2 .9-2 2v16l7-3 7 3V5c0-1.1-.9-2-2-2z" />
                  </svg>
                </button>
                <button
                  @click="shareVideo(video)"
                  class="text-gray-400 hover:text-indigo-600"
                >
                  <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Video Player Modal -->
      <div
        v-if="selectedVideo"
        class="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50"
        @click.self="selectedVideo = null"
      >
        <div class="bg-white rounded-lg max-w-4xl w-full mx-4">
          <div class="relative aspect-video">
            <iframe
              :src="selectedVideo.embedUrl"
              class="w-full h-full rounded-t-lg"
              frameborder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
              allowfullscreen
            ></iframe>
          </div>
          <div class="p-6">
            <h3 class="text-xl font-medium text-gray-900 mb-2">
              {{ selectedVideo.title }}
            </h3>
            <p class="text-gray-500">
              {{ selectedVideo.description }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useToast } from 'vue-toastification'

const toast = useToast()
const searchQuery = ref('')
const selectedCategory = ref('all')
const selectedVideo = ref(null)

const categories = [
  { id: 'all', name: 'All Tutorials' },
  { id: 'getting-started', name: 'Getting Started' },
  { id: 'tree-management', name: 'Tree Management' },
  { id: 'media', name: 'Media & Photos' },
  { id: 'privacy', name: 'Privacy & Security' },
  { id: 'advanced', name: 'Advanced Features' }
]

const videos = [
  {
    id: 1,
    title: 'Getting Started with Family Tree',
    description: 'Learn the basics of creating and managing your family tree.',
    thumbnail: '/thumbnails/getting-started.jpg',
    duration: '5:30',
    category: 'getting-started',
    embedUrl: 'https://www.youtube.com/embed/example1',
    author: {
      name: 'Sarah Johnson',
      avatar: '/avatars/sarah.jpg'
    },
    isBookmarked: false
  },
  {
    id: 2,
    title: 'Adding Family Members',
    description: 'Step-by-step guide to adding and managing family members.',
    thumbnail: '/thumbnails/adding-members.jpg',
    duration: '7:15',
    category: 'tree-management',
    embedUrl: 'https://www.youtube.com/embed/example2',
    author: {
      name: 'Michael Chen',
      avatar: '/avatars/michael.jpg'
    },
    isBookmarked: false
  },
  {
    id: 3,
    title: 'Managing Photos and Documents',
    description: 'Learn how to organize and share family photos and documents.',
    thumbnail: '/thumbnails/media-management.jpg',
    duration: '8:45',
    category: 'media',
    embedUrl: 'https://www.youtube.com/embed/example3',
    author: {
      name: 'Emily Davis',
      avatar: '/avatars/emily.jpg'
    },
    isBookmarked: false
  },
  {
    id: 4,
    title: 'Privacy Settings Explained',
    description: 'Understanding and configuring your privacy settings.',
    thumbnail: '/thumbnails/privacy-settings.jpg',
    duration: '6:20',
    category: 'privacy',
    embedUrl: 'https://www.youtube.com/embed/example4',
    author: {
      name: 'David Wilson',
      avatar: '/avatars/david.jpg'
    },
    isBookmarked: false
  },
  {
    id: 5,
    title: 'Advanced Search Techniques',
    description: 'Master the advanced search features to find family members.',
    thumbnail: '/thumbnails/advanced-search.jpg',
    duration: '9:10',
    category: 'advanced',
    embedUrl: 'https://www.youtube.com/embed/example5',
    author: {
      name: 'Lisa Brown',
      avatar: '/avatars/lisa.jpg'
    },
    isBookmarked: false
  },
  {
    id: 6,
    title: 'Collaborating with Family',
    description: 'Learn how to work together with family members on your tree.',
    thumbnail: '/thumbnails/collaboration.jpg',
    duration: '7:50',
    category: 'advanced',
    embedUrl: 'https://www.youtube.com/embed/example6',
    author: {
      name: 'James Wilson',
      avatar: '/avatars/james.jpg'
    },
    isBookmarked: false
  }
]

const filteredVideos = computed(() => {
  let filtered = videos

  // Apply category filter
  if (selectedCategory.value !== 'all') {
    filtered = filtered.filter(video => video.category === selectedCategory.value)
  }

  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(video =>
      video.title.toLowerCase().includes(query) ||
      video.description.toLowerCase().includes(query) ||
      video.author.name.toLowerCase().includes(query)
    )
  }

  return filtered
})

const playVideo = (video) => {
  selectedVideo.value = video
}

const toggleBookmark = (video) => {
  video.isBookmarked = !video.isBookmarked
  toast.success(
    video.isBookmarked
      ? 'Video added to bookmarks'
      : 'Video removed from bookmarks'
  )
}

const shareVideo = (video) => {
  // Implement sharing functionality
  toast.info('Sharing functionality coming soon!')
}
</script> 