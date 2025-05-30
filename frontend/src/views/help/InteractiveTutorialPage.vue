<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          Interactive Tutorial
        </h1>
        <p class="mt-4 text-lg text-gray-500">
          Learn how to use Family Tree through our interactive guide
        </p>
      </div>

      <!-- Progress Bar -->
      <div class="mb-8">
        <div class="relative">
          <div class="overflow-hidden h-2 text-xs flex rounded bg-gray-200">
            <div
              :style="{ width: `${(currentStep / totalSteps) * 100}%` }"
              class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-indigo-500 transition-all duration-500"
            ></div>
          </div>
          <div class="text-right mt-2">
            <span class="text-sm text-gray-600">
              Step {{ currentStep }} of {{ totalSteps }}
            </span>
          </div>
        </div>
      </div>

      <!-- Tutorial Content -->
      <div class="bg-white rounded-lg shadow-lg overflow-hidden">
        <div class="p-6">
          <!-- Step Content -->
          <div class="mb-8">
            <h2 class="text-2xl font-bold text-gray-900 mb-4">
              {{ currentStepData.title }}
            </h2>
            <div class="prose max-w-none">
              <p class="text-gray-600 mb-6">
                {{ currentStepData.description }}
              </p>
              <div v-if="currentStepData.image" class="mb-6">
                <img
                  :src="currentStepData.image"
                  :alt="currentStepData.title"
                  class="rounded-lg shadow-md"
                />
              </div>
              <div v-if="currentStepData.code" class="mb-6">
                <pre class="bg-gray-100 p-4 rounded-lg overflow-x-auto">
                  <code>{{ currentStepData.code }}</code>
                </pre>
              </div>
            </div>
          </div>

          <!-- Navigation -->
          <div class="flex justify-between items-center">
            <button
              v-if="currentStep > 1"
              @click="previousStep"
              class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              <svg class="mr-2 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
              </svg>
              Previous
            </button>
            <div v-else class="w-24"></div>

            <div class="flex items-center space-x-4">
              <button
                v-if="currentStep < totalSteps"
                @click="nextStep"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Next
                <svg class="ml-2 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </button>
              <button
                v-else
                @click="completeTutorial"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
              >
                Complete Tutorial
                <svg class="ml-2 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Completion Modal -->
      <div
        v-if="showCompletionModal"
        class="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50"
      >
        <div class="bg-white rounded-lg max-w-md w-full mx-4 p-6">
          <div class="text-center">
            <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-green-100">
              <svg class="h-6 w-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h3 class="mt-4 text-lg font-medium text-gray-900">
              Tutorial Completed!
            </h3>
            <p class="mt-2 text-sm text-gray-500">
              Congratulations on completing the tutorial! You now have a good understanding of how to use Family Tree.
            </p>
            <div class="mt-6">
              <button
                @click="closeCompletionModal"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Continue to Family Tree
              </button>
            </div>
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
const currentStep = ref(1)
const showCompletionModal = ref(false)

const tutorialSteps = [
  {
    title: 'Welcome to Family Tree',
    description: 'Welcome to the Family Tree interactive tutorial! This guide will walk you through the essential features and help you get started with building your family tree.',
    image: '/tutorial/welcome.jpg'
  },
  {
    title: 'Creating Your First Tree',
    description: 'Let\'s start by creating your first family tree. Click the "New Tree" button in the top right corner and give your tree a name. You can always change this later.',
    image: '/tutorial/create-tree.jpg',
    code: 'Click "New Tree" → Enter tree name → Click "Create"'
  },
  {
    title: 'Adding Family Members',
    description: 'Now that you have a tree, let\'s add your first family member. Click the "Add Person" button and fill in their details. You can add as much or as little information as you want.',
    image: '/tutorial/add-person.jpg',
    code: 'Click "Add Person" → Fill in details → Click "Save"'
  },
  {
    title: 'Connecting Family Members',
    description: 'Family members are connected through relationships. To connect two people, click on one person and then click "Add Relationship". Select the type of relationship and the other person.',
    image: '/tutorial/add-relationship.jpg',
    code: 'Select person → Click "Add Relationship" → Choose relationship type → Select other person'
  },
  {
    title: 'Adding Photos and Documents',
    description: 'You can add photos and documents to your family tree. Click on a person\'s profile and then click "Add Media". You can upload photos, documents, or link to existing media.',
    image: '/tutorial/add-media.jpg',
    code: 'Select person → Click "Add Media" → Choose file or link → Click "Upload"'
  },
  {
    title: 'Privacy Settings',
    description: 'Family Tree allows you to control who can see your tree. Click on the tree settings and navigate to the privacy section. Here you can set visibility levels for different parts of your tree.',
    image: '/tutorial/privacy-settings.jpg',
    code: 'Click "Tree Settings" → Go to "Privacy" → Adjust visibility settings'
  },
  {
    title: 'Collaborating with Family',
    description: 'You can invite family members to collaborate on your tree. Click "Share Tree" and enter their email addresses. They\'ll receive an invitation to view and edit the tree.',
    image: '/tutorial/share-tree.jpg',
    code: 'Click "Share Tree" → Enter email addresses → Click "Send Invites"'
  },
  {
    title: 'Search and Discovery',
    description: 'Use the search feature to find people in your tree. You can search by name, date, location, or any other information you\'ve added. The advanced search lets you combine multiple criteria.',
    image: '/tutorial/search.jpg',
    code: 'Click "Search" → Enter search terms → Use filters if needed'
  }
]

const totalSteps = tutorialSteps.length

const currentStepData = computed(() => {
  return tutorialSteps[currentStep.value - 1]
})

const nextStep = () => {
  if (currentStep.value < totalSteps) {
    currentStep.value++
  }
}

const previousStep = () => {
  if (currentStep.value > 1) {
    currentStep.value--
  }
}

const completeTutorial = () => {
  showCompletionModal.value = true
  toast.success('Congratulations on completing the tutorial!')
}

const closeCompletionModal = () => {
  showCompletionModal.value = false
  // Redirect to main tree view or dashboard
  // router.push('/tree')
}
</script> 