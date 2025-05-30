<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="md:flex md:items-center md:justify-between">
        <div class="flex-1 min-w-0">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            Share Family Tree
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            Manage who can view and edit your family tree
          </p>
        </div>
        <div class="mt-4 flex md:mt-0 md:ml-4">
          <button
            type="button"
            @click="showInviteModal = true"
            class="ml-3 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <svg class="-ml-1 mr-2 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Invite People
          </button>
        </div>
      </div>

      <!-- Sharing Settings -->
      <div class="mt-8 bg-white shadow overflow-hidden sm:rounded-lg">
        <div class="px-4 py-5 sm:px-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900">
            Sharing Settings
          </h3>
          <p class="mt-1 max-w-2xl text-sm text-gray-500">
            Configure how your family tree can be shared and viewed
          </p>
        </div>
        <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
          <dl class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-2">
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Tree Visibility</dt>
              <dd class="mt-1">
                <select
                  v-model="treeVisibility"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                >
                  <option value="private">Private - Only invited members</option>
                  <option value="family">Family - All family members</option>
                  <option value="public">Public - Anyone with the link</option>
                </select>
              </dd>
            </div>
            <div class="sm:col-span-1">
              <dt class="text-sm font-medium text-gray-500">Default Access Level</dt>
              <dd class="mt-1">
                <select
                  v-model="defaultAccessLevel"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                >
                  <option value="view">View Only</option>
                  <option value="edit">Can Edit</option>
                  <option value="admin">Administrator</option>
                </select>
              </dd>
            </div>
          </dl>
        </div>
      </div>

      <!-- Current Members -->
      <div class="mt-8">
        <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
          Current Members
        </h3>
        <div class="bg-white shadow overflow-hidden sm:rounded-md">
          <ul role="list" class="divide-y divide-gray-200">
            <li v-for="member in members" :key="member.id">
              <div class="px-4 py-4 sm:px-6">
                <div class="flex items-center justify-between">
                  <div class="flex items-center">
                    <img
                      :src="member.avatar"
                      :alt="member.name"
                      class="h-10 w-10 rounded-full"
                    />
                    <div class="ml-4">
                      <p class="text-sm font-medium text-gray-900">
                        {{ member.name }}
                      </p>
                      <p class="text-sm text-gray-500">
                        {{ member.email }}
                      </p>
                    </div>
                  </div>
                  <div class="flex items-center space-x-4">
                    <select
                      v-model="member.accessLevel"
                      class="block w-40 pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
                    >
                      <option value="view">View Only</option>
                      <option value="edit">Can Edit</option>
                      <option value="admin">Administrator</option>
                    </select>
                    <button
                      v-if="!member.isOwner"
                      @click="removeMember(member)"
                      class="text-red-600 hover:text-red-900"
                    >
                      Remove
                    </button>
                  </div>
                </div>
              </div>
            </li>
          </ul>
        </div>
      </div>

      <!-- Pending Invites -->
      <div class="mt-8">
        <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">
          Pending Invites
        </h3>
        <div class="bg-white shadow overflow-hidden sm:rounded-md">
          <ul role="list" class="divide-y divide-gray-200">
            <li v-for="invite in pendingInvites" :key="invite.id">
              <div class="px-4 py-4 sm:px-6">
                <div class="flex items-center justify-between">
                  <div>
                    <p class="text-sm font-medium text-gray-900">
                      {{ invite.email }}
                    </p>
                    <p class="text-sm text-gray-500">
                      Invited {{ invite.invitedAt }}
                    </p>
                  </div>
                  <div class="flex items-center space-x-4">
                    <span class="text-sm text-gray-500">
                      {{ invite.accessLevel }}
                    </span>
                    <button
                      @click="cancelInvite(invite)"
                      class="text-red-600 hover:text-red-900"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              </div>
            </li>
          </ul>
        </div>
      </div>

      <!-- Invite Modal -->
      <div
        v-if="showInviteModal"
        class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center"
      >
        <div class="bg-white rounded-lg max-w-md w-full mx-4 p-6">
          <h3 class="text-lg font-medium text-gray-900 mb-4">
            Invite People
          </h3>
          <div class="space-y-4">
            <div>
              <label for="email" class="block text-sm font-medium text-gray-700">
                Email Address
              </label>
              <input
                type="email"
                v-model="newInvite.email"
                class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                placeholder="Enter email address"
              />
            </div>
            <div>
              <label for="accessLevel" class="block text-sm font-medium text-gray-700">
                Access Level
              </label>
              <select
                v-model="newInvite.accessLevel"
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="view">View Only</option>
                <option value="edit">Can Edit</option>
                <option value="admin">Administrator</option>
              </select>
            </div>
            <div class="mt-5 sm:mt-6 sm:grid sm:grid-cols-2 sm:gap-3 sm:grid-flow-row-dense">
              <button
                type="button"
                @click="sendInvite"
                class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-indigo-600 text-base font-medium text-white hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:col-start-2 sm:text-sm"
              >
                Send Invite
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
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useToast } from 'vue-toastification'

const toast = useToast()
const showInviteModal = ref(false)
const treeVisibility = ref('private')
const defaultAccessLevel = ref('view')

const newInvite = ref({
  email: '',
  accessLevel: 'view'
})

const members = ref([
  {
    id: 1,
    name: 'John Smith',
    email: 'john@example.com',
    avatar: '/avatars/john.jpg',
    accessLevel: 'admin',
    isOwner: true
  },
  {
    id: 2,
    name: 'Sarah Johnson',
    email: 'sarah@example.com',
    avatar: '/avatars/sarah.jpg',
    accessLevel: 'edit',
    isOwner: false
  },
  {
    id: 3,
    name: 'Michael Chen',
    email: 'michael@example.com',
    avatar: '/avatars/michael.jpg',
    accessLevel: 'view',
    isOwner: false
  }
])

const pendingInvites = ref([
  {
    id: 1,
    email: 'emily@example.com',
    accessLevel: 'edit',
    invitedAt: '2 days ago'
  },
  {
    id: 2,
    email: 'david@example.com',
    accessLevel: 'view',
    invitedAt: '1 day ago'
  }
])

const sendInvite = () => {
  // TODO: Implement API call to send invite
  pendingInvites.value.push({
    id: Date.now(),
    email: newInvite.value.email,
    accessLevel: newInvite.value.accessLevel,
    invitedAt: 'Just now'
  })
  showInviteModal.value = false
  newInvite.value = { email: '', accessLevel: 'view' }
  toast.success('Invitation sent successfully')
}

const cancelInvite = (invite) => {
  // TODO: Implement API call to cancel invite
  pendingInvites.value = pendingInvites.value.filter(i => i.id !== invite.id)
  toast.success('Invitation cancelled')
}

const removeMember = (member) => {
  // TODO: Implement API call to remove member
  members.value = members.value.filter(m => m.id !== member.id)
  toast.success('Member removed successfully')
}
</script> 