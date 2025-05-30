<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          Keyboard Shortcuts
        </h1>
        <p class="mt-4 text-lg text-gray-500">
          Speed up your workflow with these keyboard shortcuts
        </p>
      </div>

      <!-- Search -->
      <div class="max-w-2xl mx-auto mb-12">
        <div class="relative">
          <input
            type="text"
            v-model="searchQuery"
            placeholder="Search shortcuts..."
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
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

      <!-- Shortcuts -->
      <div class="bg-white rounded-lg shadow-lg p-6">
        <div class="space-y-8">
          <div
            v-for="(shortcuts, category) in filteredShortcuts"
            :key="category"
            class="border-b border-gray-200 last:border-0 pb-8 last:pb-0"
          >
            <h2 class="text-2xl font-bold text-gray-900 mb-6">
              {{ getCategoryName(category) }}
            </h2>
            <div class="grid gap-6">
              <div
                v-for="shortcut in shortcuts"
                :key="shortcut.action"
                class="bg-gray-50 rounded-lg p-6"
              >
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <h3 class="text-lg font-medium text-gray-900 mb-2">
                      {{ shortcut.action }}
                    </h3>
                    <p class="text-gray-600">{{ shortcut.description }}</p>
                  </div>
                  <div class="ml-4">
                    <div class="flex flex-wrap gap-2">
                      <span
                        v-for="(key, index) in shortcut.keys"
                        :key="index"
                        class="inline-flex items-center px-2.5 py-1 rounded-md text-sm font-medium bg-gray-100 text-gray-800"
                      >
                        {{ key }}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Tips -->
      <div class="mt-12 bg-indigo-50 rounded-lg p-6">
        <h2 class="text-xl font-bold text-indigo-900 mb-4">
          Tips for Using Keyboard Shortcuts
        </h2>
        <ul class="space-y-3 text-indigo-800">
          <li class="flex items-start">
            <svg
              class="h-6 w-6 text-indigo-500 mr-2"
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
            <span>Use the search bar to quickly find specific shortcuts</span>
          </li>
          <li class="flex items-start">
            <svg
              class="h-6 w-6 text-indigo-500 mr-2"
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
            <span>Filter by category to focus on specific areas of the application</span>
          </li>
          <li class="flex items-start">
            <svg
              class="h-6 w-6 text-indigo-500 mr-2"
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
            <span>Most shortcuts can be used from anywhere in the application</span>
          </li>
          <li class="flex items-start">
            <svg
              class="h-6 w-6 text-indigo-500 mr-2"
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
            <span>Some shortcuts may vary depending on your operating system</span>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const categories = [
  { id: 'all', name: 'All Shortcuts' },
  { id: 'navigation', name: 'Navigation' },
  { id: 'editing', name: 'Editing' },
  { id: 'view', name: 'View' },
  { id: 'media', name: 'Media' },
  { id: 'search', name: 'Search' }
]

const selectedCategory = ref('all')
const searchQuery = ref('')

const shortcuts = {
  navigation: [
    {
      action: 'Go to Home',
      description: 'Return to the main dashboard',
      keys: ['Ctrl', 'H']
    },
    {
      action: 'Go to Family Tree',
      description: 'Open the family tree view',
      keys: ['Ctrl', 'T']
    },
    {
      action: 'Go to Profile',
      description: 'Open your profile page',
      keys: ['Ctrl', 'P']
    },
    {
      action: 'Go to Settings',
      description: 'Open the settings page',
      keys: ['Ctrl', ',', '⌘', ',']
    }
  ],
  editing: [
    {
      action: 'Add Person',
      description: 'Create a new person in the family tree',
      keys: ['Ctrl', 'N']
    },
    {
      action: 'Edit Person',
      description: 'Edit the selected person',
      keys: ['Ctrl', 'E']
    },
    {
      action: 'Delete Person',
      description: 'Remove the selected person',
      keys: ['Ctrl', 'Delete']
    },
    {
      action: 'Save Changes',
      description: 'Save all pending changes',
      keys: ['Ctrl', 'S']
    }
  ],
  view: [
    {
      action: 'Zoom In',
      description: 'Increase the zoom level',
      keys: ['Ctrl', '+']
    },
    {
      action: 'Zoom Out',
      description: 'Decrease the zoom level',
      keys: ['Ctrl', '-']
    },
    {
      action: 'Reset Zoom',
      description: 'Return to default zoom level',
      keys: ['Ctrl', '0']
    },
    {
      action: 'Toggle Fullscreen',
      description: 'Enter or exit fullscreen mode',
      keys: ['F11']
    }
  ],
  media: [
    {
      action: 'Upload Media',
      description: 'Open the media upload dialog',
      keys: ['Ctrl', 'U']
    },
    {
      action: 'View Media Gallery',
      description: 'Open the media gallery',
      keys: ['Ctrl', 'G']
    },
    {
      action: 'Attach Media',
      description: 'Attach media to selected person',
      keys: ['Ctrl', 'M']
    }
  ],
  search: [
    {
      action: 'Quick Search',
      description: 'Open the quick search dialog',
      keys: ['Ctrl', 'F']
    },
    {
      action: 'Advanced Search',
      description: 'Open the advanced search page',
      keys: ['Ctrl', 'Shift', 'F']
    },
    {
      action: 'Find Next',
      description: 'Find the next search result',
      keys: ['F3']
    },
    {
      action: 'Find Previous',
      description: 'Find the previous search result',
      keys: ['Shift', 'F3']
    }
  ]
}

const filteredShortcuts = computed(() => {
  let filtered = { ...shortcuts }

  // Apply category filter
  if (selectedCategory.value !== 'all') {
    const category = selectedCategory.value
    filtered = { [category]: shortcuts[category] }
  }

  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    const result = {}

    Object.entries(filtered).forEach(([category, categoryShortcuts]) => {
      const matchingShortcuts = categoryShortcuts.filter(shortcut => {
        const searchableText = [
          shortcut.action,
          shortcut.description,
          ...shortcut.keys
        ].join(' ').toLowerCase()
        return searchableText.includes(query)
      })

      if (matchingShortcuts.length > 0) {
        result[category] = matchingShortcuts
      }
    })

    filtered = result
  }

  return filtered
})

const getCategoryName = (categoryId) => {
  const category = categories.find(c => c.id === categoryId)
  return category ? category.name : categoryId
}
</script> 