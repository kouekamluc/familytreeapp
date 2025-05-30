<template>
  <div class="py-10">
    <header>
      <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <h1 class="text-3xl font-bold leading-tight tracking-tight text-gray-900">Create New Family Tree</h1>
      </div>
    </header>
    <main>
      <div class="mx-auto max-w-7xl sm:px-6 lg:px-8">
        <!-- Progress steps -->
        <nav aria-label="Progress" class="mt-8">
          <ol role="list" class="space-y-4 md:flex md:space-x-8 md:space-y-0">
            <li v-for="(step, index) in steps" :key="step.name" class="md:flex-1">
              <div
                class="group flex flex-col border-l-4 py-2 pl-4 md:border-l-0 md:border-t-4 md:pb-0 md:pl-0 md:pt-4"
                :class="[
                  currentStep > index
                    ? 'border-indigo-600'
                    : currentStep === index
                    ? 'border-indigo-600'
                    : 'border-gray-200'
                ]"
              >
                <span
                  class="text-sm font-medium"
                  :class="[
                    currentStep > index
                      ? 'text-indigo-600'
                      : currentStep === index
                      ? 'text-indigo-600'
                      : 'text-gray-500'
                  ]"
                >
                  Step {{ index + 1 }}
                </span>
                <span class="text-sm font-medium">{{ step.name }}</span>
              </div>
            </li>
          </ol>
        </nav>

        <!-- Form steps -->
        <div class="mt-8">
          <!-- Step 1: Basic Information -->
          <div v-if="currentStep === 0" class="space-y-6">
            <div>
              <label for="tree-name" class="block text-sm font-medium leading-6 text-gray-900">Tree Name</label>
              <div class="mt-2">
                <input
                  id="tree-name"
                  v-model="form.name"
                  type="text"
                  class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                  :class="{ 'ring-red-500': errors.name }"
                />
                <p v-if="errors.name" class="mt-2 text-sm text-red-600">{{ errors.name }}</p>
              </div>
            </div>

            <div>
              <label for="description" class="block text-sm font-medium leading-6 text-gray-900">Description</label>
              <div class="mt-2">
                <textarea
                  id="description"
                  v-model="form.description"
                  rows="3"
                  class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                ></textarea>
              </div>
            </div>

            <div>
              <label for="privacy" class="block text-sm font-medium leading-6 text-gray-900">Privacy Settings</label>
              <div class="mt-2">
                <select
                  id="privacy"
                  v-model="form.privacy"
                  class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                >
                  <option value="private">Private - Only you can view</option>
                  <option value="family">Family - Only family members can view</option>
                  <option value="public">Public - Anyone can view</option>
                </select>
              </div>
            </div>
          </div>

          <!-- Step 2: Starting Person -->
          <div v-if="currentStep === 1" class="space-y-6">
            <div>
              <label for="first-name" class="block text-sm font-medium leading-6 text-gray-900">First Name</label>
              <div class="mt-2">
                <input
                  id="first-name"
                  v-model="form.startingPerson.firstName"
                  type="text"
                  class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                  :class="{ 'ring-red-500': errors.startingPerson?.firstName }"
                />
                <p v-if="errors.startingPerson?.firstName" class="mt-2 text-sm text-red-600">
                  {{ errors.startingPerson.firstName }}
                </p>
              </div>
            </div>

            <div>
              <label for="last-name" class="block text-sm font-medium leading-6 text-gray-900">Last Name</label>
              <div class="mt-2">
                <input
                  id="last-name"
                  v-model="form.startingPerson.lastName"
                  type="text"
                  class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                  :class="{ 'ring-red-500': errors.startingPerson?.lastName }"
                />
                <p v-if="errors.startingPerson?.lastName" class="mt-2 text-sm text-red-600">
                  {{ errors.startingPerson.lastName }}
                </p>
              </div>
            </div>

            <div>
              <label for="gender" class="block text-sm font-medium leading-6 text-gray-900">Gender</label>
              <div class="mt-2">
                <select
                  id="gender"
                  v-model="form.startingPerson.gender"
                  class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                >
                  <option value="male">Male</option>
                  <option value="female">Female</option>
                  <option value="other">Other</option>
                </select>
              </div>
            </div>

            <div>
              <label for="birth-date" class="block text-sm font-medium leading-6 text-gray-900">Birth Date</label>
              <div class="mt-2">
                <input
                  id="birth-date"
                  v-model="form.startingPerson.birthDate"
                  type="date"
                  class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
                />
              </div>
            </div>
          </div>

          <!-- Step 3: Import Options -->
          <div v-if="currentStep === 2" class="space-y-6">
            <div class="rounded-lg bg-gray-50 p-6">
              <h3 class="text-base font-semibold leading-6 text-gray-900">Import Options</h3>
              <div class="mt-4">
                <p class="text-sm text-gray-500">
                  You can import your family tree data from various sources. Choose an option below or skip this step to
                  start with a blank tree.
                </p>
              </div>
              <div class="mt-6 space-y-4">
                <div class="flex items-center">
                  <input
                    id="import-gedcom"
                    v-model="form.importType"
                    name="import-type"
                    type="radio"
                    value="gedcom"
                    class="h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-600"
                  />
                  <label for="import-gedcom" class="ml-3 block text-sm font-medium leading-6 text-gray-900">
                    Import from GEDCOM file
                  </label>
                </div>
                <div class="flex items-center">
                  <input
                    id="import-csv"
                    v-model="form.importType"
                    name="import-type"
                    type="radio"
                    value="csv"
                    class="h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-600"
                  />
                  <label for="import-csv" class="ml-3 block text-sm font-medium leading-6 text-gray-900">
                    Import from CSV file
                  </label>
                </div>
                <div class="flex items-center">
                  <input
                    id="import-none"
                    v-model="form.importType"
                    name="import-type"
                    type="radio"
                    value="none"
                    class="h-4 w-4 border-gray-300 text-indigo-600 focus:ring-indigo-600"
                  />
                  <label for="import-none" class="ml-3 block text-sm font-medium leading-6 text-gray-900">
                    Start with a blank tree
                  </label>
                </div>
              </div>
            </div>

            <div v-if="form.importType !== 'none'" class="mt-6">
              <label class="block text-sm font-medium leading-6 text-gray-900">Upload File</label>
              <div class="mt-2 flex justify-center rounded-lg border border-dashed border-gray-900/25 px-6 py-10">
                <div class="text-center">
                  <svg
                    class="mx-auto h-12 w-12 text-gray-300"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M1.5 6a2.25 2.25 0 012.25-2.25h16.5A2.25 2.25 0 0122.5 6v12a2.25 2.25 0 01-2.25 2.25H3.75A2.25 2.25 0 011.5 18V6zM3 16.06V18c0 .414.336.75.75.75h16.5A.75.75 0 0021 18v-1.94l-2.69-2.689a1.5 1.5 0 00-2.12 0l-.88.879.97.97a.75.75 0 11-1.06 1.06l-5.16-5.159a1.5 1.5 0 00-2.12 0L3 16.061zm10.125-7.81a1.125 1.125 0 112.25 0 1.125 1.125 0 01-2.25 0z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  <div class="mt-4 flex text-sm leading-6 text-gray-600">
                    <label
                      for="file-upload"
                      class="relative cursor-pointer rounded-md bg-white font-semibold text-indigo-600 focus-within:outline-none focus-within:ring-2 focus-within:ring-indigo-600 focus-within:ring-offset-2 hover:text-indigo-500"
                    >
                      <span>Upload a file</span>
                      <input
                        id="file-upload"
                        type="file"
                        class="sr-only"
                        @change="handleFileUpload"
                        :accept="form.importType === 'gedcom' ? '.ged' : '.csv'"
                      />
                    </label>
                    <p class="pl-1">or drag and drop</p>
                  </div>
                  <p class="text-xs leading-5 text-gray-600">
                    {{ form.importType === 'gedcom' ? 'GEDCOM files up to 10MB' : 'CSV files up to 10MB' }}
                  </p>
                </div>
              </div>
            </div>
          </div>

          <!-- Navigation buttons -->
          <div class="mt-8 flex justify-between">
            <button
              v-if="currentStep > 0"
              type="button"
              class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
              @click="previousStep"
            >
              Previous
            </button>
            <div class="ml-auto">
              <button
                v-if="currentStep < steps.length - 1"
                type="button"
                class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                @click="nextStep"
              >
                Next
              </button>
              <button
                v-else
                type="button"
                class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                @click="createTree"
                :disabled="isLoading"
              >
                <span v-if="isLoading">Creating...</span>
                <span v-else>Create Tree</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'

