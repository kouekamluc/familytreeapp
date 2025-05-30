<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="bg-white shadow rounded-lg">
        <!-- Header -->
        <div class="px-4 py-5 border-b border-gray-200 sm:px-6">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Pending Invitations
              </h3>
              <p class="mt-1 text-sm text-gray-500">
                Manage invitations to join your family tree
              </p>
            </div>
            <button
              @click="showInviteModal = true"
              class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              New Invitation
            </button>
          </div>
        </div>

        <!-- Invites List -->
        <div class="px-4 py-5 sm:p-6">
          <div class="flex flex-col">
            <div class="-my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
              <div class="py-2 align-middle inline-block min-w-full sm:px-6 lg:px-8">
                <div class="shadow overflow-hidden border-b border-gray-200 sm:rounded-lg">
                  <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                      <tr>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Invitee
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Role
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Status
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Sent
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Expires
                        </th>
                        <th scope="col" class="relative px-6 py-3">
                          <span class="sr-only">Actions</span>
                        </th>
                      </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                      <tr v-for="invite in invites" :key="invite.id">
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm font-medium text-gray-900">
                            {{ invite.email }}
                          </div>
                          <div class="text-sm text-gray-500">
                            {{ invite.name || 'No name provided' }}
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800">
                            {{ invite.role }}
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span
                            class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                            :class="{
                              'bg-yellow-100 text-yellow-800': invite.status === 'pending',
                              'bg-green-100 text-green-800': invite.status === 'accepted',
                              'bg-red-100 text-red-800': invite.status === 'expired'
                            }"
                          >
                            {{ invite.status }}
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {{ formatDate(invite.sentAt) }}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {{ formatDate(invite.expiresAt) }}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                          <button
                            v-if="invite.status === 'pending'"
                            @click="resendInvite(invite)"
                            class="text-indigo-600 hover:text-indigo-900 mr-4"
                          >
                            Resend
                          </button>
                          <button
                            @click="cancelInvite(invite)"
                            class="text-red-600 hover:text-red-900"
                          >
                            Cancel
                          </button>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Invite Modal -->
    <div v-if="showInviteModal" class="fixed z-10 inset-0 overflow-y-auto">
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>

        <div class="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
          <div>
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              Send Invitation
            </h3>
            <div class="mt-2">
              <form @submit.prevent="handleInvite" class="space-y-4">
                <div>
                  <label for="email" class="block text-sm font-medium text-gray-700">
                    Email address
                  </label>
                  <input
                    type="email"
                    id="email"
                    v-model="inviteForm.email"
                    required
                    class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  />
                </div>

                <div>
                  <label for="name" class="block text-sm font-medium text-gray-700">
                    Name (Optional)
                  </label>
                  <input
                    type="text"
                    id="name"
                    v-model="inviteForm.name"
                    class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  />
                </div>

                <div>
                  <label for="role" class="block text-sm font-medium text-gray-700">
                    Role
                  </label>
                  <select
                    id="role"
                    v-model="inviteForm.role"
                    required
                    class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                  >
                    <option value="editor">Editor</option>
                    <option value="viewer">Viewer</option>
                  </select>
                </div>

                <div>
                  <label for="message" class="block text-sm font-medium text-gray-700">
                    Personal Message (Optional)
                  </label>
                  <textarea
                    id="message"
                    v-model="inviteForm.message"
                    rows="3"
                    class="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  ></textarea>
                </div>

                <div>
                  <label for="expiresIn" class="block text-sm font-medium text-gray-700">
                    Invitation Expires In
                  </label>
                  <select
                    id="expiresIn"
                    v-model="inviteForm.expiresIn"
                    required
                    class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                  >
                    <option value="7">7 days</option>
                    <option value="14">14 days</option>
                    <option value="30">30 days</option>
                  </select>
                </div>
              </form>
            </div>
          </div>
          <div class="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense">
            <button
              type="button"
              @click="handleInvite"
              :disabled="loading"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:col-start-2 sm:text-sm"
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
              {{ loading ? 'Sending...' : 'Send Invitation' }}
            </button>
            <button
              type="button"
              @click="showInviteModal = false"
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
import { useTreeStore } from '@/stores/tree'

const treeStore = useTreeStore()

const invites = ref([])
const loading = ref(false)
const showInviteModal = ref(false)

const inviteForm = ref({
  email: '',
  name: '',
  role: 'viewer',
  message: '',
  expiresIn: '7'
})

onMounted(async () => {
  try {
    const treeInvites = await treeStore.getTreeInvites()
    invites.value = treeInvites
  } catch (error) {
    console.error('Error fetching tree invites:', error)
    // Handle error (show notification, etc.)
  }
})

const formatDate = (date) => {
  return new Date(date).toLocaleDateString()
}

const handleInvite = async () => {
  try {
    loading.value = true
    const newInvite = await treeStore.createInvite(inviteForm.value)
    invites.value.push(newInvite)
    showInviteModal.value = false
    inviteForm.value = {
      email: '',
      name: '',
      role: 'viewer',
      message: '',
      expiresIn: '7'
    }
    // Show success notification
  } catch (error) {
    console.error('Error creating invite:', error)
    // Handle error (show notification, etc.)
  } finally {
    loading.value = false
  }
}

const resendInvite = async (invite) => {
  try {
    loading.value = true
    await treeStore.resendInvite(invite.id)
    // Show success notification
  } catch (error) {
    console.error('Error resending invite:', error)
    // Handle error (show notification, etc.)
  } finally {
    loading.value = false
  }
}

const cancelInvite = async (invite) => {
  if (!confirm(`Are you sure you want to cancel the invitation to ${invite.email}?`)) {
    return
  }

  try {
    loading.value = true
    await treeStore.cancelInvite(invite.id)
    invites.value = invites.value.filter(i => i.id !== invite.id)
    // Show success notification
  } catch (error) {
    console.error('Error canceling invite:', error)
    // Handle error (show notification, etc.)
  } finally {
    loading.value = false
  }
}
</script> 