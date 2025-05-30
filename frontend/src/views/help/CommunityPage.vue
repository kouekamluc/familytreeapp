<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          Family Tree Community
        </h1>
        <p class="mt-4 text-lg text-gray-500">
          Connect with other family history enthusiasts and share your stories
        </p>
      </div>

      <!-- Stats -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
        <div
          v-for="stat in stats"
          :key="stat.label"
          class="bg-white rounded-lg shadow-lg p-6 text-center"
        >
          <div class="text-3xl font-bold text-indigo-600">{{ stat.value }}</div>
          <div class="mt-2 text-sm text-gray-500">{{ stat.label }}</div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="bg-white rounded-lg shadow-lg p-6 space-y-8">
        <!-- Community Features -->
        <section>
          <h2 class="text-2xl font-bold text-gray-900 mb-4">Community Features</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div
              v-for="feature in features"
              :key="feature.title"
              class="p-6 border rounded-lg"
            >
              <div class="flex items-center mb-4">
                <component
                  :is="feature.icon"
                  class="h-8 w-8 text-indigo-600"
                  aria-hidden="true"
                />
                <h3 class="ml-3 text-lg font-medium text-gray-900">
                  {{ feature.title }}
                </h3>
              </div>
              <p class="text-gray-500">{{ feature.description }}</p>
            </div>
          </div>
        </section>

        <!-- Discussion Forums -->
        <section>
          <h2 class="text-2xl font-bold text-gray-900 mb-4">Discussion Forums</h2>
          <div class="space-y-4">
            <div
              v-for="forum in forums"
              :key="forum.title"
              class="p-4 border rounded-lg hover:bg-gray-50"
            >
              <div class="flex justify-between items-center">
                <div>
                  <h3 class="text-lg font-medium text-gray-900">
                    {{ forum.title }}
                  </h3>
                  <p class="text-sm text-gray-500">{{ forum.description }}</p>
                </div>
                <div class="text-right">
                  <div class="text-sm text-gray-500">
                    {{ forum.topics }} topics
                  </div>
                  <div class="text-sm text-gray-500">
                    {{ forum.posts }} posts
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>

        <!-- Events -->
        <section>
          <h2 class="text-2xl font-bold text-gray-900 mb-4">Upcoming Events</h2>
          <div class="space-y-4">
            <div
              v-for="event in events"
              :key="event.title"
              class="p-4 border rounded-lg"
            >
              <div class="flex justify-between items-start">
                <div>
                  <h3 class="text-lg font-medium text-gray-900">
                    {{ event.title }}
                  </h3>
                  <p class="text-sm text-gray-500">{{ event.date }}</p>
                  <p class="mt-2 text-gray-600">{{ event.description }}</p>
                </div>
                <button
                  class="px-4 py-2 text-sm font-medium text-indigo-600 hover:text-indigo-800"
                >
                  Register
                </button>
              </div>
            </div>
          </div>
        </section>

        <!-- Success Stories -->
        <section>
          <h2 class="text-2xl font-bold text-gray-900 mb-4">Success Stories</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div
              v-for="story in successStories"
              :key="story.title"
              class="p-6 border rounded-lg"
            >
              <div class="flex items-center mb-4">
                <img
                  :src="story.avatar"
                  :alt="story.author"
                  class="h-12 w-12 rounded-full"
                />
                <div class="ml-4">
                  <h3 class="text-lg font-medium text-gray-900">
                    {{ story.title }}
                  </h3>
                  <p class="text-sm text-gray-500">by {{ story.author }}</p>
                </div>
              </div>
              <p class="text-gray-600">{{ story.content }}</p>
            </div>
          </div>
        </section>

        <!-- Join Community -->
        <section class="text-center">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">
            Join Our Community
          </h2>
          <p class="text-gray-600 mb-6">
            Connect with other family history enthusiasts and start sharing your stories
            today.
          </p>
          <div class="space-x-4">
            <button
              class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
            >
              Join Now
            </button>
            <button
              class="inline-flex items-center px-6 py-3 border border-gray-300 text-base font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
            >
              Learn More
            </button>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const stats = [
  {
    value: '10,000+',
    label: 'Active Members'
  },
  {
    value: '50,000+',
    label: 'Family Trees'
  },
  {
    value: '1M+',
    label: 'Shared Stories'
  }
]

const features = [
  {
    title: 'Discussion Forums',
    description: 'Join conversations about genealogy, family history, and research tips.',
    icon: 'ChatBubbleLeftRightIcon'
  },
  {
    title: 'Research Groups',
    description: 'Collaborate with others researching similar family lines or regions.',
    icon: 'UserGroupIcon'
  },
  {
    title: 'Expert Q&A',
    description: 'Get answers to your genealogy questions from experienced researchers.',
    icon: 'QuestionMarkCircleIcon'
  },
  {
    title: 'Success Stories',
    description: 'Share and read about amazing family history discoveries.',
    icon: 'StarIcon'
  }
]

const forums = [
  {
    title: 'Getting Started',
    description: 'New to genealogy? Start here!',
    topics: 150,
    posts: 1200
  },
  {
    title: 'Research Methods',
    description: 'Share and learn research techniques',
    topics: 200,
    posts: 1800
  },
  {
    title: 'DNA & Genetics',
    description: 'Discuss DNA testing and genetic genealogy',
    topics: 180,
    posts: 1500
  },
  {
    title: 'Regional Research',
    description: 'Connect with researchers in your area',
    topics: 250,
    posts: 2200
  }
]

const events = [
  {
    title: 'Virtual Genealogy Workshop',
    date: 'March 20, 2024 - 2:00 PM EST',
    description: 'Learn advanced research techniques from expert genealogists.'
  },
  {
    title: 'DNA Testing Q&A Session',
    date: 'March 25, 2024 - 7:00 PM EST',
    description: 'Get your DNA testing questions answered by genetic genealogy experts.'
  },
  {
    title: 'Family History Writing Workshop',
    date: 'April 1, 2024 - 3:00 PM EST',
    description: 'Learn how to write and preserve your family stories.'
  }
]

const successStories = [
  {
    title: 'Found My Long-Lost Cousins',
    author: 'Sarah Johnson',
    avatar: '/avatars/sarah.jpg',
    content: 'After years of searching, I finally connected with cousins I never knew existed. The community helped me break through a brick wall in my research.'
  },
  {
    title: 'Solved a Family Mystery',
    author: 'Michael Chen',
    avatar: '/avatars/michael.jpg',
    content: 'With the help of other researchers, I uncovered the truth about my great-grandfather\'s immigration story. The journey was incredible!'
  }
]
</script> 