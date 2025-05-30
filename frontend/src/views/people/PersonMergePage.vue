<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="md:flex md:items-center md:justify-between">
        <div class="flex-1 min-w-0">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            Merge People
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            Combine duplicate person records while preserving all information
          </p>
        </div>
      </div>

      <!-- Person Selection -->
      <div class="mt-8 bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            Select People to Merge
          </h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            Choose the primary record and the record to be merged
          </p>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
            <!-- Primary Person -->
            <div>
              <label class="block text-sm font-medium text-gray-700">
                Primary Person
              </label>
              <div class="mt-1">
                <select
                  v-model="primaryPerson"
                  class="block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                >
                  <option v-for="person in people" :key="person.id" :value="person">
                    {{ person.name }} ({{ person.birthDate }})
                  </option>
                </select>
              </div>
            </div>

            <!-- Person to Merge -->
            <div>
              <label class="block text-sm font-medium text-gray-700">
                Person to Merge
              </label>
              <div class="mt-1">
                <select
                  v-model="personToMerge"
                  class="block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                >
                  <option v-for="person in people" :key="person.id" :value="person">
                    {{ person.name }} ({{ person.birthDate }})
                  </option>
                </select>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Comparison -->
      <div v-if="primaryPerson && personToMerge" class="mt-8 bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            Compare Information
          </h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            Review and select which information to keep
          </p>
        </div>
        <div class="border-t border-gray-200">
          <dl>
            <!-- Basic Information -->
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Basic Information</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                <div class="space-y-4">
                  <!-- Name -->
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <input
                        type="radio"
                        v-model="selectedFields.name"
                        :value="primaryPerson.name"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <span class="ml-2 text-sm text-gray-900">{{ primaryPerson.name }}</span>
                    </div>
                    <div class="flex items-center">
                      <input
                        type="radio"
                        v-model="selectedFields.name"
                        :value="personToMerge.name"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <span class="ml-2 text-sm text-gray-900">{{ personToMerge.name }}</span>
                    </div>
                  </div>

                  <!-- Birth Date -->
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <input
                        type="radio"
                        v-model="selectedFields.birthDate"
                        :value="primaryPerson.birthDate"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <span class="ml-2 text-sm text-gray-900">{{ primaryPerson.birthDate }}</span>
                    </div>
                    <div class="flex items-center">
                      <input
                        type="radio"
                        v-model="selectedFields.birthDate"
                        :value="personToMerge.birthDate"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <span class="ml-2 text-sm text-gray-900">{{ personToMerge.birthDate }}</span>
                    </div>
                  </div>

                  <!-- Birth Place -->
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <input
                        type="radio"
                        v-model="selectedFields.birthPlace"
                        :value="primaryPerson.birthPlace"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <span class="ml-2 text-sm text-gray-900">{{ primaryPerson.birthPlace }}</span>
                    </div>
                    <div class="flex items-center">
                      <input
                        type="radio"
                        v-model="selectedFields.birthPlace"
                        :value="personToMerge.birthPlace"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <span class="ml-2 text-sm text-gray-900">{{ personToMerge.birthPlace }}</span>
                    </div>
                  </div>
                </div>
              </dd>
            </div>

            <!-- Contact Information -->
            <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Contact Information</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                <div class="space-y-4">
                  <!-- Email -->
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <input
                        type="radio"
                        v-model="selectedFields.email"
                        :value="primaryPerson.email"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <span class="ml-2 text-sm text-gray-900">{{ primaryPerson.email }}</span>
                    </div>
                    <div class="flex items-center">
                      <input
                        type="radio"
                        v-model="selectedFields.email"
                        :value="personToMerge.email"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <span class="ml-2 text-sm text-gray-900">{{ personToMerge.email }}</span>
                    </div>
                  </div>

                  <!-- Phone -->
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <input
                        type="radio"
                        v-model="selectedFields.phone"
                        :value="primaryPerson.phone"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <span class="ml-2 text-sm text-gray-900">{{ primaryPerson.phone }}</span>
                    </div>
                    <div class="flex items-center">
                      <input
                        type="radio"
                        v-model="selectedFields.phone"
                        :value="personToMerge.phone"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <span class="ml-2 text-sm text-gray-900">{{ personToMerge.phone }}</span>
                    </div>
                  </div>
                </div>
              </dd>
            </div>

            <!-- Additional Information -->
            <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
              <dt class="text-sm font-medium text-gray-500">Additional Information</dt>
              <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                <div class="space-y-4">
                  <!-- Notes -->
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <input
                        type="radio"
                        v-model="selectedFields.notes"
                        :value="primaryPerson.notes"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <span class="ml-2 text-sm text-gray-900">{{ primaryPerson.notes }}</span>
                    </div>
                    <div class="flex items-center">
                      <input
                        type="radio"
                        v-model="selectedFields.notes"
                        :value="personToMerge.notes"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <span class="ml-2 text-sm text-gray-900">{{ personToMerge.notes }}</span>
                    </div>
                  </div>

                  <!-- Photos -->
                  <div class="flex items-center justify-between">
                    <div class="flex items-center">
                      <input
                        type="checkbox"
                        v-model="selectedFields.keepPrimaryPhotos"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                      />
                      <span class="ml-2 text-sm text-gray-900">Keep primary person's photos</span>
                    </div>
                    <div class="flex items-center">
                      <input
                        type="checkbox"
                        v-model="selectedFields.keepMergePhotos"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                      />
                      <span class="ml-2 text-sm text-gray-900">Keep merge person's photos</span>
                    </div>
                  </div>
                </div>
              </dd>
            </div>
          </dl>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="mt-8 flex justify-end space-x-4">
        <button
          type="button"
          @click="cancel"
          class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Cancel
        </button>
        <button
          type="button"
          @click="mergePeople"
          :disabled="!canMerge"
          class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Merge People
        </button>
      </div>

      <!-- Confirmation Modal -->
      <div
        v-if="showConfirmationModal"
        class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center"
      >
        <div class="bg-white rounded-lg max-w-md w-full mx-4 p-6">
          <h3 class="text-lg font-medium text-red-600 mb-4">
            Confirm Merge
          </h3>
          <p class="text-sm text-gray-500 mb-4">
            Are you sure you want to merge these people? This action cannot be undone.
          </p>
          <div class="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense">
            <button
              type="button"
              @click="confirmMerge"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:col-start-2 sm:text-sm"
            >
              Merge
            </button>
            <button
              type="button"
              @click="showConfirmationModal = false"
              class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:col-start-1 sm:text-sm"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'

