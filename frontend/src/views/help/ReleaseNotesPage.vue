<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          Release Notes
        </h1>
        <p class="mt-4 text-lg text-gray-500">
          Stay up to date with the latest changes and improvements
        </p>
      </div>

      <!-- Version Filter -->
      <div class="mb-8">
        <div class="flex items-center justify-between">
          <div class="flex space-x-4">
            <button
              v-for="filter in versionFilters"
              :key="filter.value"
              @click="selectedFilter = filter.value"
              :class="[
                'px-4 py-2 text-sm font-medium rounded-md',
                selectedFilter === filter.value
                  ? 'bg-indigo-100 text-indigo-700'
                  : 'text-gray-500 hover:text-gray-700'
              ]"
            >
              {{ filter.label }}
            </button>
          </div>
          <div class="relative">
            <input
              type="text"
              v-model="searchQuery"
              placeholder="Search release notes..."
              class="w-64 px-4 py-2 rounded-md border border-gray-300 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
            />
            <div class="absolute inset-y-0 right-0 flex items-center pr-3">
              <svg
                class="h-5 w-5 text-gray-400"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
            </div>
          </div>
        </div>
      </div>

      <!-- Release Notes -->
      <div class="space-y-8">
        <div
          v-for="release in filteredReleases"
          :key="release.version"
          class="bg-white rounded-lg shadow-lg overflow-hidden"
        >
          <!-- Version Header -->
          <div class="px-6 py-4 bg-gray-50 border-b border-gray-200">
            <div class="flex items-center justify-between">
              <div>
                <h2 class="text-xl font-bold text-gray-900">
                  Version {{ release.version }}
                </h2>
                <p class="text-sm text-gray-500">{{ release.date }}</p>
              </div>
              <div class="flex items-center space-x-2">
                <span
                  :class="[
                    'px-2 py-1 text-xs font-medium rounded-full',
                    release.type === 'major'
                      ? 'bg-green-100 text-green-800'
                      : release.type === 'minor'
                      ? 'bg-blue-100 text-blue-800'
                      : 'bg-gray-100 text-gray-800'
                  ]"
                >
                  {{ release.type }}
                </span>
              </div>
            </div>
          </div>

          <!-- Release Content -->
          <div class="px-6 py-4">
            <!-- Highlights -->
            <div v-if="release.highlights.length > 0" class="mb-6">
              <h3 class="text-lg font-medium text-gray-900 mb-3">
                Highlights
              </h3>
              <ul class="space-y-2">
                <li
                  v-for="highlight in release.highlights"
                  :key="highlight"
                  class="flex items-start"
                >
                  <svg
                    class="h-5 w-5 text-green-500 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                  <span class="ml-2 text-gray-600">{{ highlight }}</span>
                </li>
              </ul>
            </div>

            <!-- New Features -->
            <div v-if="release.newFeatures.length > 0" class="mb-6">
              <h3 class="text-lg font-medium text-gray-900 mb-3">
                New Features
              </h3>
              <ul class="space-y-2">
                <li
                  v-for="feature in release.newFeatures"
                  :key="feature"
                  class="flex items-start"
                >
                  <svg
                    class="h-5 w-5 text-indigo-500 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                    />
                  </svg>
                  <span class="ml-2 text-gray-600">{{ feature }}</span>
                </li>
              </ul>
            </div>

            <!-- Improvements -->
            <div v-if="release.improvements.length > 0" class="mb-6">
              <h3 class="text-lg font-medium text-gray-900 mb-3">
                Improvements
              </h3>
              <ul class="space-y-2">
                <li
                  v-for="improvement in release.improvements"
                  :key="improvement"
                  class="flex items-start"
                >
                  <svg
                    class="h-5 w-5 text-blue-500 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 10V3L4 14h7v7l9-11h-7z"
                    />
                  </svg>
                  <span class="ml-2 text-gray-600">{{ improvement }}</span>
                </li>
              </ul>
            </div>

            <!-- Bug Fixes -->
            <div v-if="release.bugFixes.length > 0" class="mb-6">
              <h3 class="text-lg font-medium text-gray-900 mb-3">
                Bug Fixes
              </h3>
              <ul class="space-y-2">
                <li
                  v-for="fix in release.bugFixes"
                  :key="fix"
                  class="flex items-start"
                >
                  <svg
                    class="h-5 w-5 text-red-500 mt-0.5"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                    />
                  </svg>
                  <span class="ml-2 text-gray-600">{{ fix }}</span>
                </li>
              </ul>
            </div>

            <!-- Technical Notes -->
            <div v-if="release.technicalNotes" class="mt-6 pt-6 border-t border-gray-200">
              <h3 class="text-lg font-medium text-gray-900 mb-3">
                Technical Notes
              </h3>
              <div class="prose prose-sm text-gray-600">
                {{ release.technicalNotes }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Pagination -->
      <div class="mt-8 flex justify-center">
        <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px">
          <button
            v-for="page in totalPages"
            :key="page"
            @click="currentPage = page"
            :class="[
              'relative inline-flex items-center px-4 py-2 border text-sm font-medium',
              currentPage === page
                ? 'z-10 bg-indigo-50 border-indigo-500 text-indigo-600'
                : 'bg-white border-gray-300 text-gray-500 hover:bg-gray-50'
            ]"
          >
            {{ page }}
          </button>
        </nav>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const versionFilters = [
  { label: 'All Versions', value: 'all' },
  { label: 'Major', value: 'major' },
  { label: 'Minor', value: 'minor' },
  { label: 'Patches', value: 'patch' }
]

