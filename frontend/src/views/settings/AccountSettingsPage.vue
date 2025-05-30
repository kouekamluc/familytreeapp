<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="md:flex md:items-center md:justify-between">
        <div class="flex-1 min-w-0">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            Account Settings
          </h2>
          <p class="mt-1 text-sm text-gray-500">
            Manage your account information and preferences
          </p>
        </div>
        <div class="mt-4 flex md:mt-0 md:ml-4">
          <button
            type="button"
            @click="saveChanges"
            class="ml-3 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Save Changes
          </button>
        </div>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 lg:grid-cols-3">
        <!-- Main Content -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Profile Information -->
          <div class="bg-white shadow overflow-hidden sm:rounded-lg">
            <div class="px-4 py-5 sm:px-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Profile Information
              </h3>
            </div>
            <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
              <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
                <div class="sm:col-span-3">
                  <label for="firstName" class="block text-sm font-medium text-gray-700">
                    First name
                  </label>
                  <div class="mt-1">
                    <input
                      type="text"
                      id="firstName"
                      v-model="profile.firstName"
                      class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                  </div>
                </div>

                <div class="sm:col-span-3">
                  <label for="lastName" class="block text-sm font-medium text-gray-700">
                    Last name
                  </label>
                  <div class="mt-1">
                    <input
                      type="text"
                      id="lastName"
                      v-model="profile.lastName"
                      class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                  </div>
                </div>

                <div class="sm:col-span-4">
                  <label for="email" class="block text-sm font-medium text-gray-700">
                    Email address
                  </label>
                  <div class="mt-1">
                    <input
                      type="email"
                      id="email"
                      v-model="profile.email"
                      class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                  </div>
                </div>

                <div class="sm:col-span-6">
                  <label for="bio" class="block text-sm font-medium text-gray-700">
                    Bio
                  </label>
                  <div class="mt-1">
                    <textarea
                      id="bio"
                      v-model="profile.bio"
                      rows="3"
                      class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                  </div>
                  <p class="mt-2 text-sm text-gray-500">
                    Brief description for your profile.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <!-- Password -->
          <div class="bg-white shadow overflow-hidden sm:rounded-lg">
            <div class="px-4 py-5 sm:px-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Change Password
              </h3>
            </div>
            <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
              <div class="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6">
                <div class="sm:col-span-4">
                  <label for="currentPassword" class="block text-sm font-medium text-gray-700">
                    Current password
                  </label>
                  <div class="mt-1">
                    <input
                      type="password"
                      id="currentPassword"
                      v-model="password.current"
                      class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                  </div>
                </div>

                <div class="sm:col-span-4">
                  <label for="newPassword" class="block text-sm font-medium text-gray-700">
                    New password
                  </label>
                  <div class="mt-1">
                    <input
                      type="password"
                      id="newPassword"
                      v-model="password.new"
                      class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                  </div>
                </div>

                <div class="sm:col-span-4">
                  <label for="confirmPassword" class="block text-sm font-medium text-gray-700">
                    Confirm new password
                  </label>
                  <div class="mt-1">
                    <input
                      type="password"
                      id="confirmPassword"
                      v-model="password.confirm"
                      class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Notification Preferences -->
          <div class="bg-white shadow overflow-hidden sm:rounded-lg">
            <div class="px-4 py-5 sm:px-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Notification Preferences
              </h3>
            </div>
            <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
              <div class="space-y-4">
                <div class="flex items-start">
                  <div class="flex items-center h-5">
                    <input
                      id="emailNotifications"
                      v-model="notifications.email"
                      type="checkbox"
                      class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                    />
                  </div>
                  <div class="ml-3 text-sm">
                    <label for="emailNotifications" class="font-medium text-gray-700">
                      Email notifications
                    </label>
                    <p class="text-gray-500">
                      Receive email notifications about family tree updates and activity
                    </p>
                  </div>
                </div>

                <div class="flex items-start">
                  <div class="flex items-center h-5">
                    <input
                      id="treeInvites"
                      v-model="notifications.treeInvites"
                      type="checkbox"
                      class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                    />
                  </div>
                  <div class="ml-3 text-sm">
                    <label for="treeInvites" class="font-medium text-gray-700">
                      Tree invites
                    </label>
                    <p class="text-gray-500">
                      Get notified when someone invites you to join their family tree
                    </p>
                  </div>
                </div>

                <div class="flex items-start">
                  <div class="flex items-center h-5">
                    <input
                      id="profileUpdates"
                      v-model="notifications.profileUpdates"
                      type="checkbox"
                      class="focus:ring-indigo-500 h-4 w-4 text-indigo-600 border-gray-300 rounded"
                    />
                  </div>
                  <div class="ml-3 text-sm">
                    <label for="profileUpdates" class="font-medium text-gray-700">
                      Profile updates
                    </label>
                    <p class="text-gray-500">
                      Receive notifications when someone updates your profile information
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Sidebar -->
        <div class="lg:col-span-1 space-y-6">
          <!-- Profile Photo -->
          <div class="bg-white shadow overflow-hidden sm:rounded-lg">
            <div class="px-4 py-5 sm:px-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Profile Photo
              </h3>
            </div>
            <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
              <div class="flex items-center">
                <div class="flex-shrink-0 h-20 w-20">
                  <img
                    v-if="profile.photo"
                    :src="profile.photo"
                    :alt="`${profile.firstName} ${profile.lastName}`"
                    class="h-20 w-20 rounded-full object-cover"
                  />
                  <div
                    v-else
                    class="h-20 w-20 rounded-full bg-gray-200 flex items-center justify-center"
                  >
                    <svg
                      class="h-10 w-10 text-gray-400"
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
                  </div>
                </div>
                <div class="ml-5">
                  <label
                    for="photo-upload"
                    class="cursor-pointer inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    Change photo
                    <input
                      id="photo-upload"
                      type="file"
                      class="hidden"
                      accept="image/*"
                      @change="handlePhotoUpload"
                    />
                  </label>
                  <button
                    v-if="profile.photo"
                    type="button"
                    @click="removePhoto"
                    class="ml-3 inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    Remove
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Danger Zone -->
          <div class="bg-white shadow overflow-hidden sm:rounded-lg">
            <div class="px-4 py-5 sm:px-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Danger Zone
              </h3>
            </div>
            <div class="border-t border-gray-200 px-4 py-5 sm:px-6">
              <button
                type="button"
                @click="showDeleteModal = true"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
              >
                Delete Account
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Delete Account Modal -->
    <div v-if="showDeleteModal" class="fixed z-10 inset-0 overflow-y-auto">
      <div class="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity" aria-hidden="true">
          <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
        </div>

        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>

        <div class="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
          <div class="sm:flex sm:items-start">
            <div class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10">
              <svg
                class="h-6 w-6 text-red-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                />
              </svg>
            </div>
            <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
              <h3 class="text-lg leading-6 font-medium text-gray-900">
                Delete Account
              </h3>
              <div class="mt-2">
                <p class="text-sm text-gray-500">
                  Are you sure you want to delete your account? This action cannot be undone.
                </p>
              </div>
            </div>
          </div>
          <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
            <button
              type="button"
              @click="deleteAccount"
              class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm"
            >
              Delete
            </button>
            <button
              type="button"
              @click="showDeleteModal = false"
              class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm"
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
import { useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'

const router = useRouter()
const toast = useToast()

const profile = ref({
  firstName: 'John',
  lastName: 'Smith',
  email: 'john.smith@example.com',
  bio: 'Family history enthusiast',
  photo: null
})

const password = ref({
  current: '',
  new: '',
  confirm: ''
})

const notifications = ref({
  email: true,
  treeInvites: true,
  profileUpdates: true
})

const showDeleteModal = ref(false)

const handlePhotoUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    const reader = new FileReader()
    reader.onload = (e) => {
      profile.value.photo = e.target.result
    }
    reader.readAsDataURL(file)
  }
}

const removePhoto = () => {
  profile.value.photo = null
}

const saveChanges = async () => {
  try {
    // TODO: Implement API call to save changes
    await new Promise(resolve => setTimeout(resolve, 1000))
    toast.success('Changes saved successfully')
  } catch (error) {
    toast.error('Failed to save changes')
    console.error('Error saving changes:', error)
  }
}

const deleteAccount = async () => {
  try {
    // TODO: Implement API call to delete account
    await new Promise(resolve => setTimeout(resolve, 1000))
    toast.success('Account deleted successfully')
    router.push('/')
  } catch (error) {
    toast.error('Failed to delete account')
    console.error('Error deleting account:', error)
  }
}
</script> 