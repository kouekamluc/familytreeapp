<template>
  <div class="min-h-screen bg-gray-100">
    <div class="py-6">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h1 class="text-2xl font-semibold text-gray-900">Dashboard</h1>
      </div>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-8">
        <!-- Stats -->
        <div class="mt-8">
          <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
            <div
              v-for="stat in stats"
              :key="stat.name"
              class="bg-white overflow-hidden shadow rounded-lg"
            >
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <component
                      :is="stat.icon"
                      class="h-6 w-6 text-gray-400"
                      aria-hidden="true"
                    />
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">
                        {{ stat.name }}
                      </dt>
                      <dd class="flex items-baseline">
                        <div class="text-2xl font-semibold text-gray-900">
                          {{ stat.value }}
                        </div>
                        <div
                          v-if="stat.change"
                          :class="[
                            stat.changeType === 'increase'
                              ? 'text-green-600'
                              : 'text-red-600',
                            'ml-2 flex items-baseline text-sm font-semibold'
                          ]"
                        >
                          <component
                            :is="stat.changeType === 'increase' ? 'ArrowUpIcon' : 'ArrowDownIcon'"
                            class="self-center flex-shrink-0 h-5 w-5"
                            aria-hidden="true"
                          />
                          <span class="sr-only">
                            {{ stat.changeType === 'increase' ? 'Increased' : 'Decreased' }} by
                          </span>
                          {{ stat.change }}
                        </div>
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Quick Actions -->
        <div class="mt-8">
          <h2 class="text-lg font-medium text-gray-900">Quick Actions</h2>
          <div class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <div
              v-for="action in quickActions"
              :key="action.name"
              class="relative rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm flex items-center space-x-3 hover:border-gray-400 focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-indigo-500"
            >
              <div class="flex-shrink-0">
                <component
                  :is="action.icon"
                  class="h-6 w-6 text-gray-400"
                  aria-hidden="true"
                />
              </div>
              <div class="flex-1 min-w-0">
                <router-link :to="action.href" class="focus:outline-none">
                  <span class="absolute inset-0" aria-hidden="true" />
                  <p class="text-sm font-medium text-gray-900">
                    {{ action.name }}
                  </p>
                  <p class="text-sm text-gray-500">
                    {{ action.description }}
                  </p>
                </router-link>
              </div>
            </div>
          </div>
        </div>

        <!-- Recent Activity -->
        <div class="mt-8">
          <h2 class="text-lg font-medium text-gray-900">Recent Activity</h2>
          <div class="mt-4 bg-white shadow overflow-hidden sm:rounded-md">
            <ul role="list" class="divide-y divide-gray-200">
              <li v-for="activity in recentActivity" :key="activity.id">
                <div class="px-4 py-4 sm:px-6">
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <img
                        :src="activity.user.avatar"
                        :alt="activity.user.name"
                        class="h-8 w-8 rounded-full"
                      />
                      <div class="ml-4">
                        <p class="text-sm font-medium text-gray-900">
                          {{ activity.user.name }}
                        </p>
                        <p class="text-sm text-gray-500">
                          {{ activity.action }}
                        </p>
                      </div>
                    </div>
                    <div class="ml-2 flex-shrink-0 flex">
                      <p class="text-sm text-gray-500">
                        {{ activity.time }}
                      </p>
                    </div>
                  </div>
                  <div class="mt-2 sm:flex sm:justify-between">
                    <div class="sm:flex">
                      <p class="flex items-center text-sm text-gray-500">
                        <component
                          :is="activity.icon"
                          class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400"
                          aria-hidden="true"
                        />
                        {{ activity.details }}
                      </p>
                    </div>
                  </div>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const stats = [
  {
    name: 'Total Family Members',
    value: '156',
    change: '12%',
    changeType: 'increase',
    icon: 'UserGroupIcon'
  },
  {
    name: 'Photos Uploaded',
    value: '2,345',
    change: '8%',
    changeType: 'increase',
    icon: 'PhotoIcon'
  },
  {
    name: 'Stories Shared',
    value: '89',
    change: '3%',
    changeType: 'decrease',
    icon: 'BookOpenIcon'
  },
  {
    name: 'Active Collaborators',
    value: '24',
    change: '15%',
    changeType: 'increase',
    icon: 'UserIcon'
  }
]

const quickActions = [
  {
    name: 'Add Family Member',
    description: 'Add a new person to your family tree',
    icon: 'UserPlusIcon',
    href: '/people/add'
  },
  {
    name: 'Upload Photos',
    description: 'Share family photos and documents',
    icon: 'UploadIcon',
    href: '/media/upload'
  },
  {
    name: 'Share Tree',
    description: 'Invite family members to collaborate',
    icon: 'ShareIcon',
    href: '/trees/share'
  },
  {
    name: 'Create Story',
    description: 'Write and share family stories',
    icon: 'PencilIcon',
    href: '/stories/create'
  },
  {
    name: 'View Timeline',
    description: 'Explore your family history',
    icon: 'ClockIcon',
    href: '/timeline'
  },
  {
    name: 'Search Records',
    description: 'Find historical records and documents',
    icon: 'SearchIcon',
    href: '/search'
  }
]

const recentActivity = [
  {
    id: 1,
    user: {
      name: 'Sarah Johnson',
      avatar: '/avatars/sarah.jpg'
    },
    action: 'added a new family member',
    details: 'Added John Smith as a cousin',
    time: '2 hours ago',
    icon: 'UserPlusIcon'
  },
  {
    id: 2,
    user: {
      name: 'Michael Chen',
      avatar: '/avatars/michael.jpg'
    },
    action: 'uploaded photos',
    details: 'Added 12 photos to the family album',
    time: '4 hours ago',
    icon: 'PhotoIcon'
  },
  {
    id: 3,
    user: {
      name: 'Emily Davis',
      avatar: '/avatars/emily.jpg'
    },
    action: 'shared a story',
    details: 'Shared "Our Family Vacation 2023"',
    time: '1 day ago',
    icon: 'BookOpenIcon'
  },
  {
    id: 4,
    user: {
      name: 'David Wilson',
      avatar: '/avatars/david.jpg'
    },
    action: 'updated profile',
    details: 'Updated contact information',
    time: '2 days ago',
    icon: 'PencilIcon'
  }
]
</script> 