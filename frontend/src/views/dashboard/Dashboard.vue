<template>
  <div class="min-h-screen bg-gray-100">
    <div class="py-10">
      <header>
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <h1 class="text-3xl font-bold leading-tight tracking-tight text-gray-900">Dashboard</h1>
        </div>
      </header>
      <main>
        <div class="mx-auto max-w-7xl sm:px-6 lg:px-8">
          <!-- Welcome Section -->
          <div class="px-4 py-5 sm:px-6">
            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="px-4 py-5 sm:p-6">
                <h3 class="text-lg font-medium leading-6 text-gray-900">Welcome back, {{ userStore.user?.name }}</h3>
                <div class="mt-2 max-w-xl text-sm text-gray-500">
                  <p>Here's an overview of your family trees and recent activity.</p>
                </div>
              </div>
            </div>
          </div>

          <!-- Quick Actions -->
          <div class="mt-8">
            <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
              <!-- Create New Tree -->
              <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="px-4 py-5 sm:p-6">
                  <h3 class="text-lg font-medium leading-6 text-gray-900">Create New Tree</h3>
                  <div class="mt-2 max-w-xl text-sm text-gray-500">
                    <p>Start a new family tree or import an existing one.</p>
                  </div>
                  <div class="mt-5">
                    <router-link
                      to="/trees/new"
                      class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    >
                      Create Tree
                    </router-link>
                  </div>
                </div>
              </div>

              <!-- Import Tree -->
              <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="px-4 py-5 sm:p-6">
                  <h3 class="text-lg font-medium leading-6 text-gray-900">Import Tree</h3>
                  <div class="mt-2 max-w-xl text-sm text-gray-500">
                    <p>Import a family tree from GEDCOM or other formats.</p>
                  </div>
                  <div class="mt-5">
                    <router-link
                      to="/trees/import"
                      class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    >
                      Import Tree
                    </router-link>
                  </div>
                </div>
              </div>

              <!-- Recent Activity -->
              <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="px-4 py-5 sm:p-6">
                  <h3 class="text-lg font-medium leading-6 text-gray-900">Recent Activity</h3>
                  <div class="mt-2 max-w-xl text-sm text-gray-500">
                    <p>View your recent changes and updates.</p>
                  </div>
                  <div class="mt-5">
                    <router-link
                      to="/activity"
                      class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    >
                      View Activity
                    </router-link>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Your Trees -->
          <div class="mt-8">
            <div class="bg-white shadow rounded-lg">
              <div class="px-4 py-5 sm:px-6">
                <h3 class="text-lg font-medium leading-6 text-gray-900">Your Family Trees</h3>
              </div>
              <div class="border-t border-gray-200">
                <ul role="list" class="divide-y divide-gray-200">
                  <li v-for="tree in treesStore.trees" :key="tree.id" class="px-4 py-4 sm:px-6">
                    <div class="flex items-center justify-between">
                      <div class="flex items-center">
                        <div class="flex-shrink-0">
                          <svg class="h-6 w-6 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
                          </svg>
                        </div>
                        <div class="ml-4">
                          <div class="text-sm font-medium text-indigo-600">
                            <router-link :to="`/trees/${tree.id}`">{{ tree.name }}</router-link>
                          </div>
                          <div class="text-sm text-gray-500">
                            {{ tree.description }}
                          </div>
                        </div>
                      </div>
                      <div class="flex items-center space-x-4">
                        <span class="text-sm text-gray-500">
                          {{ tree.memberCount }} members
                        </span>
                        <div class="flex space-x-2">
                          <button
                            @click="editTree(tree)"
                            class="text-gray-400 hover:text-gray-500"
                          >
                            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                            </svg>
                          </button>
                          <button
                            @click="deleteTree(tree)"
                            class="text-gray-400 hover:text-gray-500"
                          >
                            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                          </button>
                        </div>
                      </div>
                    </div>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          <!-- Recent Activity Feed -->
          <div class="mt-8">
            <div class="bg-white shadow rounded-lg">
              <div class="px-4 py-5 sm:px-6">
                <h3 class="text-lg font-medium leading-6 text-gray-900">Recent Activity</h3>
              </div>
              <div class="border-t border-gray-200">
                <ul role="list" class="divide-y divide-gray-200">
                  <li v-for="activity in recentActivity" :key="activity.id" class="px-4 py-4 sm:px-6">
                    <div class="flex items-center space-x-4">
                      <div class="flex-shrink-0">
                        <span class="inline-flex items-center justify-center h-8 w-8 rounded-full bg-gray-100">
                          <span class="text-sm font-medium leading-none text-gray-600">
                            {{ activity.userInitials }}
                          </span>
                        </span>
                      </div>
                      <div class="flex-1 min-w-0">
                        <p class="text-sm font-medium text-gray-900 truncate">
                          {{ activity.description }}
                        </p>
                        <p class="text-sm text-gray-500">
                          {{ formatDate(activity.timestamp) }}
                        </p>
                      </div>
                    </div>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useUserStore } from '@/stores/user'
import { useTreesStore } from '@/stores/trees'
import { format } from 'date-fns'

const userStore = useUserStore()
const treesStore = useTreesStore()

const recentActivity = ref([
  {
    id: 1,
    userInitials: 'JD',
    description: 'Added new family member: John Smith',
    timestamp: new Date('2024-03-15T10:30:00')
  },
  {
    id: 2,
    userInitials: 'MS',
    description: 'Updated profile information for Mary Johnson',
    timestamp: new Date('2024-03-15T09:15:00')
  },
  {
    id: 3,
    userInitials: 'RS',
    description: 'Uploaded new photo to family album',
    timestamp: new Date('2024-03-14T16:45:00')
  }
])

const formatDate = (date) => {
  return format(date, 'MMM d, yyyy h:mm a')
}

const editTree = (tree) => {
  // Implement tree editing logic
  console.log('Edit tree:', tree)
}

const deleteTree = async (tree) => {
  if (confirm(`Are you sure you want to delete "${tree.name}"?`)) {
    try {
      await treesStore.deleteTree(tree.id)
    } catch (error) {
      console.error('Error deleting tree:', error)
    }
  }
}

onMounted(async () => {
  try {
    await treesStore.fetchTrees()
  } catch (error) {
    console.error('Error fetching trees:', error)
  }
})
</script> 