<template>
  <div class="min-h-screen bg-gray-100">
    <!-- Toolbar -->
    <div class="bg-white shadow">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex">
            <div class="flex-shrink-0 flex items-center">
              <h1 class="text-xl font-semibold text-gray-900">
                Family Timeline
              </h1>
            </div>
          </div>
          <div class="flex items-center space-x-4">
            <!-- Time Range Controls -->
            <div class="flex items-center space-x-2">
              <button
                @click="zoomOut"
                class="p-2 rounded-md text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4" />
                </svg>
              </button>
              <select
                v-model="timeRange"
                class="block w-40 pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="year">Year</option>
                <option value="decade">Decade</option>
                <option value="century">Century</option>
              </select>
              <button
                @click="zoomIn"
                class="p-2 rounded-md text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                </svg>
              </button>
            </div>

            <!-- Filter Controls -->
            <div class="flex items-center space-x-2">
              <button
                @click="showFilterModal = true"
                class="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <svg class="-ml-1 mr-2 h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" />
                </svg>
                Filters
              </button>
            </div>

            <!-- Action Buttons -->
            <div class="flex items-center space-x-4">
              <button
                @click="showAddEventModal = true"
                class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <svg class="-ml-1 mr-2 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                </svg>
                Add Event
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Timeline Visualization -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <div class="bg-white shadow rounded-lg overflow-hidden">
        <div class="p-4">
          <!-- Timeline -->
          <div class="relative">
            <!-- Timeline Line -->
            <div class="absolute left-1/2 transform -translate-x-1/2 h-full w-0.5 bg-gray-200"></div>

            <!-- Timeline Events -->
            <div class="space-y-8">
              <div v-for="event in events" :key="event.id" class="relative">
                <!-- Event Content -->
                <div
                  :class="[
                    'relative flex items-center',
                    event.position === 'left' ? 'justify-start' : 'justify-end'
                  ]"
                >
                  <div
                    :class="[
                      'w-1/2 p-4 rounded-lg shadow-sm',
                      event.position === 'left' ? 'mr-8' : 'ml-8',
                      event.type === 'birth' ? 'bg-green-50' :
                      event.type === 'marriage' ? 'bg-blue-50' :
                      event.type === 'death' ? 'bg-red-50' :
                      'bg-gray-50'
                    ]"
                  >
                    <div class="flex items-center justify-between">
                      <div class="flex items-center">
                        <div
                          :class="[
                            'flex-shrink-0 h-8 w-8 rounded-full flex items-center justify-center',
                            event.type === 'birth' ? 'bg-green-100 text-green-600' :
                            event.type === 'marriage' ? 'bg-blue-100 text-blue-600' :
                            event.type === 'death' ? 'bg-red-100 text-red-600' :
                            'bg-gray-100 text-gray-600'
                          ]"
                        >
                          <component :is="event.icon" class="h-5 w-5" />
                        </div>
                        <div class="ml-4">
                          <h3 class="text-lg font-medium text-gray-900">
                            {{ event.title }}
                          </h3>
                          <p class="text-sm text-gray-500">
                            {{ event.date }}
                          </p>
                        </div>
                      </div>
                      <div class="flex items-center space-x-2">
                        <button
                          @click="editEvent(event)"
                          class="text-gray-400 hover:text-gray-500"
                        >
                          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                          </svg>
                        </button>
                        <button
                          @click="deleteEvent(event)"
                          class="text-gray-400 hover:text-gray-500"
                        >
                          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                        </button>
                      </div>
                    </div>
                    <p class="mt-2 text-sm text-gray-600">
                      {{ event.description }}
                    </p>
                    <div v-if="event.media" class="mt-4">
                      <img
                        :src="event.media"
                        :alt="event.title"
                        class="h-32 w-full object-cover rounded-lg"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Add Event Modal -->
    <div
      v-if="showAddEventModal"
      class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center"
    >
      <div class="bg-white rounded-lg max-w-md w-full mx-4 p-6">
        <h3 class="text-lg font-medium text-gray-900 mb-4">
          Add Timeline Event
        </h3>
        <div class="space-y-4">
          <div>
            <label for="title" class="block text-sm font-medium text-gray-700">
              Event Title
            </label>
            <input
              type="text"
              v-model="newEvent.title"
              class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            />
          </div>
          <div>
            <label for="date" class="block text-sm font-medium text-gray-700">
              Date
            </label>
            <input
              type="date"
              v-model="newEvent.date"
              class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            />
          </div>
          <div>
            <label for="type" class="block text-sm font-medium text-gray-700">
              Event Type
            </label>
            <select
              v-model="newEvent.type"
              class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
            >
              <option value="birth">Birth</option>
              <option value="marriage">Marriage</option>
              <option value="death">Death</option>
              <option value="other">Other</option>
            </select>
          </div>
          <div>
            <label for="description" class="block text-sm font-medium text-gray-700">
              Description
            </label>
            <textarea
              v-model="newEvent.description"
              rows="3"
              class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
            />
          </div>
          <div>
            <label for="media" class="block text-sm font-medium text-gray-700">
              Media
            </label>
            <input
              type="file"
              @change="handleMediaUpload"
              class="mt-1 block w-full"
            />
          </div>
          <div class="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense">
            <button
              type="button"
              @click="addEvent"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:col-start-2 sm:text-sm"
            >
              Add
            </button>
            <button
              type="button"
              @click="showAddEventModal = false"
              class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:col-start-1 sm:text-sm"
            >
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Filter Modal -->
    <div
      v-if="showFilterModal"
      class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center"
    >
      <div class="bg-white rounded-lg max-w-md w-full mx-4 p-6">
        <h3 class="text-lg font-medium text-gray-900 mb-4">
          Filter Timeline
        </h3>
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700">
              Event Types
            </label>
            <div class="mt-2 space-y-2">
              <div v-for="type in eventTypes" :key="type.value" class="flex items-center">
                <input
                  type="checkbox"
                  v-model="filters.types"
                  :value="type.value"
                  class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                />
                <label class="ml-2 text-sm text-gray-700">
                  {{ type.label }}
                </label>
              </div>
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700">
              Date Range
            </label>
            <div class="mt-2 grid grid-cols-2 gap-4">
              <div>
                <label class="block text-xs text-gray-500">From</label>
                <input
                  type="date"
                  v-model="filters.dateRange.from"
                  class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                />
              </div>
              <div>
                <label class="block text-xs text-gray-500">To</label>
                <input
                  type="date"
                  v-model="filters.dateRange.to"
                  class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                />
              </div>
            </div>
          </div>
          <div class="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense">
            <button
              type="button"
              @click="applyFilters"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:col-start-2 sm:text-sm"
            >
              Apply
            </button>
            <button
              type="button"
              @click="showFilterModal = false"
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
import { ref } from 'vue'
import { useToast } from 'vue-toastification'

