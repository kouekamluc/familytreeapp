<template>
  <div class="py-10">
    <header>
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="md:flex md:items-center md:justify-between">
          <div class="min-w-0 flex-1">
            <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
              Family Trees
            </h2>
          </div>
          <div class="mt-4 flex md:ml-4 md:mt-0">
            <router-link
              to="/trees/create"
              class="ml-3 inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            >
              Create new tree
            </router-link>
          </div>
        </div>
      </div>
    </header>
    <main>
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <!-- Filters -->
        <div class="border-b border-gray-200 pb-5 sm:flex sm:items-center sm:justify-between">
          <h3 class="text-base font-semibold leading-6 text-gray-900">Filters</h3>
          <div class="mt-3 sm:ml-4 sm:mt-0">
            <div class="flex flex-wrap gap-4">
              <div class="flex items-center">
                <input
                  id="sort-by-date"
                  v-model="filters.sortBy"
                  name="sort-by"
                  type="radio"
                  value="date"
                  class="h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-600"
                />
                <label for="sort-by-date" class="ml-3 text-sm font-medium text-gray-700">Sort by date</label>
              </div>
              <div class="flex items-center">
                <input
                  id="sort-by-name"
                  v-model="filters.sortBy"
                  name="sort-by"
                  type="radio"
                  value="name"
                  class="h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-600"
                />
                <label for="sort-by-name" class="ml-3 text-sm font-medium text-gray-700">Sort by name</label>
              </div>
              <div class="flex items-center">
                <input
                  id="sort-by-size"
                  v-model="filters.sortBy"
                  name="sort-by"
                  type="radio"
                  value="size"
                  class="h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-600"
                />
                <label for="sort-by-size" class="ml-3 text-sm font-medium text-gray-700">Sort by size</label>
              </div>
            </div>
          </div>
        </div>

        <!-- Search -->
        <div class="mt-4">
          <div class="relative rounded-md shadow-sm">
            <input
              type="text"
              v-model="filters.search"
              class="block w-full rounded-md border-0 py-1.5 text-gray-900 ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
              placeholder="Search trees..."
            />
          </div>
        </div>

        <!-- Tree grid -->
        <div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          <div
            v-for="tree in filteredTrees"
            :key="tree.id"
            class="relative flex flex-col overflow-hidden rounded-lg border border-gray-200 bg-white"
          >
            <div class="aspect-h-4 aspect-w-3 bg-gray-200 sm:aspect-none sm:h-48">
              <img
                :src="tree.thumbnail || '/placeholder-tree.jpg'"
                :alt="tree.name"
                class="h-full w-full object-cover object-center sm:h-full sm:w-full"
              />
            </div>
            <div class="flex flex-1 flex-col space-y-2 p-4">
              <h3 class="text-sm font-medium text-gray-900">
                <router-link :to="`/trees/${tree.id}`">
                  <span aria-hidden="true" class="absolute inset-0" />
                  {{ tree.name }}
                </router-link>
              </h3>
              <p class="text-sm text-gray-500">{{ tree.description }}</p>
              <div class="mt-2 flex flex-1 flex-col justify-end">
                <dl class="flex space-x-4 text-sm text-gray-500">
                  <div>
                    <dt class="inline">Members:</dt>
                    <dd class="inline ml-1">{{ tree.memberCount }}</dd>
                  </div>
                  <div>
                    <dt class="inline">Last updated:</dt>
                    <dd class="inline ml-1">{{ new Date(tree.lastUpdated).toLocaleDateString() }}</dd>
                  </div>
                </dl>
              </div>
            </div>
            <div class="absolute top-4 right-4">
              <button
                type="button"
                class="rounded-full bg-white p-1 text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
                @click.stop="openTreeMenu(tree)"
              >
                <span class="sr-only">Open options</span>
                <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path d="M10 3a1.5 1.5 0 110 3 1.5 1.5 0 010-3zM10 8.5a1.5 1.5 0 110 3 1.5 1.5 0 010-3zM10 14a1.5 1.5 0 110 3 1.5 1.5 0 010-3z" />
                </svg>
              </button>
            </div>
          </div>
        </div>

        <!-- Empty state -->
        <div v-if="filteredTrees.length === 0" class="text-center py-12">
          <svg
            class="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            aria-hidden="true"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 13h6m-3-3v6m-9 1V7a2 2 0 012-2h6l2 2h6a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2z"
            />
          </svg>
          <h3 class="mt-2 text-sm font-semibold text-gray-900">No trees found</h3>
          <p class="mt-1 text-sm text-gray-500">Get started by creating a new family tree.</p>
          <div class="mt-6">
            <router-link
              to="/trees/create"
              class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
            >
              Create new tree
            </router-link>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'

const router = useRouter()
const toast = useToast()

const filters = ref({
  search: '',
  sortBy: 'date'
})

const trees = ref([
  {
    id: 1,
    name: 'Smith Family Tree',
    description: 'The Smith family history from 1800 to present',
    memberCount: 45,
    lastUpdated: '2024-02-20T10:30:00Z',
    thumbnail: null
  },
  {
    id: 2,
    name: 'Johnson Family Tree',
    description: 'Johnson family genealogy and history',
    memberCount: 32,
    lastUpdated: '2024-02-19T15:45:00Z',
    thumbnail: null
  },
  {
    id: 3,
    name: 'Williams Family Tree',
    description: 'Williams family records and stories',
    memberCount: 28,
    lastUpdated: '2024-02-18T09:15:00Z',
    thumbnail: null
  }
])

const filteredTrees = computed(() => {
  let result = [...trees.value]

  // Apply search filter
  if (filters.value.search) {
    const searchLower = filters.value.search.toLowerCase()
    result = result.filter(
      tree =>
        tree.name.toLowerCase().includes(searchLower) ||
        tree.description.toLowerCase().includes(searchLower)
    )
  }

  // Apply sorting
  result.sort((a, b) => {
    switch (filters.value.sortBy) {
      case 'name':
        return a.name.localeCompare(b.name)
      case 'size':
        return b.memberCount - a.memberCount
      case 'date':
      default:
        return new Date(b.lastUpdated) - new Date(a.lastUpdated)
    }
  })

  return result
})

const openTreeMenu = (tree) => {
  // TODO: Implement tree menu with options like edit, share, delete
  console.log('Open menu for tree:', tree)
}
</script> 