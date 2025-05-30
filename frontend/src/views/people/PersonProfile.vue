<template>
  <div class="min-h-screen bg-gray-100">
    <div class="py-10">
      <header>
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between">
            <h1 class="text-3xl font-bold leading-tight tracking-tight text-gray-900">
              {{ personStore.currentPerson?.firstName }} {{ personStore.currentPerson?.lastName }}
            </h1>
            <div class="flex space-x-4">
              <button
                @click="showEditModal = true"
                class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
                Edit Profile
              </button>
              <button
                @click="showAddMediaModal = true"
                class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                Add Media
              </button>
            </div>
          </div>
        </div>
      </header>
      <main>
        <div class="mx-auto max-w-7xl sm:px-6 lg:px-8">
          <div class="px-4 py-8 sm:px-0">
            <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
              <!-- Personal Information -->
              <div class="lg:col-span-2">
                <div class="bg-white shadow rounded-lg">
                  <div class="px-4 py-5 sm:p-6">
                    <h3 class="text-lg font-medium leading-6 text-gray-900">Personal Information</h3>
                    <div class="mt-6 border-t border-gray-200">
                      <dl class="divide-y divide-gray-200">
                        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4">
                          <dt class="text-sm font-medium text-gray-500">Full name</dt>
                          <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                            {{ personStore.currentPerson?.firstName }} {{ personStore.currentPerson?.lastName }}
                          </dd>
                        </div>
                        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4">
                          <dt class="text-sm font-medium text-gray-500">Birth date</dt>
                          <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                            {{ formatDate(personStore.currentPerson?.birthDate) }}
                          </dd>
                        </div>
                        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4">
                          <dt class="text-sm font-medium text-gray-500">Gender</dt>
                          <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                            {{ personStore.currentPerson?.gender }}
                          </dd>
                        </div>
                        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4">
                          <dt class="text-sm font-medium text-gray-500">Birth place</dt>
                          <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                            {{ personStore.currentPerson?.birthPlace }}
                          </dd>
                        </div>
                        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4">
                          <dt class="text-sm font-medium text-gray-500">Biography</dt>
                          <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                            {{ personStore.currentPerson?.biography }}
                          </dd>
                        </div>
                      </dl>
                    </div>
                  </div>
                </div>

                <!-- Relationships -->
                <div class="mt-6 bg-white shadow rounded-lg">
                  <div class="px-4 py-5 sm:p-6">
                    <h3 class="text-lg font-medium leading-6 text-gray-900">Relationships</h3>
                    <div class="mt-6">
                      <div class="space-y-6">
                        <!-- Parents -->
                        <div>
                          <h4 class="text-sm font-medium text-gray-500">Parents</h4>
                          <div class="mt-2 grid grid-cols-1 gap-4 sm:grid-cols-2">
                            <div v-for="parent in personStore.currentPerson?.parents" :key="parent.id" class="relative rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm flex items-center space-x-3 hover:border-gray-400">
                              <div class="flex-1 min-w-0">
                                <router-link :to="`/people/${parent.id}`" class="focus:outline-none">
                                  <span class="absolute inset-0" aria-hidden="true"></span>
                                  <p class="text-sm font-medium text-gray-900">{{ parent.firstName }} {{ parent.lastName }}</p>
                                  <p class="text-sm text-gray-500">{{ parent.relationship }}</p>
                                </router-link>
                              </div>
                            </div>
                          </div>
                        </div>

                        <!-- Siblings -->
                        <div>
                          <h4 class="text-sm font-medium text-gray-500">Siblings</h4>
                          <div class="mt-2 grid grid-cols-1 gap-4 sm:grid-cols-2">
                            <div v-for="sibling in personStore.currentPerson?.siblings" :key="sibling.id" class="relative rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm flex items-center space-x-3 hover:border-gray-400">
                              <div class="flex-1 min-w-0">
                                <router-link :to="`/people/${sibling.id}`" class="focus:outline-none">
                                  <span class="absolute inset-0" aria-hidden="true"></span>
                                  <p class="text-sm font-medium text-gray-900">{{ sibling.firstName }} {{ sibling.lastName }}</p>
                                  <p class="text-sm text-gray-500">{{ sibling.relationship }}</p>
                                </router-link>
                              </div>
                            </div>
                          </div>
                        </div>

                        <!-- Spouse -->
                        <div>
                          <h4 class="text-sm font-medium text-gray-500">Spouse</h4>
                          <div class="mt-2">
                            <div v-if="personStore.currentPerson?.spouse" class="relative rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm flex items-center space-x-3 hover:border-gray-400">
                              <div class="flex-1 min-w-0">
                                <router-link :to="`/people/${personStore.currentPerson.spouse.id}`" class="focus:outline-none">
                                  <span class="absolute inset-0" aria-hidden="true"></span>
                                  <p class="text-sm font-medium text-gray-900">
                                    {{ personStore.currentPerson.spouse.firstName }} {{ personStore.currentPerson.spouse.lastName }}
                                  </p>
                                  <p class="text-sm text-gray-500">Married {{ formatDate(personStore.currentPerson.spouse.marriageDate) }}</p>
                                </router-link>
                              </div>
                            </div>
                            <div v-else class="text-sm text-gray-500">No spouse information available</div>
                          </div>
                        </div>

                        <!-- Children -->
                        <div>
                          <h4 class="text-sm font-medium text-gray-500">Children</h4>
                          <div class="mt-2 grid grid-cols-1 gap-4 sm:grid-cols-2">
                            <div v-for="child in personStore.currentPerson?.children" :key="child.id" class="relative rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm flex items-center space-x-3 hover:border-gray-400">
                              <div class="flex-1 min-w-0">
                                <router-link :to="`/people/${child.id}`" class="focus:outline-none">
                                  <span class="absolute inset-0" aria-hidden="true"></span>
                                  <p class="text-sm font-medium text-gray-900">{{ child.firstName }} {{ child.lastName }}</p>
                                  <p class="text-sm text-gray-500">Born {{ formatDate(child.birthDate) }}</p>
                                </router-link>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Media Gallery -->
              <div class="lg:col-span-1">
                <div class="bg-white shadow rounded-lg">
                  <div class="px-4 py-5 sm:p-6">
                    <h3 class="text-lg font-medium leading-6 text-gray-900">Media Gallery</h3>
                    <div class="mt-6 grid grid-cols-2 gap-4">
                      <div v-for="media in personStore.currentPerson?.media" :key="media.id" class="relative">
                        <img
                          :src="media.url"
                          :alt="media.description"
                          class="h-24 w-full object-cover rounded-lg"
                        />
                        <div class="absolute inset-0 bg-black bg-opacity-0 hover:bg-opacity-20 transition-opacity rounded-lg">
                          <div class="absolute bottom-0 left-0 right-0 p-2 bg-black bg-opacity-50 text-white text-xs rounded-b-lg">
                            {{ media.description }}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>

    <!-- Edit Profile Modal -->
    <div v-if="showEditModal" class="fixed z-10 inset-0 overflow-y-auto">
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
        <div class="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
          <div>
            <div class="mt-3 text-center sm:mt-5">
              <h3 class="text-lg leading-6 font-medium text-gray-900">Edit Profile</h3>
              <div class="mt-2">
                <form @submit.prevent="updateProfile" class="space-y-4">
                  <div>
                    <label for="firstName" class="block text-sm font-medium text-gray-700">First Name</label>
                    <input
                      type="text"
                      id="firstName"
                      v-model="editForm.firstName"
                      class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      required
                    />
                  </div>
                  <div>
                    <label for="lastName" class="block text-sm font-medium text-gray-700">Last Name</label>
                    <input
                      type="text"
                      id="lastName"
                      v-model="editForm.lastName"
                      class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      required
                    />
                  </div>
                  <div>
                    <label for="birthDate" class="block text-sm font-medium text-gray-700">Birth Date</label>
                    <input
                      type="date"
                      id="birthDate"
                      v-model="editForm.birthDate"
                      class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    />
                  </div>
                  <div>
                    <label for="birthPlace" class="block text-sm font-medium text-gray-700">Birth Place</label>
                    <input
                      type="text"
                      id="birthPlace"
                      v-model="editForm.birthPlace"
                      class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    />
                  </div>
                  <div>
                    <label for="biography" class="block text-sm font-medium text-gray-700">Biography</label>
                    <textarea
                      id="biography"
                      v-model="editForm.biography"
                      rows="4"
                      class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    ></textarea>
                  </div>
                </form>
              </div>
            </div>
          </div>
          <div class="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense">
            <button
              type="button"
              @click="updateProfile"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:col-start-2 sm:text-sm"
            >
              Save Changes
            </button>
            <button
              type="button"
              @click="showEditModal = false"
              class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:col-start-1 sm:text-sm"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Add Media Modal -->
    <div v-if="showAddMediaModal" class="fixed z-10 inset-0 overflow-y-auto">
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>
        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>
        <div class="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
          <div>
            <div class="mt-3 text-center sm:mt-5">
              <h3 class="text-lg leading-6 font-medium text-gray-900">Add Media</h3>
              <div class="mt-2">
                <form @submit.prevent="addMedia" class="space-y-4">
                  <div>
                    <label for="mediaFile" class="block text-sm font-medium text-gray-700">Media File</label>
                    <input
                      type="file"
                      id="mediaFile"
                      @change="handleFileUpload"
                      class="mt-1 block w-full"
                      accept="image/*,video/*"
                      required
                    />
                  </div>
                  <div>
                    <label for="mediaDescription" class="block text-sm font-medium text-gray-700">Description</label>
                    <input
                      type="text"
                      id="mediaDescription"
                      v-model="newMedia.description"
                      class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      required
                    />
                  </div>
                  <div>
                    <label for="mediaDate" class="block text-sm font-medium text-gray-700">Date</label>
                    <input
                      type="date"
                      id="mediaDate"
                      v-model="newMedia.date"
                      class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    />
                  </div>
                </form>
              </div>
            </div>
          </div>
          <div class="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense">
            <button
              type="button"
              @click="addMedia"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:col-start-2 sm:text-sm"
            >
              Upload
            </button>
            <button
              type="button"
              @click="showAddMediaModal = false"
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
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { usePeopleStore } from '@/stores/people'
import { format } from 'date-fns'

