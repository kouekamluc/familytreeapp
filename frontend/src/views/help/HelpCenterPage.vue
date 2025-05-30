<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          Help Center
        </h1>
        <p class="mt-4 text-lg text-gray-500">
          Find the help you need to make the most of your family tree
        </p>
      </div>

      <!-- Search -->
      <div class="max-w-2xl mx-auto mb-12">
        <div class="relative">
          <input
            type="text"
            v-model="searchQuery"
            placeholder="Search help topics..."
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
          />
          <div class="absolute inset-y-0 right-0 flex items-center pr-3">
            <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
        </div>
      </div>

      <!-- Quick Links -->
      <div class="mb-12">
        <h2 class="text-xl font-bold text-gray-900 mb-6">Quick Links</h2>
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <router-link
            v-for="link in quickLinks"
            :key="link.title"
            :to="link.to"
            class="flex items-center p-4 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow"
          >
            <div class="flex-shrink-0">
              <component :is="link.icon" class="h-6 w-6 text-indigo-600" />
            </div>
            <div class="ml-4">
              <h3 class="text-sm font-medium text-gray-900">{{ link.title }}</h3>
              <p class="text-sm text-gray-500">{{ link.description }}</p>
            </div>
          </router-link>
        </div>
      </div>

      <!-- Help Categories -->
      <div class="grid grid-cols-1 gap-8 md:grid-cols-2">
        <div v-for="category in filteredCategories" :key="category.title" class="bg-white rounded-lg shadow-lg p-6">
          <div class="flex items-center mb-4">
            <component :is="category.icon" class="h-6 w-6 text-indigo-600" />
            <h2 class="ml-3 text-xl font-bold text-gray-900">{{ category.title }}</h2>
          </div>
          <div class="space-y-4">
            <router-link
              v-for="topic in category.topics"
              :key="topic.title"
              :to="topic.to"
              class="block p-4 rounded-lg hover:bg-gray-50"
            >
              <h3 class="text-lg font-medium text-gray-900">{{ topic.title }}</h3>
              <p class="mt-1 text-sm text-gray-500">{{ topic.description }}</p>
            </router-link>
          </div>
        </div>
      </div>

      <!-- Contact Support -->
      <div class="mt-12 text-center">
        <p class="text-gray-600 mb-4">Need more help?</p>
        <router-link
          to="/help/contact"
          class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
        >
          Contact Support
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import {
  HomeIcon,
  UserGroupIcon,
  PhotoIcon,
  CogIcon,
  ShieldCheckIcon,
  QuestionMarkCircleIcon,
  BookOpenIcon,
  VideoCameraIcon,
  ChatBubbleLeftRightIcon,
  DocumentTextIcon,
  UserCircleIcon,
  ChartBarIcon
} from '@heroicons/vue/24/outline'

const searchQuery = ref('')

const quickLinks = [
  {
    title: 'Getting Started',
    description: 'Learn the basics',
    to: '/help/getting-started',
    icon: HomeIcon
  },
  {
    title: 'FAQ',
    description: 'Common questions',
    to: '/help/faq',
    icon: QuestionMarkCircleIcon
  },
  {
    title: 'User Guide',
    description: 'Detailed documentation',
    to: '/help/guide',
    icon: BookOpenIcon
  },
  {
    title: 'Video Tutorials',
    description: 'Watch and learn',
    to: '/help/tutorials',
    icon: VideoCameraIcon
  }
]

const categories = [
  {
    title: 'Family Tree Basics',
    icon: UserGroupIcon,
    topics: [
      {
        title: 'Creating Your First Tree',
        description: 'Learn how to start building your family tree',
        to: '/help/creating-tree'
      },
      {
        title: 'Adding Family Members',
        description: 'Add and manage people in your tree',
        to: '/help/adding-members'
      },
      {
        title: 'Managing Relationships',
        description: 'Define and edit family relationships',
        to: '/help/relationships'
      }
    ]
  },
  {
    title: 'Media & Photos',
    icon: PhotoIcon,
    topics: [
      {
        title: 'Uploading Photos',
        description: 'Add photos to your family tree',
        to: '/help/uploading-photos'
      },
      {
        title: 'Organizing Media',
        description: 'Create albums and organize your media',
        to: '/help/organizing-media'
      },
      {
        title: 'Photo Editing',
        description: 'Edit and enhance your photos',
        to: '/help/photo-editing'
      }
    ]
  },
  {
    title: 'Privacy & Security',
    icon: ShieldCheckIcon,
    topics: [
      {
        title: 'Privacy Settings',
        description: 'Control who can see your tree',
        to: '/help/privacy-settings'
      },
      {
        title: 'Data Protection',
        description: 'How we protect your information',
        to: '/help/data-protection'
      },
      {
        title: 'Account Security',
        description: 'Keep your account secure',
        to: '/help/account-security'
      }
    ]
  },
  {
    title: 'Advanced Features',
    icon: CogIcon,
    topics: [
      {
        title: 'Tree Statistics',
        description: 'View insights about your tree',
        to: '/help/tree-statistics'
      },
      {
        title: 'Collaboration',
        description: 'Work together with family members',
        to: '/help/collaboration'
      },
      {
        title: 'Import/Export',
        description: 'Transfer your tree data',
        to: '/help/import-export'
      }
    ]
  }
]

const filteredCategories = computed(() => {
  const query = searchQuery.value.toLowerCase()
  if (!query) return categories

  return categories.map(category => ({
    ...category,
    topics: category.topics.filter(topic =>
      topic.title.toLowerCase().includes(query) ||
      topic.description.toLowerCase().includes(query)
    )
  })).filter(category => category.topics.length > 0)
})
</script> 