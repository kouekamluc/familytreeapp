<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          Feedback & Suggestions
        </h1>
        <p class="mt-4 text-lg text-gray-500">
          Help us improve your family tree experience
        </p>
      </div>

      <!-- Feedback Form -->
      <div class="bg-white rounded-lg shadow-lg p-6 mb-8">
        <form @submit.prevent="handleSubmit" class="space-y-6">
          <!-- Feedback Type -->
          <div>
            <label class="block text-sm font-medium text-gray-700">
              What type of feedback do you have?
            </label>
            <div class="mt-2 grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div
                v-for="type in feedbackTypes"
                :key="type.id"
                class="relative flex items-center"
              >
                <input
                  :id="type.id"
                  v-model="form.type"
                  :value="type.id"
                  type="radio"
                  class="h-4 w-4 text-indigo-600 focus:ring-indigo-500"
                />
                <label
                  :for="type.id"
                  class="ml-3 block text-sm font-medium text-gray-700"
                >
                  {{ type.label }}
                </label>
              </div>
            </div>
          </div>

          <!-- Subject -->
          <div>
            <label
              for="subject"
              class="block text-sm font-medium text-gray-700"
            >
              Subject
            </label>
            <input
              id="subject"
              v-model="form.subject"
              type="text"
              required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              placeholder="Brief description of your feedback"
            />
          </div>

          <!-- Description -->
          <div>
            <label
              for="description"
              class="block text-sm font-medium text-gray-700"
            >
              Description
            </label>
            <textarea
              id="description"
              v-model="form.description"
              rows="4"
              required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              placeholder="Please provide detailed feedback..."
            />
          </div>

          <!-- Priority -->
          <div>
            <label class="block text-sm font-medium text-gray-700">
              Priority
            </label>
            <select
              v-model="form.priority"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            >
              <option value="low">Low - General feedback</option>
              <option value="medium">Medium - Feature request</option>
              <option value="high">High - Bug or issue affecting usage</option>
            </select>
          </div>

          <!-- Attachments -->
          <div>
            <label class="block text-sm font-medium text-gray-700">
              Attachments (optional)
            </label>
            <div
              class="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md"
              :class="{ 'border-indigo-500': isDragging }"
              @dragover.prevent="isDragging = true"
              @dragleave.prevent="isDragging = false"
              @drop.prevent="handleFileDrop"
            >
              <div class="space-y-1 text-center">
                <svg
                  class="mx-auto h-12 w-12 text-gray-400"
                  stroke="currentColor"
                  fill="none"
                  viewBox="0 0 48 48"
                  aria-hidden="true"
                >
                  <path
                    d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02"
                    stroke-width="2"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                  />
                </svg>
                <div class="flex text-sm text-gray-600">
                  <label
                    for="file-upload"
                    class="relative cursor-pointer bg-white rounded-md font-medium text-indigo-600 hover:text-indigo-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-indigo-500"
                  >
                    <span>Upload files</span>
                    <input
                      id="file-upload"
                      type="file"
                      multiple
                      class="sr-only"
                      @change="handleFileSelect"
                    />
                  </label>
                  <p class="pl-1">or drag and drop</p>
                </div>
                <p class="text-xs text-gray-500">
                  PNG, JPG, PDF up to 10MB
                </p>
              </div>
            </div>
            <!-- File List -->
            <div v-if="form.files.length > 0" class="mt-4">
              <ul class="divide-y divide-gray-200">
                <li
                  v-for="(file, index) in form.files"
                  :key="index"
                  class="py-3 flex items-center justify-between"
                >
                  <div class="flex items-center">
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
                        d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"
                      />
                    </svg>
                    <span class="ml-2 text-sm text-gray-500">
                      {{ file.name }}
                    </span>
                  </div>
                  <button
                    type="button"
                    class="text-red-600 hover:text-red-800"
                    @click="removeFile(index)"
                  >
                    Remove
                  </button>
                </li>
              </ul>
            </div>
          </div>

          <!-- Contact Information -->
          <div>
            <label class="block text-sm font-medium text-gray-700">
              Would you like us to contact you about this feedback?
            </label>
            <div class="mt-2">
              <div class="flex items-center">
                <input
                  id="contact-yes"
                  v-model="form.allowContact"
                  type="radio"
                  :value="true"
                  class="h-4 w-4 text-indigo-600 focus:ring-indigo-500"
                />
                <label
                  for="contact-yes"
                  class="ml-3 block text-sm font-medium text-gray-700"
                >
                  Yes, please contact me
                </label>
              </div>
              <div class="flex items-center mt-2">
                <input
                  id="contact-no"
                  v-model="form.allowContact"
                  type="radio"
                  :value="false"
                  class="h-4 w-4 text-indigo-600 focus:ring-indigo-500"
                />
                <label
                  for="contact-no"
                  class="ml-3 block text-sm font-medium text-gray-700"
                >
                  No, this is anonymous feedback
                </label>
              </div>
            </div>
          </div>

          <!-- Email (if contact is allowed) -->
          <div v-if="form.allowContact">
            <label
              for="email"
              class="block text-sm font-medium text-gray-700"
            >
              Email Address
            </label>
            <input
              id="email"
              v-model="form.email"
              type="email"
              required
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
              placeholder="your@email.com"
            />
          </div>

          <!-- Submit Button -->
          <div class="flex justify-end">
            <button
              type="submit"
              :disabled="isSubmitting"
              class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
            >
              <svg
                v-if="isSubmitting"
                class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle
                  class="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  stroke-width="4"
                />
                <path
                  class="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                />
              </svg>
              {{ isSubmitting ? 'Submitting...' : 'Submit Feedback' }}
            </button>
          </div>
        </form>
      </div>

      <!-- Recent Updates -->
      <div class="bg-white rounded-lg shadow-lg p-6">
        <h2 class="text-xl font-bold text-gray-900 mb-4">Recent Updates</h2>
        <div class="space-y-4">
          <div
            v-for="update in recentUpdates"
            :key="update.id"
            class="border-l-4 border-indigo-500 pl-4"
          >
            <div class="flex items-center">
              <span class="text-sm font-medium text-indigo-600">
                {{ update.date }}
              </span>
              <span class="ml-2 text-sm text-gray-500">
                {{ update.status }}
              </span>
            </div>
            <p class="mt-1 text-sm text-gray-900">{{ update.description }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useToast } from 'vue-toastification'

