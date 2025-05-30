<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          Contact Support
        </h1>
        <p class="mt-4 text-lg text-gray-500">
          We're here to help. Send us a message and we'll get back to you as soon as possible.
        </p>
      </div>

      <!-- Contact Form -->
      <div class="bg-white rounded-lg shadow-lg p-6">
        <form @submit.prevent="handleSubmit" class="space-y-6">
          <!-- Subject -->
          <div>
            <label for="subject" class="block text-sm font-medium text-gray-700">
              Subject
            </label>
            <select
              id="subject"
              v-model="form.subject"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              required
            >
              <option value="">Select a subject</option>
              <option value="technical">Technical Issue</option>
              <option value="account">Account Problem</option>
              <option value="billing">Billing Question</option>
              <option value="feature">Feature Request</option>
              <option value="other">Other</option>
            </select>
          </div>

          <!-- Description -->
          <div>
            <label for="description" class="block text-sm font-medium text-gray-700">
              Description
            </label>
            <div class="mt-1">
              <textarea
                id="description"
                v-model="form.description"
                rows="4"
                class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                placeholder="Please describe your issue or question in detail..."
                required
              ></textarea>
            </div>
          </div>

          <!-- Priority -->
          <div>
            <label class="block text-sm font-medium text-gray-700">
              Priority
            </label>
            <div class="mt-2 space-y-4">
              <div class="flex items-center">
                <input
                  id="priority-low"
                  v-model="form.priority"
                  type="radio"
                  value="low"
                  class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                />
                <label for="priority-low" class="ml-3 block text-sm font-medium text-gray-700">
                  Low - General question or feedback
                </label>
              </div>
              <div class="flex items-center">
                <input
                  id="priority-medium"
                  v-model="form.priority"
                  type="radio"
                  value="medium"
                  class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                />
                <label for="priority-medium" class="ml-3 block text-sm font-medium text-gray-700">
                  Medium - Feature request or minor issue
                </label>
              </div>
              <div class="flex items-center">
                <input
                  id="priority-high"
                  v-model="form.priority"
                  type="radio"
                  value="high"
                  class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                />
                <label for="priority-high" class="ml-3 block text-sm font-medium text-gray-700">
                  High - Critical issue affecting usage
                </label>
              </div>
            </div>
          </div>

          <!-- Attachments -->
          <div>
            <label class="block text-sm font-medium text-gray-700">
              Attachments (optional)
            </label>
            <div class="mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-gray-300 border-dashed rounded-md">
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
                      @change="handleFileUpload"
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
              <h4 class="text-sm font-medium text-gray-700">Selected files:</h4>
              <ul class="mt-2 divide-y divide-gray-200">
                <li
                  v-for="(file, index) in form.files"
                  :key="index"
                  class="py-2 flex items-center justify-between"
                >
                  <div class="flex items-center">
                    <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                    </svg>
                    <span class="ml-2 text-sm text-gray-500">{{ file.name }}</span>
                  </div>
                  <button
                    type="button"
                    @click="removeFile(index)"
                    class="text-red-600 hover:text-red-800"
                  >
                    Remove
                  </button>
                </li>
              </ul>
            </div>
          </div>

          <!-- Contact Method -->
          <div>
            <label class="block text-sm font-medium text-gray-700">
              Preferred Contact Method
            </label>
            <div class="mt-2 space-y-4">
              <div class="flex items-center">
                <input
                  id="contact-email"
                  v-model="form.contactMethod"
                  type="radio"
                  value="email"
                  class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                />
                <label for="contact-email" class="ml-3 block text-sm font-medium text-gray-700">
                  Email
                </label>
              </div>
              <div class="flex items-center">
                <input
                  id="contact-phone"
                  v-model="form.contactMethod"
                  type="radio"
                  value="phone"
                  class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                />
                <label for="contact-phone" class="ml-3 block text-sm font-medium text-gray-700">
                  Phone
                </label>
              </div>
            </div>
          </div>

          <!-- Contact Details -->
          <div v-if="form.contactMethod === 'phone'">
            <label for="phone" class="block text-sm font-medium text-gray-700">
              Phone Number
            </label>
            <input
              type="tel"
              id="phone"
              v-model="form.phone"
              class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
              placeholder="+1 (555) 000-0000"
            />
          </div>

          <!-- Submit Button -->
          <div class="flex justify-end">
            <button
              type="submit"
              :disabled="isSubmitting"
              class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
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
                ></circle>
                <path
                  class="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                ></path>
              </svg>
              {{ isSubmitting ? 'Sending...' : 'Send Message' }}
            </button>
          </div>
        </form>
      </div>

      <!-- Alternative Contact Methods -->
      <div class="mt-12 text-center">
        <h2 class="text-lg font-medium text-gray-900">Other Ways to Reach Us</h2>
        <div class="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2">
          <div class="bg-white rounded-lg shadow-sm p-6">
            <svg class="h-6 w-6 text-indigo-600 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            </svg>
            <h3 class="mt-4 text-sm font-medium text-gray-900">Email</h3>
            <p class="mt-2 text-sm text-gray-500">
              support@familytree.com
            </p>
          </div>
          <div class="bg-white rounded-lg shadow-sm p-6">
            <svg class="h-6 w-6 text-indigo-600 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z" />
            </svg>
            <h3 class="mt-4 text-sm font-medium text-gray-900">Live Chat</h3>
            <p class="mt-2 text-sm text-gray-500">
              Available 24/7
            </p>
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
const isSubmitting = ref(false)

const form = ref({
  subject: '',
  description: '',
  priority: 'medium',
  files: [],
  contactMethod: 'email',
  phone: ''
})

const handleFileUpload = (event) => {
  const files = Array.from(event.target.files)
  const maxSize = 10 * 1024 * 1024 // 10MB
  const allowedTypes = ['image/jpeg', 'image/png', 'application/pdf']

  files.forEach(file => {
    if (file.size > maxSize) {
      toast.error(`File ${file.name} is too large. Maximum size is 10MB.`)
      return
    }
    if (!allowedTypes.includes(file.type)) {
      toast.error(`File ${file.name} has an unsupported type. Please upload PNG, JPG, or PDF files.`)
      return
    }
    form.value.files.push(file)
  })
}

const removeFile = (index) => {
  form.value.files.splice(index, 1)
}

const handleSubmit = async () => {
  try {
    isSubmitting.value = true

    // Create FormData object for file upload
    const formData = new FormData()
    formData.append('subject', form.value.subject)
    formData.append('description', form.value.description)
    formData.append('priority', form.value.priority)
    formData.append('contactMethod', form.value.contactMethod)
    if (form.value.contactMethod === 'phone') {
      formData.append('phone', form.value.phone)
    }
    form.value.files.forEach(file => {
      formData.append('files', file)
    })

    // TODO: Replace with actual API call
    await new Promise(resolve => setTimeout(resolve, 1500)) // Simulated API call

    toast.success('Your message has been sent successfully!')
    form.value = {
      subject: '',
      description: '',
      priority: 'medium',
      files: [],
      contactMethod: 'email',
      phone: ''
    }
  } catch (error) {
    toast.error('Failed to send message. Please try again.')
    console.error('Error submitting form:', error)
  } finally {
    isSubmitting.value = false
  }
}
</script> 