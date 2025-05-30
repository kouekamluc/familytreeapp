<template>
  <div class="min-h-screen">
    <!-- Hero Section -->
    <div class="relative bg-white overflow-hidden">
      <div class="max-w-7xl mx-auto">
        <div class="relative z-10 pb-8 bg-white sm:pb-16 md:pb-20 lg:max-w-2xl lg:w-full lg:pb-28 xl:pb-32">
          <main class="mt-10 mx-auto max-w-7xl px-4 sm:mt-12 sm:px-6 md:mt-16 lg:mt-20 lg:px-8 xl:mt-28">
            <div class="sm:text-center lg:text-left">
              <h1 class="text-4xl tracking-tight font-extrabold text-gray-900 sm:text-5xl md:text-6xl">
                <span class="block">Preserve Your</span>
                <span class="block text-indigo-600">Family History</span>
              </h1>
              <p class="mt-3 text-base text-gray-500 sm:mt-5 sm:text-lg sm:max-w-xl sm:mx-auto md:mt-5 md:text-xl lg:mx-0">
                Create, share, and preserve your family tree with our intuitive platform. Connect generations, share stories, and build a lasting legacy for future generations.
              </p>
              <div class="mt-5 sm:mt-8 sm:flex sm:justify-center lg:justify-start">
                <div class="rounded-md shadow">
                  <router-link
                    to="/register"
                    class="w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 md:py-4 md:text-lg md:px-10"
                  >
                    Get Started
                  </router-link>
                </div>
                <div class="mt-3 sm:mt-0 sm:ml-3">
                  <router-link
                    to="/help"
                    class="w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 md:py-4 md:text-lg md:px-10"
                  >
                    Learn More
                  </router-link>
                </div>
              </div>
            </div>
          </main>
        </div>
      </div>
      <div class="lg:absolute lg:inset-y-0 lg:right-0 lg:w-1/2">
        <img
          class="h-56 w-full object-cover sm:h-72 md:h-96 lg:w-full lg:h-full"
          src="/images/hero-family.jpg"
          alt="Family gathering"
        />
      </div>
    </div>

    <!-- Features Section -->
    <div class="py-12 bg-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="lg:text-center">
          <h2 class="text-base text-indigo-600 font-semibold tracking-wide uppercase">Features</h2>
          <p class="mt-2 text-3xl leading-8 font-extrabold tracking-tight text-gray-900 sm:text-4xl">
            Everything you need to build your family tree
          </p>
          <p class="mt-4 max-w-2xl text-xl text-gray-500 lg:mx-auto">
            Our platform provides all the tools you need to create, manage, and share your family history.
          </p>
        </div>

        <div class="mt-10">
          <div class="space-y-10 md:space-y-0 md:grid md:grid-cols-2 md:gap-x-8 md:gap-y-10">
            <div v-for="feature in features" :key="feature.name" class="relative">
              <div class="absolute flex items-center justify-center h-12 w-12 rounded-md bg-indigo-500 text-white">
                <component :is="feature.icon" class="h-6 w-6" aria-hidden="true" />
              </div>
              <p class="ml-16 text-lg leading-6 font-medium text-gray-900">{{ feature.name }}</p>
              <p class="mt-2 ml-16 text-base text-gray-500">{{ feature.description }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Testimonials Section -->
    <div class="bg-gray-50 py-12">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="lg:text-center mb-12">
          <h2 class="text-base text-indigo-600 font-semibold tracking-wide uppercase">Testimonials</h2>
          <p class="mt-2 text-3xl leading-8 font-extrabold tracking-tight text-gray-900 sm:text-4xl">
            What our users say
          </p>
        </div>
        <div class="mt-10">
          <div class="grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-3">
            <div v-for="testimonial in testimonials" :key="testimonial.name" class="bg-white rounded-lg shadow-lg p-6">
              <div class="flex items-center mb-4">
                <img
                  :src="testimonial.avatar"
                  :alt="testimonial.name"
                  class="h-12 w-12 rounded-full"
                />
                <div class="ml-4">
                  <h4 class="text-lg font-medium text-gray-900">{{ testimonial.name }}</h4>
                  <p class="text-gray-500">{{ testimonial.role }}</p>
                </div>
              </div>
              <p class="text-gray-600">{{ testimonial.content }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- CTA Section -->
    <div class="bg-indigo-700">
      <div class="max-w-2xl mx-auto text-center py-16 px-4 sm:py-20 sm:px-6 lg:px-8">
        <h2 class="text-3xl font-extrabold text-white sm:text-4xl">
          <span class="block">Ready to start your family tree?</span>
          <span class="block">Join thousands of families today.</span>
        </h2>
        <p class="mt-4 text-lg leading-6 text-indigo-200">
          Start preserving your family history and create lasting connections with your loved ones.
        </p>
        <router-link
          to="/register"
          class="mt-8 w-full inline-flex items-center justify-center px-5 py-3 border border-transparent text-base font-medium rounded-md text-indigo-600 bg-white hover:bg-indigo-50 sm:w-auto"
        >
          Sign up for free
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const features = [
  {
    name: 'Easy Tree Building',
    description: 'Create and manage your family tree with our intuitive drag-and-drop interface.',
    icon: 'TreeIcon'
  },
  {
    name: 'Media Sharing',
    description: 'Upload and share photos, documents, and stories with your family members.',
    icon: 'PhotoIcon'
  },
  {
    name: 'Privacy Controls',
    description: 'Control who can see and edit your family tree with granular privacy settings.',
    icon: 'LockIcon'
  },
  {
    name: 'Collaboration',
    description: 'Invite family members to contribute to your family tree and share their stories.',
    icon: 'UserGroupIcon'
  },
  {
    name: 'Search & Discovery',
    description: 'Find relatives and discover connections with our powerful search tools.',
    icon: 'SearchIcon'
  },
  {
    name: 'Timeline View',
    description: 'Visualize your family history with interactive timelines and relationship maps.',
    icon: 'ClockIcon'
  }
]

const testimonials = [
  {
    name: 'Sarah Johnson',
    role: 'Family Historian',
    avatar: '/avatars/sarah.jpg',
    content: 'This platform has helped me connect with relatives I never knew existed. The interface is intuitive and the privacy features give me peace of mind.'
  },
  {
    name: 'Michael Chen',
    role: 'Genealogy Researcher',
    avatar: '/avatars/michael.jpg',
    content: 'As a professional genealogist, I appreciate the attention to detail and the powerful tools available. It\'s made my research much more efficient.'
  },
  {
    name: 'Emily Davis',
    role: 'Family Storyteller',
    avatar: '/avatars/emily.jpg',
    content: 'I love how easy it is to share family stories and photos. My children and grandchildren can now access our family history anytime.'
  }
]
</script> 