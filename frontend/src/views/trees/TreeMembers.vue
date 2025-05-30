<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="bg-white shadow rounded-lg">
        <!-- Header -->
        <div class="px-4 py-5 border-b border-gray-200 sm:px-6">
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Tree Members
              </h3>
              <p class="mt-1 text-sm text-gray-500">
                Manage members and their permissions
              </p>
            </div>
            <button
              @click="showInviteModal = true"
              class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Invite Member
            </button>
          </div>
        </div>

        <!-- Members List -->
        <div class="px-4 py-5 sm:p-6">
          <div class="flex flex-col">
            <div class="-my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
              <div class="py-2 align-middle inline-block min-w-full sm:px-6 lg:px-8">
                <div class="shadow overflow-hidden border-b border-gray-200 sm:rounded-lg">
                  <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                      <tr>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Member
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Role
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Status
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Joined
                        </th>
                        <th scope="col" class="relative px-6 py-3">
                          <span class="sr-only">Actions</span>
                        </th>
                      </tr>
                    </thead>
                    <tbody class="bg-white divide-y divide-gray-200">
                      <tr v-for="member in members" :key="member.id">
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="flex items-center">
                            <div class="flex-shrink-0 h-10 w-10">
                              <img
                                class="h-10 w-10 rounded-full"
                                :src="member.avatar || '/default-avatar.png'"
                                :alt="member.name"
                              />
                            </div>
                            <div class="ml-4">
                              <div class="text-sm font-medium text-gray-900">
                                {{ member.name }}
                              </div>
                              <div class="text-sm text-gray-500">
                                {{ member.email }}
                              </div>
                            </div>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <select
                            v-model="member.role"
                            @change="updateMemberRole(member)"
                            class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                          >
                            <option value="admin">Admin</option>
                            <option value="editor">Editor</option>
                            <option value="viewer">Viewer</option>
                          </select>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span
                            class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                            :class="{
                              'bg-green-100 text-green-800': member.status === 'active',
                              'bg-yellow-100 text-yellow-800': member.status === 'pending',
                              'bg-red-100 text-red-800': member.status === 'inactive'
                            }"
                          >
                            {{ member.status }}
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {{ formatDate(member.joinedAt) }}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                          <button
                            v-if="member.status === 'pending'"
                            @click="resendInvite(member)"
                            class="text-indigo-600 hover:text-indigo-900 mr-4"
                          >
                            Resend Invite
                          </button>
                          <button
                            @click="removeMember(member)"
                            class="text-red-600 hover:text-red-900"
                          >
                            Remove
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

    <!-- Invite Member Modal -->
    <div v-if="showInviteModal" class="fixed z-10 inset-0 overflow-y-auto">
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>

        <div class="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
          <div>
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              Invite Member
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
              {{ loading ? 'Sending...' : 'Send Invite' }}
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

const members = ref([])
const loading = ref(false)
const showInviteModal = ref(false)

const inviteForm = ref({
  email: '',
  role: 'viewer',
  message: ''
})

onMounted(async () => {
  try {
    const treeMembers = await treeStore.getTreeMembers()
    members.value = treeMembers
  } catch (error) {
    console.error('Error fetching tree members:', error)
    // Handle error (show notification, etc.)
  }
})

const formatDate = (date) => {
  return new Date(date).toLocaleDateString()
}

const updateMemberRole = async (member) => {
  try {
    loading.value = true
    await treeStore.updateMemberRole(member.id, member.role)
    // Show success notification
  } catch (error) {
    console.error('Error updating member role:', error)
    // Handle error (show notification, etc.)
  } finally {
    loading.value = false
  }
}

const removeMember = async (member) => {
  if (!confirm(`Are you sure you want to remove ${member.name} from the tree?`)) {
    return
  }

  try {
    loading.value = true
    await treeStore.removeMember(member.id)
    members.value = members.value.filter(m => m.id !== member.id)
    // Show success notification
  } catch (error) {
    console.error('Error removing member:', error)
    // Handle error (show notification, etc.)
  } finally {
    loading.value = false
  }
}

const handleInvite = async () => {
  try {
    loading.value = true
    const newMember = await treeStore.inviteMember(inviteForm.value)
    members.value.push(newMember)
    showInviteModal.value = false
    inviteForm.value = {
      email: '',
      role: 'viewer',
      message: ''
    }
    // Show success notification
  } catch (error) {
    console.error('Error inviting member:', error)
    // Handle error (show notification, etc.)
  } finally {
    loading.value = false
  }
}

const resendInvite = async (member) => {
  try {
    loading.value = true
    await treeStore.resendInvite(member.id)
    // Show success notification
  } catch (error) {
    console.error('Error resending invite:', error)
    // Handle error (show notification, etc.)
  } finally {
    loading.value = false
  }
}
</script> 