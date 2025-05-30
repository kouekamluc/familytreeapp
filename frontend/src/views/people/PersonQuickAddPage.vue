<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="md:flex md:items-center md:justify-between">
        <div class="flex-1 min-w-0">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            Quick Add Person
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            Add a new family member with essential information
          </p>
        </div>
      </div>

      <div class="mt-8 bg-white shadow overflow-hidden sm:rounded-lg">
        <form @submit.prevent="savePerson" class="space-y-6 divide-y divide-gray-200">
          <!-- Basic Information -->
          <div class="px-4 py-5 sm:p-6">
            <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
              <!-- First Name -->
              <div class="sm:col-span-3">
                <label for="firstName" class="block text-sm font-medium text-gray-700">
                  First Name
                </label>
                <div class="mt-1">
                  <input
                    type="text"
                    id="firstName"
                    v-model="person.firstName"
                    required
                    class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>

              <!-- Last Name -->
              <div class="sm:col-span-3">
                <label for="lastName" class="block text-sm font-medium text-gray-700">
                  Last Name
                </label>
                <div class="mt-1">
                  <input
                    type="text"
                    id="lastName"
                    v-model="person.lastName"
                    required
                    class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>

              <!-- Gender -->
              <div class="sm:col-span-2">
                <label for="gender" class="block text-sm font-medium text-gray-700">
                  Gender
                </label>
                <div class="mt-1">
                  <select
                    id="gender"
                    v-model="person.gender"
                    class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  >
                    <option value="">Select...</option>
                    <option value="male">Male</option>
                    <option value="female">Female</option>
                    <option value="other">Other</option>
                  </select>
                </div>
              </div>

              <!-- Birth Date -->
              <div class="sm:col-span-2">
                <label for="birthDate" class="block text-sm font-medium text-gray-700">
                  Birth Date
                </label>
                <div class="mt-1">
                  <input
                    type="date"
                    id="birthDate"
                    v-model="person.birthDate"
                    class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>

              <!-- Birth Place -->
              <div class="sm:col-span-2">
                <label for="birthPlace" class="block text-sm font-medium text-gray-700">
                  Birth Place
                </label>
                <div class="mt-1">
                  <input
                    type="text"
                    id="birthPlace"
                    v-model="person.birthPlace"
                    class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  />
                </div>
              </div>
            </div>
          </div>

          <!-- Relationships -->
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
              Relationships
            </h3>
            <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
              <!-- Father -->
              <div class="sm:col-span-3">
                <label for="father" class="block text-sm font-medium text-gray-700">
                  Father
                </label>
                <div class="mt-1">
                  <select
                    id="father"
                    v-model="person.fatherId"
                    class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  >
                    <option value="">Select...</option>
                    <option v-for="father in potentialFathers" :key="father.id" :value="father.id">
                      {{ father.name }}
                    </option>
                  </select>
                </div>
              </div>

              <!-- Mother -->
              <div class="sm:col-span-3">
                <label for="mother" class="block text-sm font-medium text-gray-700">
                  Mother
                </label>
                <div class="mt-1">
                  <select
                    id="mother"
                    v-model="person.motherId"
                    class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  >
                    <option value="">Select...</option>
                    <option v-for="mother in potentialMothers" :key="mother.id" :value="mother.id">
                      {{ mother.name }}
                    </option>
                  </select>
                </div>
              </div>

              <!-- Spouse -->
              <div class="sm:col-span-3">
                <label for="spouse" class="block text-sm font-medium text-gray-700">
                  Spouse
                </label>
                <div class="mt-1">
                  <select
                    id="spouse"
                    v-model="person.spouseId"
                    class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  >
                    <option value="">Select...</option>
                    <option v-for="spouse in potentialSpouses" :key="spouse.id" :value="spouse.id">
                      {{ spouse.name }}
                    </option>
                  </select>
                </div>
              </div>

              <!-- Marriage Date -->
              <div class="sm:col-span-3">
                <label for="marriageDate" class="block text-sm font-medium text-gray-700">
                  Marriage Date
                </label>
                <div class="mt-1">
                  <input
                    type="date"
                    id="marriageDate"
                    v-model="person.marriageDate"
                    :disabled="!person.spouseId"
                    class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md disabled:bg-gray-100 disabled:cursor-not-allowed"
                  />
                </div>
              </div>
            </div>
          </div>

          <!-- Additional Information -->
          <div class="px-4 py-5 sm:p-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
              Additional Information
            </h3>
            <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
              <!-- Notes -->
              <div class="sm:col-span-6">
                <label for="notes" class="block text-sm font-medium text-gray-700">
                  Notes
                </label>
                <div class="mt-1">
                  <textarea
                    id="notes"
                    v-model="person.notes"
                    rows="3"
                    class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  ></textarea>
                </div>
              </div>

              <!-- Photo Upload -->
              <div class="sm:col-span-6">
                <label class="block text-sm font-medium text-gray-700">
                  Photo
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
                        for="photo-upload"
                        class="relative cursor-pointer bg-white rounded-md font-medium text-indigo-600 hover:text-indigo-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-indigo-500"
                      >
                        <span>Upload a file</span>
                        <input
                          id="photo-upload"
                          type="file"
                          class="sr-only"
                          accept="image/*"
                          @change="handlePhotoUpload"
                        />
                      </label>
                      <p class="pl-1">or drag and drop</p>
                    </div>
                    <p class="text-xs text-gray-500">
                      PNG, JPG, GIF up to 10MB
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="px-4 py-3 bg-gray-50 text-right sm:px-6">
            <button
              type="button"
              @click="cancel"
              class="inline-flex justify-center py-2 px-4 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="ml-3 inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Save
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'

const router = useRouter()
const toast = useToast()

const person = ref({
  firstName: '',
  lastName: '',
  gender: '',
  birthDate: '',
  birthPlace: '',
  fatherId: '',
  motherId: '',
  spouseId: '',
  marriageDate: '',
  notes: '',
  photo: null
})

// Sample data - replace with actual data from your store/API
const potentialFathers = ref([
  { id: 1, name: 'John Smith' },
  { id: 2, name: 'Michael Johnson' }
])

const potentialMothers = ref([
  { id: 3, name: 'Sarah Smith' },
  { id: 4, name: 'Emily Johnson' }
])

const potentialSpouses = ref([
  { id: 5, name: 'Mary Williams' },
  { id: 6, name: 'Lisa Brown' }
])

const handlePhotoUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    person.value.photo = file
  }
}

const cancel = () => {
  router.back()
}

const savePerson = async () => {
  try {
    // TODO: Implement API call to save person
    const formData = new FormData()
    Object.entries(person.value).forEach(([key, value]) => {
      if (value !== null && value !== '') {
        formData.append(key, value)
      }
    })
    
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    toast.success('Person added successfully')
    router.push('/people')
  } catch (error) {
    toast.error('Failed to add person')
    console.error('Error adding person:', error)
  }
}
</script> 