<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="mb-8">
        <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
          {{ isEditing ? 'Edit Relationship' : 'Add Relationship' }}
        </h2>
        <p class="mt-1 text-sm text-gray-500">
          Define the connection between family members
        </p>
      </div>

      <div class="bg-white rounded-lg shadow-lg overflow-hidden">
        <div class="p-6">
          <form @submit.prevent="handleSubmit" class="space-y-6">
            <!-- Person Selection -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-medium text-gray-700">Person 1</label>
                <div class="mt-1">
                  <select
                    v-model="relationship.person1Id"
                    class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    required
                  >
                    <option value="">Select a person</option>
                    <option
                      v-for="person in people"
                      :key="person.id"
                      :value="person.id"
                    >
                      {{ person.name }}
                    </option>
                  </select>
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700">Person 2</label>
                <div class="mt-1">
                  <select
                    v-model="relationship.person2Id"
                    class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                    required
                  >
                    <option value="">Select a person</option>
                    <option
                      v-for="person in people"
                      :key="person.id"
                      :value="person.id"
                    >
                      {{ person.name }}
                    </option>
                  </select>
                </div>
              </div>
            </div>

            <!-- Relationship Type -->
            <div>
              <label class="block text-sm font-medium text-gray-700">Relationship Type</label>
              <div class="mt-1">
                <select
                  v-model="relationship.type"
                  class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  required
                >
                  <option value="">Select relationship type</option>
                  <option value="parent">Parent</option>
                  <option value="child">Child</option>
                  <option value="spouse">Spouse</option>
                  <option value="sibling">Sibling</option>
                  <option value="grandparent">Grandparent</option>
                  <option value="grandchild">Grandchild</option>
                  <option value="aunt_uncle">Aunt/Uncle</option>
                  <option value="niece_nephew">Niece/Nephew</option>
                  <option value="cousin">Cousin</option>
                  <option value="in_law">In-law</option>
                </select>
              </div>
            </div>

            <!-- Additional Details -->
            <div>
              <label class="block text-sm font-medium text-gray-700">Additional Details</label>
              <div class="mt-1">
                <textarea
                  v-model="relationship.details"
                  rows="3"
                  class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  placeholder="Add any additional information about this relationship..."
                ></textarea>
              </div>
            </div>

            <!-- Date Range -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-medium text-gray-700">Start Date</label>
                <div class="mt-1">
                  <input
                    v-model="relationship.startDate"
                    type="date"
                    class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  />
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700">End Date</label>
                <div class="mt-1">
                  <input
                    v-model="relationship.endDate"
                    type="date"
                    class="block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  />
                </div>
              </div>
            </div>

            <!-- Privacy Settings -->
            <div>
              <label class="block text-sm font-medium text-gray-700">Privacy</label>
              <div class="mt-2 space-y-4">
                <div class="flex items-center">
                  <input
                    v-model="relationship.isPrivate"
                    type="checkbox"
                    class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                  />
                  <label class="ml-2 block text-sm text-gray-900">
                    Make this relationship private
                  </label>
                </div>
                <p class="text-sm text-gray-500">
                  Private relationships will only be visible to you and other family members you explicitly share them with.
                </p>
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="flex justify-end space-x-3">
              <button
                type="button"
                class="px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                @click="router.back()"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                {{ isEditing ? 'Save Changes' : 'Add Relationship' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()

const isEditing = computed(() => {
  return !!route.params.id
})

const people = ref([
  { id: 1, name: 'John Smith' },
  { id: 2, name: 'Mary Smith' },
  { id: 3, name: 'James Smith' },
  { id: 4, name: 'Sarah Smith' }
])

const relationship = ref({
  person1Id: '',
  person2Id: '',
  type: '',
  details: '',
  startDate: '',
  endDate: '',
  isPrivate: false
})

onMounted(() => {
  if (isEditing.value) {
    // TODO: Fetch relationship details using route.params.id
    console.log('Loading relationship:', route.params.id)
  }
})

const handleSubmit = async () => {
  try {
    // TODO: Implement relationship save logic
    console.log('Saving relationship:', relationship.value)
    
    // Redirect back to relationships list
    router.push('/relationships')
  } catch (error) {
    console.error('Error saving relationship:', error)
    // TODO: Show error message to user
  }
}
</script> 