const router = useRouter()
const toast = useToast()

const steps = [
  { name: 'Basic Information' },
  { name: 'Starting Person' },
  { name: 'Import Options' }
]

const currentStep = ref(0)
const isLoading = ref(false)

const form = reactive({
  name: '',
  description: '',
  privacy: 'private',
  startingPerson: {
    firstName: '',
    lastName: '',
    gender: 'male',
    birthDate: ''
  },
  importType: 'none',
  importFile: null
})

const errors = reactive({
  name: '',
  startingPerson: {
    firstName: '',
    lastName: ''
  }
})

const validateStep = () => {
  let isValid = true

  if (currentStep.value === 0) {
    if (!form.name) {
      errors.name = 'Tree name is required'
      isValid = false
    } else {
      errors.name = ''
    }
  }

  if (currentStep.value === 1) {
    if (!form.startingPerson.firstName) {
      errors.startingPerson.firstName = 'First name is required'
      isValid = false
    } else {
      errors.startingPerson.firstName = ''
    }

    if (!form.startingPerson.lastName) {
      errors.startingPerson.lastName = 'Last name is required'
      isValid = false
    } else {
      errors.startingPerson.lastName = ''
    }
  }

  return isValid
}

const nextStep = () => {
  if (validateStep()) {
    currentStep.value++
  }
}

const previousStep = () => {
  currentStep.value--
}

const handleFileUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    form.importFile = file
  }
}

const createTree = async () => {
  if (!validateStep()) return

  isLoading.value = true
  try {
    // TODO: Implement actual API call
    const formData = new FormData()
    formData.append('name', form.name)
    formData.append('description', form.description)
    formData.append('privacy', form.privacy)
    formData.append('startingPerson', JSON.stringify(form.startingPerson))
    
    if (form.importFile) {
      formData.append('importFile', form.importFile)
    }

    const response = await fetch('/api/trees/', {
      method: 'POST',
      body: formData
    })

    if (!response.ok) {
      throw new Error('Failed to create tree')
    }

    const data = await response.json()
    toast.success('Family tree created successfully!')
    router.push(`/trees/${data.id}`)
  } catch (error) {
    toast.error(error.message || 'Failed to create family tree')
  } finally {
    isLoading.value = false
  }
}
</script> 