<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="bg-white shadow rounded-lg">
        <!-- Header -->
        <div class="px-4 py-5 border-b border-gray-200 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            Add New Person
          </h3>
          <p class="mt-1 text-sm text-gray-500">
            Add a new person to your family tree
          </p>
        </div>

        <!-- Form -->
        <form @submit.prevent="handleSubmit" class="space-y-6 p-6">
          <!-- Basic Information -->
          <div class="space-y-4">
            <h4 class="text-md font-medium text-gray-900">Basic Information</h4>
            
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div>
                <label for="firstName" class="block text-sm font-medium text-gray-700">
                  First Name
                </label>
                <input
                  type="text"
                  id="firstName"
                  v-model="form.firstName"
                  required
                  class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                />
              </div>

              <div>
                <label for="lastName" class="block text-sm font-medium text-gray-700">
                  Last Name
                </label>
                <input
                  type="text"
                  id="lastName"
                  v-model="form.lastName"
                  required
                  class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                />
              </div>
            </div>

            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div>
                <label for="birthDate" class="block text-sm font-medium text-gray-700">
                  Birth Date
                </label>
                <input
                  type="date"
                  id="birthDate"
                  v-model="form.birthDate"
                  class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                />
              </div>

              <div>
                <label for="gender" class="block text-sm font-medium text-gray-700">
                  Gender
                </label>
                <select
                  id="gender"
                  v-model="form.gender"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                >
                  <option value="">Select gender</option>
                  <option value="male">Male</option>
                  <option value="female">Female</option>
                  <option value="other">Other</option>
                </select>
              </div>
            </div>

            <div>
              <label for="birthPlace" class="block text-sm font-medium text-gray-700">
                Birth Place
              </label>
              <input
                type="text"
                id="birthPlace"
                v-model="form.birthPlace"
                class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              />
            </div>
          </div>

          <!-- Biography -->
          <div class="space-y-4">
            <h4 class="text-md font-medium text-gray-900">Biography</h4>
            
            <div>
              <label for="biography" class="block text-sm font-medium text-gray-700">
                Biography
              </label>
              <textarea
                id="biography"
                v-model="form.biography"
                rows="4"
                class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              ></textarea>
            </div>
          </div>

          <!-- Relationships -->
          <div class="space-y-4">
            <h4 class="text-md font-medium text-gray-900">Relationships</h4>
            
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div>
                <label for="father" class="block text-sm font-medium text-gray-700">
                  Father
                </label>
                <select
                  id="father"
                  v-model="form.fatherId"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                >
                  <option value="">Select father</option>
                  <option v-for="person in availableParents" :key="person.id" :value="person.id">
                    {{ person.firstName }} {{ person.lastName }}
                  </option>
                </select>
              </div>

              <div>
                <label for="mother" class="block text-sm font-medium text-gray-700">
                  Mother
                </label>
                <select
                  id="mother"
                  v-model="form.motherId"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                >
                  <option value="">Select mother</option>
                  <option v-for="person in availableParents" :key="person.id" :value="person.id">
                    {{ person.firstName }} {{ person.lastName }}
                  </option>
                </select>
              </div>
            </div>

            <div>
              <label for="spouse" class="block text-sm font-medium text-gray-700">
                Spouse
              </label>
              <select
                id="spouse"
                v-model="form.spouseId"
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="">Select spouse</option>
                <option v-for="person in availableSpouses" :key="person.id" :value="person.id">
                  {{ person.firstName }} {{ person.lastName }}
                </option>
              </select>
            </div>
          </div>

          <!-- Submit Button -->
          <div class="flex justify-end">
            <button
              type="submit"
              :disabled="loading"
              class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
            >
              <svg
                v-if="loading"
                class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path
                  class="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                ></path>
              </svg>
              {{ loading ? 'Adding...' : 'Add Person' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { usePersonStore } from '@/stores/person'

const router = useRouter()
const personStore = usePersonStore()

const form = ref({
  firstName: '',
  lastName: '',
  birthDate: '',
  gender: '',
  birthPlace: '',
  biography: '',
  fatherId: '',
  motherId: '',
  spouseId: ''
})

const loading = ref(false)
const availableParents = ref([])
const availableSpouses = ref([])

onMounted(async () => {
  try {
    const [parents, spouses] = await Promise.all([
      personStore.getAvailableParents(),
      personStore.getAvailableSpouses()
    ])
    availableParents.value = parents
    availableSpouses.value = spouses
  } catch (error) {
    console.error('Error fetching available relationships:', error)
    // Handle error (show notification, etc.)
  }
})

const handleSubmit = async () => {
  try {
    loading.value = true
    const newPerson = await personStore.createPerson(form.value)
    router.push(`/person/${newPerson.id}`)
  } catch (error) {
    console.error('Error creating person:', error)
    // Handle error (show notification, etc.)
  } finally {
    loading.value = false
  }
}
</script> 