const selectedFilter = ref('all')
const searchQuery = ref('')
const currentPage = ref(1)
const itemsPerPage = 5

const releases = [
  {
    version: '2.0.0',
    date: 'March 15, 2024',
    type: 'major',
    highlights: [
      'Complete redesign of the user interface',
      'New timeline visualization feature',
      'Enhanced privacy controls'
    ],
    newFeatures: [
      'DNA test results import and analysis',
      'Advanced search capabilities',
      'Collaborative editing tools',
      'Media gallery improvements'
    ],
    improvements: [
      'Faster tree loading performance',
      'Improved mobile responsiveness',
      'Enhanced data export options'
    ],
    bugFixes: [
      'Fixed issue with relationship calculations',
      'Resolved media upload problems',
      'Corrected date formatting in reports'
    ],
    technicalNotes: 'This release includes significant architectural changes to improve scalability and performance. Users may need to clear their browser cache for optimal performance.'
  },
  {
    version: '1.5.0',
    date: 'February 28, 2024',
    type: 'minor',
    highlights: [
      'New media management system',
      'Improved search functionality'
    ],
    newFeatures: [
      'Batch photo upload',
      'Advanced filtering options',
      'Custom relationship types'
    ],
    improvements: [
      'Faster search results',
      'Better mobile experience',
      'Enhanced privacy settings'
    ],
    bugFixes: [
      'Fixed photo rotation issues',
      'Resolved search indexing problems'
    ]
  },
  {
    version: '1.4.2',
    date: 'February 15, 2024',
    type: 'patch',
    highlights: [
      'Security improvements',
      'Performance optimizations'
    ],
    bugFixes: [
      'Fixed authentication issues',
      'Resolved data synchronization problems',
      'Corrected export formatting'
    ]
  }
]

const filteredReleases = computed(() => {
  let filtered = releases

  // Apply version filter
  if (selectedFilter.value !== 'all') {
    filtered = filtered.filter(release => release.type === selectedFilter.value)
  }

  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(release => {
      const searchableText = [
        release.version,
        ...(release.highlights || []),
        ...(release.newFeatures || []),
        ...(release.improvements || []),
        ...(release.bugFixes || []),
        release.technicalNotes
      ].join(' ').toLowerCase()
      return searchableText.includes(query)
    })
  }

  // Apply pagination
  const start = (currentPage.value - 1) * itemsPerPage
  return filtered.slice(start, start + itemsPerPage)
})

const totalPages = computed(() => {
  const totalItems = releases.length
  return Math.ceil(totalItems / itemsPerPage)
})
</script> 