const route = useRoute()
const peopleStore = usePeopleStore()

const showEditModal = ref(false)
const showAddMediaModal = ref(false)

const editForm = ref({
  firstName: '',
  lastName: '',
  birthDate: '',
  birthPlace: '',
  biography: ''
})

const newMedia = ref({
  file: null,
  description: '',
  date: ''
})

const formatDate = (date) => {
  if (!date) return 'Not specified'
  return format(new Date(date), 'MMMM d, yyyy')
}

const handleFileUpload = (event) => {
  newMedia.value.file = event.target.files[0]
}

const updateProfile = async () => {
  try {
    await peopleStore.updatePerson(route.params.id, editForm.value)
    showEditModal.value = false
  } catch (error) {
    console.error('Error updating profile:', error)
  }
}

const addMedia = async () => {
  try {
    const formData = new FormData()
    formData.append('file', newMedia.value.file)
    formData.append('description', newMedia.value.description)
    formData.append('date', newMedia.value.date)
    formData.append('personId', route.params.id)

    await peopleStore.addMedia(formData)
    showAddMediaModal.value = false
    newMedia.value = {
      file: null,
      description: '',
      date: ''
    }
  } catch (error) {
    console.error('Error adding media:', error)
  }
}

onMounted(async () => {
  try {
    const person = await peopleStore.fetchPerson(route.params.id)
    editForm.value = {
      firstName: person.firstName,
      lastName: person.lastName,
      birthDate: person.birthDate,
      birthPlace: person.birthPlace,
      biography: person.biography
    }
  } catch (error) {
    console.error('Error fetching person:', error)
  }
})
</script> 