const toast = useToast()
const isDragging = ref(false)
const isSubmitting = ref(false)

const feedbackTypes = [
  { id: 'bug', label: 'Bug Report' },
  { id: 'feature', label: 'Feature Request' },
  { id: 'improvement', label: 'Improvement Suggestion' },
  { id: 'other', label: 'Other' }
]

const form = ref({
  type: 'improvement',
  subject: '',
  description: '',
  priority: 'medium',
  files: [],
  allowContact: false,
  email: ''
})

const recentUpdates = [
  {
    id: 1,
    date: 'March 15, 2024',
    status: 'Implemented',
    description: 'Added support for DNA test results import'
  },
  {
    id: 2,
    date: 'March 10, 2024',
    status: 'In Progress',
    description: 'Improving media upload performance'
  },
  {
    id: 3,
    date: 'March 5, 2024',
    status: 'Planned',
    description: 'New timeline visualization feature'
  }
]

const handleFileSelect = (event) => {
  const files = Array.from(event.target.files)
  validateAndAddFiles(files)
}

const handleFileDrop = (event) => {
  isDragging.value = false
  const files = Array.from(event.dataTransfer.files)
  validateAndAddFiles(files)
}

const validateAndAddFiles = (files) => {
  const maxSize = 10 * 1024 * 1024 // 10MB
  const allowedTypes = ['image/png', 'image/jpeg', 'application/pdf']

  files.forEach(file => {
    if (file.size > maxSize) {
      toast.error(`File ${file.name} is too large. Maximum size is 10MB.`)
      return
    }

    if (!allowedTypes.includes(file.type)) {
      toast.error(`File ${file.name} is not a supported type. Please upload PNG, JPG, or PDF files.`)
      return
    }

    form.value.files.push(file)
  })
}

const removeFile = (index) => {
  form.value.files.splice(index, 1)
}

const handleSubmit = async () => {
  isSubmitting.value = true

  try {
    // Create FormData object
    const formData = new FormData()
    formData.append('type', form.value.type)
    formData.append('subject', form.value.subject)
    formData.append('description', form.value.description)
    formData.append('priority', form.value.priority)
    formData.append('allowContact', form.value.allowContact)
    
    if (form.value.allowContact) {
      formData.append('email', form.value.email)
    }

    form.value.files.forEach(file => {
      formData.append('files', file)
    })

    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1500))

    // Show success message
    toast.success('Thank you for your feedback! We appreciate your input.')
    
    // Reset form
    form.value = {
      type: 'improvement',
      subject: '',
      description: '',
      priority: 'medium',
      files: [],
      allowContact: false,
      email: ''
    }
  } catch (error) {
    toast.error('There was an error submitting your feedback. Please try again.')
  } finally {
    isSubmitting.value = false
  }
}
</script> 