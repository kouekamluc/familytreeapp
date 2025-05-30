<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="mb-8">
        <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
          Upload Media
        </h2>
        <p class="mt-1 text-sm text-gray-500">
          Add photos, videos, or documents to your family tree
        </p>
      </div>

      <div class="bg-white rounded-lg shadow-lg overflow-hidden">
        <div class="p-6">
          <!-- Upload Area -->
          <div
            class="border-2 border-dashed border-gray-300 rounded-lg p-12 text-center"
            :class="{ 'border-indigo-500 bg-indigo-50': isDragging }"
            @dragenter.prevent="isDragging = true"
            @dragleave.prevent="isDragging = false"
            @dragover.prevent
            @drop.prevent="handleDrop"
          >
            <svg
              class="mx-auto h-12 w-12 text-gray-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
              />
            </svg>
            <div class="mt-4">
              <button
                type="button"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                @click="triggerFileInput"
              >
                Select Files
              </button>
              <input
                ref="fileInput"
                type="file"
                multiple
                class="hidden"
                @change="handleFileSelect"
              />
            </div>
            <p class="mt-2 text-sm text-gray-500">
              or drag and drop files here
            </p>
            <p class="mt-1 text-xs text-gray-500">
              Supported formats: JPG, PNG, GIF, MP4, PDF (max 50MB)
            </p>
          </div>

          <!-- Upload Progress -->
          <div v-if="uploadingFiles.length > 0" class="mt-8">
            <h3 class="text-lg font-medium text-gray-900 mb-4">Upload Progress</h3>
            <div class="space-y-4">
              <div
                v-for="file in uploadingFiles"
                :key="file.id"
                class="flex items-center justify-between"
              >
                <div class="flex items-center space-x-3">
                  <div class="flex-shrink-0">
                    <img
                      v-if="file.type.startsWith('image/')"
                      :src="file.preview"
                      class="h-10 w-10 rounded object-cover"
                    />
                    <div
                      v-else
                      class="h-10 w-10 rounded bg-gray-100 flex items-center justify-center"
                    >
                      <svg class="h-6 w-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                      </svg>
                    </div>
                  </div>
                  <div>
                    <p class="text-sm font-medium text-gray-900">{{ file.name }}</p>
                    <p class="text-xs text-gray-500">{{ formatFileSize(file.size) }}</p>
                  </div>
                </div>
                <div class="flex items-center space-x-4">
                  <div class="w-32">
                    <div class="bg-gray-200 rounded-full h-2">
                      <div
                        class="bg-indigo-600 rounded-full h-2"
                        :style="{ width: `${file.progress}%` }"
                      ></div>
                    </div>
                  </div>
                  <button
                    v-if="file.progress < 100"
                    class="text-red-600 hover:text-red-900"
                    @click="cancelUpload(file.id)"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Metadata Form -->
          <div v-if="selectedFiles.length > 0" class="mt-8">
            <h3 class="text-lg font-medium text-gray-900 mb-4">Media Details</h3>
            <form @submit.prevent="handleSubmit" class="space-y-6">
              <div>
                <label class="block text-sm font-medium text-gray-700">Title</label>
                <input
                  v-model="metadata.title"
                  type="text"
                  class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  required
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700">Description</label>
                <textarea
                  v-model="metadata.description"
                  rows="3"
                  class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                ></textarea>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700">Date</label>
                <input
                  v-model="metadata.date"
                  type="date"
                  class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700">Location</label>
                <input
                  v-model="metadata.location"
                  type="text"
                  class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700">Related People</label>
                <div class="mt-2 space-y-2">
                  <div
                    v-for="person in metadata.relatedPeople"
                    :key="person.id"
                    class="flex items-center justify-between p-2 bg-gray-50 rounded-md"
                  >
                    <div class="flex items-center space-x-3">
                      <img
                        :src="person.avatar"
                        :alt="person.name"
                        class="h-8 w-8 rounded-full"
                      />
                      <span class="text-sm text-gray-900">{{ person.name }}</span>
                    </div>
                    <button
                      type="button"
                      class="text-red-600 hover:text-red-900"
                      @click="removePerson(person.id)"
                    >
                      Remove
                    </button>
                  </div>
                  <button
                    type="button"
                    class="inline-flex items-center px-3 py-1.5 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    @click="showPersonSelector = true"
                  >
                    Add Person
                  </button>
                </div>
              </div>

              <div class="flex justify-end space-x-3">
                <button
                  type="button"
                  class="px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  @click="resetForm"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  :disabled="isUploading"
                >
                  Upload
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const fileInput = ref(null)
const isDragging = ref(false)
const selectedFiles = ref([])
const uploadingFiles = ref([])
const showPersonSelector = ref(false)

const metadata = ref({
  title: '',
  description: '',
  date: '',
  location: '',
  relatedPeople: []
})

const isUploading = computed(() => {
  return uploadingFiles.value.some(file => file.progress < 100)
})

const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

const triggerFileInput = () => {
  fileInput.value.click()
}

const handleFileSelect = (event) => {
  const files = Array.from(event.target.files)
  processFiles(files)
}

const handleDrop = (event) => {
  isDragging.value = false
  const files = Array.from(event.dataTransfer.files)
  processFiles(files)
}

const processFiles = (files) => {
  files.forEach(file => {
    if (file.size > 50 * 1024 * 1024) {
      alert(`File ${file.name} is too large. Maximum size is 50MB.`)
      return
    }

    const fileObj = {
      id: Date.now() + Math.random(),
      name: file.name,
      size: file.size,
      type: file.type,
      file: file,
      progress: 0
    }

    if (file.type.startsWith('image/')) {
      const reader = new FileReader()
      reader.onload = (e) => {
        fileObj.preview = e.target.result
      }
      reader.readAsDataURL(file)
    }

    selectedFiles.value.push(fileObj)
  })
}

const cancelUpload = (fileId) => {
  const index = uploadingFiles.value.findIndex(f => f.id === fileId)
  if (index !== -1) {
    uploadingFiles.value.splice(index, 1)
  }
}

const removePerson = (personId) => {
  metadata.value.relatedPeople = metadata.value.relatedPeople.filter(p => p.id !== personId)
}

const resetForm = () => {
  selectedFiles.value = []
  uploadingFiles.value = []
  metadata.value = {
    title: '',
    description: '',
    date: '',
    location: '',
    relatedPeople: []
  }
}

const handleSubmit = async () => {
  uploadingFiles.value = [...selectedFiles.value]
  
  // Simulate upload progress
  for (const file of uploadingFiles.value) {
    for (let progress = 0; progress <= 100; progress += 10) {
      file.progress = progress
      await new Promise(resolve => setTimeout(resolve, 200))
    }
  }

  // TODO: Implement actual file upload logic
  console.log('Uploading files:', uploadingFiles.value)
  console.log('Metadata:', metadata.value)

  // Redirect to media gallery after successful upload
  router.push('/media')
}
</script> 