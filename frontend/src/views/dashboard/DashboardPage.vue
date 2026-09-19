<template>
  <div class="min-h-screen bg-gray-50">
    <header class="bg-white shadow">
      <div class="container mx-auto px-4 py-6">
        <div class="flex justify-between items-center">
          <h1 class="text-2xl font-bold text-gray-900">Dashboard</h1>
          <div class="flex items-center space-x-4">
            <button class="btn btn-primary" @click="showAddPersonModal = true">
              Add Person
            </button>
            <button class="btn btn-secondary" @click="showAddEventModal = true">
              Add Event
            </button>
          </div>
        </div>
      </div>
    </header>

    <main class="container mx-auto px-4 py-8">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <!-- Recent Activity -->
        <div class="card">
          <h2 class="text-lg font-semibold mb-4">Recent Activity</h2>
          <div class="space-y-4">
            <div v-for="activity in recentActivity" :key="activity.id" class="flex items-start space-x-3">
              <div class="flex-shrink-0">
                <div class="w-8 h-8 rounded-full bg-primary-100 flex items-center justify-center">
                  <span class="text-primary-600 text-sm">{{ activity.initials }}</span>
                </div>
              </div>
              <div>
                <p class="text-sm text-gray-900">{{ activity.description }}</p>
                <p class="text-xs text-gray-500">{{ activity.time }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Family Tree Stats -->
        <div class="card">
          <h2 class="text-lg font-semibold mb-4">Family Tree Stats</h2>
          <div class="grid grid-cols-2 gap-4">
            <div class="bg-primary-50 rounded-lg p-4">
              <p class="text-sm text-gray-600">Total People</p>
              <p class="text-2xl font-bold text-primary-600">{{ stats.totalPeople }}</p>
            </div>
            <div class="bg-primary-50 rounded-lg p-4">
              <p class="text-sm text-gray-600">Relationships</p>
              <p class="text-2xl font-bold text-primary-600">{{ stats.totalRelationships }}</p>
            </div>
            <div class="bg-primary-50 rounded-lg p-4">
              <p class="text-sm text-gray-600">Events</p>
              <p class="text-2xl font-bold text-primary-600">{{ stats.totalEvents }}</p>
            </div>
            <div class="bg-primary-50 rounded-lg p-4">
              <p class="text-sm text-gray-600">Media Items</p>
              <p class="text-2xl font-bold text-primary-600">{{ stats.totalMedia }}</p>
            </div>
          </div>
        </div>

        <!-- Upcoming Events -->
        <div class="card">
          <h2 class="text-lg font-semibold mb-4">Upcoming Events</h2>
          <div class="space-y-4">
            <div v-for="event in upcomingEvents" :key="event.id" class="flex items-start space-x-3">
              <div class="flex-shrink-0">
                <div class="w-8 h-8 rounded-full bg-primary-100 flex items-center justify-center">
                  <span class="text-primary-600 text-sm">{{ event.initials }}</span>
                </div>
              </div>
              <div>
                <p class="text-sm text-gray-900">{{ event.title }}</p>
                <p class="text-xs text-gray-500">{{ event.date }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Recent Media -->
      <div class="mt-8">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-lg font-semibold">Recent Media</h2>
          <router-link to="/media" class="text-primary-600 hover:text-primary-700">
            View All
          </router-link>
        </div>
        <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
          <div v-for="media in recentMedia" :key="media.id" class="aspect-w-1 aspect-h-1">
            <img
              :src="media.thumbnail"
              :alt="media.title"
              class="object-cover rounded-lg shadow-sm"
            />
          </div>
        </div>
      </div>
    </main>

    <!-- Add Person Modal -->
    <div v-if="showAddPersonModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
      <div class="bg-white rounded-lg p-6 w-full max-w-md">
        <h3 class="text-lg font-semibold mb-4">Add New Person</h3>
        <form @submit.prevent="handleAddPerson">
          <div class="space-y-4">
            <div>
              <label class="label">First Name</label>
              <input type="text" v-model="newPerson.firstName" class="input" required />
            </div>
            <div>
              <label class="label">Last Name</label>
              <input type="text" v-model="newPerson.lastName" class="input" required />
            </div>
            <div>
              <label class="label">Birth Date</label>
              <input type="date" v-model="newPerson.birthDate" class="input" />
            </div>
            <div>
              <label class="label">Gender</label>
              <select v-model="newPerson.gender" class="input">
                <option value="M">Male</option>
                <option value="F">Female</option>
                <option value="O">Other</option>
              </select>
            </div>
          </div>
          <div class="mt-6 flex justify-end space-x-3">
            <button type="button" class="btn btn-secondary" @click="showAddPersonModal = false">
              Cancel
            </button>
            <button type="submit" class="btn btn-primary">
              Add Person
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Add Event Modal -->
    <div v-if="showAddEventModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
      <div class="bg-white rounded-lg p-6 w-full max-w-md">
        <h3 class="text-lg font-semibold mb-4">Add New Event</h3>
        <form @submit.prevent="handleAddEvent">
          <div class="space-y-4">
            <div>
              <label class="label">Title</label>
              <input type="text" v-model="newEvent.title" class="input" required />
            </div>
            <div>
              <label class="label">Date</label>
              <input type="date" v-model="newEvent.date" class="input" required />
            </div>
            <div>
              <label class="label">Description</label>
              <textarea v-model="newEvent.description" class="input" rows="3"></textarea>
            </div>
            <div>
              <label class="label">Related People</label>
              <select v-model="newEvent.relatedPeople" class="input" multiple>
                <option v-for="person in people" :key="person.id" :value="person.id">
                  {{ person.firstName }} {{ person.lastName }}
                </option>
              </select>
            </div>
          </div>
          <div class="mt-6 flex justify-end space-x-3">
            <button type="button" class="btn btn-secondary" @click="showAddEventModal = false">
              Cancel
            </button>
            <button type="submit" class="btn btn-primary">
              Add Event
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
import { usePeopleStore } from '@/stores/people'
import { useEventsStore } from '@/stores/events'
import { useMediaStore } from '@/stores/media'

const router = useRouter()
const peopleStore = usePeopleStore()
const eventsStore = useEventsStore()
const mediaStore = useMediaStore()

// State
const showAddPersonModal = ref(false)
const showAddEventModal = ref(false)
const newPerson = ref({
  firstName: '',
  lastName: '',
  birthDate: '',
  gender: 'M'
})
const newEvent = ref({
  title: '',
  date: '',
  description: '',
  relatedPeople: []
})

// Mock data
const recentActivity = ref([
  {
    id: 1,
    initials: 'JD',
    description: 'Added new person: John Doe',
    time: '2 hours ago'
  },
  {
    id: 2,
    initials: 'JS',
    description: 'Updated relationship: John Doe and Jane Smith',
    time: '4 hours ago'
  }
])

const stats = ref({
  totalPeople: 0,
  totalRelationships: 0,
  totalEvents: 0,
  totalMedia: 0
})

const upcomingEvents = ref([
  {
    id: 1,
    initials: 'BD',
    title: 'Birthday Party',
    date: 'Next Saturday'
  },
  {
    id: 2,
    initials: 'WD',
    title: 'Wedding Anniversary',
    date: 'In 2 weeks'
  }
])

const recentMedia = ref([
  {
    id: 1,
    title: 'Family Photo',
    thumbnail: 'https://via.placeholder.com/150'
  },
  {
    id: 2,
    title: 'Wedding Photo',
    thumbnail: 'https://via.placeholder.com/150'
  }
])

// Methods
const handleAddPerson = async () => {
  try {
    await peopleStore.createPerson(newPerson.value)
    showAddPersonModal.value = false
    newPerson.value = {
      firstName: '',
      lastName: '',
      birthDate: '',
      gender: 'M'
    }
  } catch (error) {
    console.error('Error adding person:', error)
  }
}

const handleAddEvent = async () => {
  try {
    await eventsStore.createEvent(newEvent.value)
    showAddEventModal.value = false
    newEvent.value = {
      title: '',
      date: '',
      description: '',
      relatedPeople: []
    }
  } catch (error) {
    console.error('Error adding event:', error)
  }
}

// Lifecycle hooks
onMounted(async () => {
  try {
    await Promise.all([
      peopleStore.fetchPeople(),
      eventsStore.fetchEvents(),
      mediaStore.fetchMedia()
    ])
    
    // Update stats
    const peopleList = Array.isArray(peopleStore.people) ? peopleStore.people : (peopleStore.people?.results || [])
    const eventsList = Array.isArray(eventsStore.events) ? eventsStore.events : (eventsStore.events?.results || [])
    const mediaList = Array.isArray(mediaStore.mediaItems) ? mediaStore.mediaItems : (mediaStore.media || [])

    stats.value = {
      totalPeople: peopleList.length,
      totalRelationships: 0,
      totalEvents: eventsList.length,
      totalMedia: mediaList.length
    }
  } catch (error) {
    console.error('Error loading dashboard data:', error)
  }
})
</script> 