const toast = useToast()
const timeRange = ref('year')
const showAddEventModal = ref(false)
const showFilterModal = ref(false)

const newEvent = ref({
  title: '',
  date: '',
  type: 'other',
  description: '',
  media: null
})

const filters = ref({
  types: ['birth', 'marriage', 'death', 'other'],
  dateRange: {
    from: '',
    to: ''
  }
})

const eventTypes = [
  { value: 'birth', label: 'Birth' },
  { value: 'marriage', label: 'Marriage' },
  { value: 'death', label: 'Death' },
  { value: 'other', label: 'Other' }
]

const events = ref([
  {
    id: 1,
    title: 'John Smith Born',
    date: '1950-01-15',
    type: 'birth',
    description: 'Born in New York City',
    media: '/images/john-birth.jpg',
    position: 'left',
    icon: 'UserIcon'
  },
  {
    id: 2,
    title: 'Sarah Johnson Born',
    date: '1952-03-20',
    type: 'birth',
    description: 'Born in Boston',
    media: '/images/sarah-birth.jpg',
    position: 'right',
    icon: 'UserIcon'
  },
  {
    id: 3,
    title: 'John & Sarah Married',
    date: '1975-06-10',
    type: 'marriage',
    description: 'Married in New York City',
    media: '/images/wedding.jpg',
    position: 'left',
    icon: 'HeartIcon'
  }
])

const zoomIn = () => {
  // TODO: Implement zoom functionality
}

const zoomOut = () => {
  // TODO: Implement zoom functionality
}

const handleMediaUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    // TODO: Implement file upload
    newEvent.value.media = URL.createObjectURL(file)
  }
}

const addEvent = () => {
  // TODO: Implement API call to add event
  events.value.push({
    id: Date.now(),
    ...newEvent.value,
    position: events.value.length % 2 === 0 ? 'left' : 'right',
    icon: newEvent.value.type === 'birth' ? 'UserIcon' :
          newEvent.value.type === 'marriage' ? 'HeartIcon' :
          newEvent.value.type === 'death' ? 'CrossIcon' :
          'StarIcon'
  })
  showAddEventModal.value = false
  newEvent.value = {
    title: '',
    date: '',
    type: 'other',
    description: '',
    media: null
  }
  toast.success('Event added successfully')
}

const editEvent = (event) => {
  // TODO: Implement edit functionality
  toast.info('Edit functionality coming soon')
}

const deleteEvent = (event) => {
  // TODO: Implement API call to delete event
  events.value = events.value.filter(e => e.id !== event.id)
  toast.success('Event deleted successfully')
}

const applyFilters = () => {
  // TODO: Implement filter functionality
  showFilterModal.value = false
  toast.success('Filters applied successfully')
}
</script> 