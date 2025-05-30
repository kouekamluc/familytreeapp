<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="md:flex md:items-center md:justify-between">
        <div class="flex-1 min-w-0">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            {{ person.firstName }} {{ person.lastName }}
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            {{ person.birthDate }} - {{ person.deathDate || 'Present' }}
          </p>
        </div>
        <div class="mt-4 flex md:mt-0 md:ml-4">
          <button
            type="button"
            @click="editPerson"
            class="ml-3 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Edit
          </button>
        </div>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-3">
        <!-- Main Content -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Basic Information -->
          <div class="bg-white shadow overflow-hidden sm:rounded-lg">
            <div class="px-4 py-5 sm:px-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Basic Information
              </h3>
            </div>
            <div class="border-t border-gray-200">
              <dl>
                <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                  <dt class="text-sm font-medium text-gray-500">Full name</dt>
                  <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                    {{ person.firstName }} {{ person.lastName }}
                  </dd>
                </div>
                <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                  <dt class="text-sm font-medium text-gray-500">Gender</dt>
                  <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                    {{ person.gender }}
                  </dd>
                </div>
                <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                  <dt class="text-sm font-medium text-gray-500">Birth</dt>
                  <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                    {{ person.birthDate }} in {{ person.birthPlace }}
                  </dd>
                </div>
                <div v-if="person.deathDate" class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                  <dt class="text-sm font-medium text-gray-500">Death</dt>
                  <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                    {{ person.deathDate }} in {{ person.deathPlace }}
                  </dd>
                </div>
                <div v-if="person.burialPlace" class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                  <dt class="text-sm font-medium text-gray-500">Burial</dt>
                  <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                    {{ person.burialPlace }}
                  </dd>
                </div>
              </dl>
            </div>
          </div>

          <!-- Family Relationships -->
          <div class="bg-white shadow overflow-hidden sm:rounded-lg">
            <div class="px-4 py-5 sm:px-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Family Relationships
              </h3>
            </div>
            <div class="border-t border-gray-200">
              <dl>
                <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                  <dt class="text-sm font-medium text-gray-500">Father</dt>
                  <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                    <a
                      v-if="person.father"
                      :href="`/people/${person.father.id}`"
                      class="text-indigo-600 hover:text-indigo-900"
                    >
                      {{ person.father.name }}
                    </a>
                    <span v-else>Unknown</span>
                  </dd>
                </div>
                <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                  <dt class="text-sm font-medium text-gray-500">Mother</dt>
                  <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                    <a
                      v-if="person.mother"
                      :href="`/people/${person.mother.id}`"
                      class="text-indigo-600 hover:text-indigo-900"
                    >
                      {{ person.mother.name }}
                    </a>
                    <span v-else>Unknown</span>
                  </dd>
                </div>
                <div class="bg-gray-50 px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                  <dt class="text-sm font-medium text-gray-500">Spouse</dt>
                  <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                    <a
                      v-if="person.spouse"
                      :href="`/people/${person.spouse.id}`"
                      class="text-indigo-600 hover:text-indigo-900"
                    >
                      {{ person.spouse.name }}
                    </a>
                    <span v-else>None</span>
                    <span v-if="person.marriageDate" class="text-gray-500">
                      (married {{ person.marriageDate }})
                    </span>
                  </dd>
                </div>
                <div class="bg-white px-4 py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                  <dt class="text-sm font-medium text-gray-500">Children</dt>
                  <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                    <ul v-if="person.children && person.children.length > 0" class="border border-gray-200 rounded-md divide-y divide-gray-200">
                      <li
                        v-for="child in person.children"
                        :key="child.id"
                        class="pl-3 pr-4 py-3 flex items-center justify-between text-sm"
                      >
                        <div class="w-0 flex-1 flex items-center">
                          <a
                            :href="`/people/${child.id}`"
                            class="text-indigo-600 hover:text-indigo-900"
                          >
                            {{ child.name }}
                          </a>
                        </div>
                      </li>
                    </ul>
                    <span v-else>None</span>
                  </dd>
                </div>
              </dl>
            </div>
          </div>

          <!-- Notes -->
          <div v-if="person.notes" class="bg-white shadow overflow-hidden sm:rounded-lg">
            <div class="px-4 py-5 sm:px-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Notes
              </h3>
            </div>
            <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
              <p class="text-sm text-gray-900 whitespace-pre-line">
                {{ person.notes }}
              </p>
            </div>
          </div>
        </div>

        <!-- Sidebar -->
        <div class="lg:col-span-1 space-y-6">
          <!-- Photo -->
          <div class="bg-white shadow overflow-hidden sm:rounded-lg">
            <div class="px-4 py-5 sm:px-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Photo
              </h3>
            </div>
            <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
              <div v-if="person.photo" class="aspect-w-1 aspect-h-1">
                <img
                  :src="person.photo"
                  :alt="`${person.firstName} ${person.lastName}`"
                  class="object-cover rounded-lg"
                />
              </div>
              <div v-else class="text-center py-12">
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
                    d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                  />
                </svg>
                <p class="mt-2 text-sm text-gray-500">No photo available</p>
              </div>
            </div>
          </div>

          <!-- Timeline -->
          <div class="bg-white shadow overflow-hidden sm:rounded-lg">
            <div class="px-4 py-5 sm:px-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Timeline
              </h3>
            </div>
            <div class="border-t border-gray-200">
              <ul class="divide-y divide-gray-200">
                <li v-for="event in timelineEvents" :key="event.id" class="px-4 py-4">
                  <div class="flex space-x-3">
                    <div class="flex-1 space-y-1">
                      <div class="flex items-center justify-between">
                        <h3 class="text-sm font-medium">{{ event.title }}</h3>
                        <p class="text-sm text-gray-500">{{ event.date }}</p>
                      </div>
                      <p class="text-sm text-gray-500">{{ event.description }}</p>
                    </div>
                  </div>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useToast } from 'vue-toastification'

