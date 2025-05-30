<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          Frequently Asked Questions
        </h1>
        <p class="mt-4 text-lg text-gray-500">
          Find answers to common questions about our family tree platform
        </p>
      </div>

      <!-- Search -->
      <div class="max-w-2xl mx-auto mb-12">
        <div class="relative">
          <input
            type="text"
            v-model="searchQuery"
            placeholder="Search FAQs..."
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
          />
          <div class="absolute inset-y-0 right-0 flex items-center pr-3">
            <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
        </div>
      </div>

      <!-- FAQ Categories -->
      <div class="grid grid-cols-1 gap-8 md:grid-cols-2">
        <!-- Getting Started -->
        <div class="bg-white rounded-lg shadow-lg p-6">
          <h2 class="text-xl font-bold text-gray-900 mb-4">Getting Started</h2>
          <div class="space-y-4">
            <div v-for="(faq, index) in filteredFAQs.gettingStarted" :key="index" class="border-b border-gray-200 pb-4">
              <button
                @click="toggleFAQ('gettingStarted', index)"
                class="flex justify-between items-center w-full text-left"
              >
                <span class="text-lg font-medium text-gray-900">{{ faq.question }}</span>
                <svg
                  class="h-5 w-5 text-gray-500 transform transition-transform"
                  :class="{ 'rotate-180': faq.isOpen }"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                </svg>
              </button>
              <div v-show="faq.isOpen" class="mt-2 text-gray-600">
                {{ faq.answer }}
              </div>
            </div>
          </div>
        </div>

        <!-- Family Tree Management -->
        <div class="bg-white rounded-lg shadow-lg p-6">
          <h2 class="text-xl font-bold text-gray-900 mb-4">Family Tree Management</h2>
          <div class="space-y-4">
            <div v-for="(faq, index) in filteredFAQs.treeManagement" :key="index" class="border-b border-gray-200 pb-4">
              <button
                @click="toggleFAQ('treeManagement', index)"
                class="flex justify-between items-center w-full text-left"
              >
                <span class="text-lg font-medium text-gray-900">{{ faq.question }}</span>
                <svg
                  class="h-5 w-5 text-gray-500 transform transition-transform"
                  :class="{ 'rotate-180': faq.isOpen }"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                </svg>
              </button>
              <div v-show="faq.isOpen" class="mt-2 text-gray-600">
                {{ faq.answer }}
              </div>
            </div>
          </div>
        </div>

        <!-- Privacy & Security -->
        <div class="bg-white rounded-lg shadow-lg p-6">
          <h2 class="text-xl font-bold text-gray-900 mb-4">Privacy & Security</h2>
          <div class="space-y-4">
            <div v-for="(faq, index) in filteredFAQs.privacy" :key="index" class="border-b border-gray-200 pb-4">
              <button
                @click="toggleFAQ('privacy', index)"
                class="flex justify-between items-center w-full text-left"
              >
                <span class="text-lg font-medium text-gray-900">{{ faq.question }}</span>
                <svg
                  class="h-5 w-5 text-gray-500 transform transition-transform"
                  :class="{ 'rotate-180': faq.isOpen }"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                </svg>
              </button>
              <div v-show="faq.isOpen" class="mt-2 text-gray-600">
                {{ faq.answer }}
              </div>
            </div>
          </div>
        </div>

        <!-- Media & Sharing -->
        <div class="bg-white rounded-lg shadow-lg p-6">
          <h2 class="text-xl font-bold text-gray-900 mb-4">Media & Sharing</h2>
          <div class="space-y-4">
            <div v-for="(faq, index) in filteredFAQs.media" :key="index" class="border-b border-gray-200 pb-4">
              <button
                @click="toggleFAQ('media', index)"
                class="flex justify-between items-center w-full text-left"
              >
                <span class="text-lg font-medium text-gray-900">{{ faq.question }}</span>
                <svg
                  class="h-5 w-5 text-gray-500 transform transition-transform"
                  :class="{ 'rotate-180': faq.isOpen }"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                </svg>
              </button>
              <div v-show="faq.isOpen" class="mt-2 text-gray-600">
                {{ faq.answer }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Contact Support -->
      <div class="mt-12 text-center">
        <p class="text-gray-600 mb-4">Can't find what you're looking for?</p>
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

const searchQuery = ref('')

const faqs = {
  gettingStarted: [
    {
      question: 'How do I create my first family tree?',
      answer: 'To create your first family tree, sign up for an account and click the "Create New Tree" button on your dashboard. Start by adding yourself as the first person, then add your immediate family members. You can expand the tree by adding more relatives and their relationships.',
      isOpen: false
    },
    {
      question: 'Can I invite family members to collaborate?',
      answer: 'Yes! You can invite family members to collaborate on your tree. Go to the tree settings, click "Invite Members," and enter their email addresses. They\'ll receive an invitation to join and contribute to the family tree.',
      isOpen: false
    },
    {
      question: 'Is there a limit to how many people I can add?',
      answer: 'The free plan allows you to add up to 100 people to your family tree. Premium plans offer unlimited additions and additional features like advanced privacy controls and media storage.',
      isOpen: false
    }
  ],
  treeManagement: [
    {
      question: 'How do I edit someone\'s information?',
      answer: 'To edit someone\'s information, navigate to their profile page and click the "Edit" button. You can update their personal details, relationships, and add or modify media attachments.',
      isOpen: false
    },
    {
      question: 'Can I merge duplicate profiles?',
      answer: 'Yes, you can merge duplicate profiles. Go to the person\'s profile, click "More Options," and select "Merge with Another Profile." You\'ll be able to select the profile to merge with and choose which information to keep.',
      isOpen: false
    },
    {
      question: 'How do I handle privacy for living relatives?',
      answer: 'You can set privacy levels for each person in your tree. For living relatives, you can restrict their information to only be visible to specific family members or keep it private until you\'re ready to share.',
      isOpen: false
    }
  ],
  privacy: [
    {
      question: 'How is my family\'s data protected?',
      answer: 'We take data protection seriously. All data is encrypted in transit and at rest. We never share your family\'s information with third parties, and you have complete control over who can view and edit your family tree.',
      isOpen: false
    },
    {
      question: 'Can I export my family tree data?',
      answer: 'Yes, you can export your family tree data at any time. Go to the tree settings and select "Export Tree." You can choose to export in various formats, including GEDCOM, PDF, or CSV.',
      isOpen: false
    },
    {
      question: 'What happens to my data if I delete my account?',
      answer: 'When you delete your account, all your personal data and family tree information will be permanently deleted after 30 days. You\'ll receive an email confirmation when the deletion is complete.',
      isOpen: false
    }
  ],
  media: [
    {
      question: 'What types of media can I upload?',
      answer: 'You can upload photos, documents, audio recordings, and videos. Supported formats include JPG, PNG, PDF, MP3, MP4, and more. Each media item can be attached to specific people and events in your tree.',
      isOpen: false
    },
    {
      question: 'Is there a limit to how much media I can upload?',
      answer: 'Free accounts can upload up to 1GB of media. Premium plans offer more storage space, starting from 10GB up to unlimited storage depending on your plan.',
      isOpen: false
    },
    {
      question: 'How do I organize my media?',
      answer: 'You can organize media by creating albums, adding tags, and attaching them to specific people or events. Use the media gallery to browse, search, and manage all your uploaded content.',
      isOpen: false
    }
  ]
}

const filteredFAQs = computed(() => {
  const query = searchQuery.value.toLowerCase()
  if (!query) return faqs

  const filterCategory = (category) => {
    return category.filter(faq => 
      faq.question.toLowerCase().includes(query) || 
      faq.answer.toLowerCase().includes(query)
    )
  }

  return {
    gettingStarted: filterCategory(faqs.gettingStarted),
    treeManagement: filterCategory(faqs.treeManagement),
    privacy: filterCategory(faqs.privacy),
    media: filterCategory(faqs.media)
  }
})

const toggleFAQ = (category, index) => {
  faqs[category][index].isOpen = !faqs[category][index].isOpen
}
</script> 