const router = useRouter()
const toast = useToast()

const primaryPerson = ref(null)
const personToMerge = ref(null)
const showConfirmationModal = ref(false)

const selectedFields = ref({
  name: '',
  birthDate: '',
  birthPlace: '',
  email: '',
  phone: '',
  notes: '',
  keepPrimaryPhotos: true,
  keepMergePhotos: true
})

// Sample data - replace with actual data from your store/API
const people = ref([
  {
    id: 1,
    name: 'John Smith',
    birthDate: '1950-01-15',
    birthPlace: 'New York, USA',
    email: 'john@example.com',
    phone: '+1 234 567 8900',
    notes: 'Lived in New York for 30 years',
    photos: ['/photos/john1.jpg', '/photos/john2.jpg']
  },
  {
    id: 2,
    name: 'John A. Smith',
    birthDate: '1950-01-15',
    birthPlace: 'NYC, USA',
    email: 'john.smith@example.com',
    phone: '+1 234 567 8901',
    notes: 'Retired in 2015',
    photos: ['/photos/john3.jpg']
  }
])

const canMerge = computed(() => {
  return primaryPerson.value && 
         personToMerge.value && 
         primaryPerson.value.id !== personToMerge.value.id
})

const cancel = () => {
  router.back()
}

const mergePeople = () => {
  showConfirmationModal.value = true
}

const confirmMerge = async () => {
  try {
    // TODO: Implement API call to merge people
    const mergedData = {
      primaryId: primaryPerson.value.id,
      mergeId: personToMerge.value.id,
      selectedFields: selectedFields.value
    }
    
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    showConfirmationModal.value = false
    toast.success('People merged successfully')
    router.push('/people')
  } catch (error) {
    toast.error('Failed to merge people')
    console.error('Error merging people:', error)
  }
}
</script> 