const router = useRouter()
const route = useRoute()
const toast = useToast()

const person = ref({
  firstName: '',
  lastName: '',
  gender: '',
  birthDate: '',
  birthPlace: '',
  deathDate: '',
  deathPlace: '',
  burialPlace: '',
  father: null,
  mother: null,
  spouse: null,
  marriageDate: '',
  children: [],
  notes: '',
  photo: null
})

const timelineEvents = ref([])

onMounted(async () => {
  try {
    // TODO: Implement API call to fetch person data
    const personId = route.params.id
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    // Sample data - replace with actual API response
    person.value = {
      firstName: 'John',
      lastName: 'Smith',
      gender: 'male',
      birthDate: '1950-01-15',
      birthPlace: 'New York, USA',
      deathDate: '',
      deathPlace: '',
      burialPlace: '',
      father: {
        id: 1,
        name: 'William Smith'
      },
      mother: {
        id: 2,
        name: 'Mary Smith'
      },
      spouse: {
        id: 3,
        name: 'Sarah Smith'
      },
      marriageDate: '1975-06-20',
      children: [
        { id: 4, name: 'Michael Smith' },
        { id: 5, name: 'Emily Smith' }
      ],
      notes: 'Lived in New York for 30 years. Worked as a teacher. Enjoyed gardening and photography.',
      photo: '/photos/john.jpg'
    }

    // Generate timeline events
    timelineEvents.value = [
      {
        id: 1,
        title: 'Birth',
        date: '1950-01-15',
        description: 'Born in New York, USA'
      },
      {
        id: 2,
        title: 'Marriage',
        date: '1975-06-20',
        description: 'Married Sarah Smith'
      },
      {
        id: 3,
        title: 'Child Born',
        date: '1978-03-10',
        description: 'Michael Smith was born'
      },
      {
        id: 4,
        title: 'Child Born',
        date: '1980-11-25',
        description: 'Emily Smith was born'
      }
    ]
  } catch (error) {
    toast.error('Failed to load person data')
    console.error('Error loading person:', error)
  }
})

const editPerson = () => {
  router.push(`/people/${route.params.id}/edit`)
}
</script> 