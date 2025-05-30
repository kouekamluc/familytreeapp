<template>
  <div class="min-h-screen bg-gray-100 py-6">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="mb-8">
        <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
          Settings
        </h2>
        <p class="mt-1 text-sm text-gray-500">
          Manage your account and application preferences
        </p>
      </div>

      <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <!-- Navigation -->
        <div class="lg:col-span-1">
          <nav class="space-y-1">
            <button
              v-for="section in sections"
              :key="section.id"
              @click="activeSection = section.id"
              class="w-full flex items-center px-3 py-2 text-sm font-medium rounded-md"
              :class="[
                activeSection === section.id
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-gray-900 hover:bg-gray-50'
              ]"
            >
              <component
                :is="section.icon"
                class="mr-3 h-5 w-5"
                :class="[
                  activeSection === section.id
                    ? 'text-indigo-500'
                    : 'text-gray-400'
                ]"
              />
              {{ section.name }}
            </button>
          </nav>
        </div>

        <!-- Content -->
        <div class="lg:col-span-2">
          <div class="bg-white shadow rounded-lg">
            <!-- Profile Settings -->
            <div v-if="activeSection === 'profile'" class="p-6">
              <h3 class="text-lg font-medium text-gray-900 mb-6">Profile Settings</h3>
              <form @submit.prevent="saveProfile" class="space-y-6">
                <div>
                  <label class="block text-sm font-medium text-gray-700">Profile Picture</label>
                  <div class="mt-2 flex items-center space-x-5">
                    <img
                      :src="profile.avatar"
                      alt="Profile"
                      class="h-16 w-16 rounded-full"
                    />
                    <button
                      type="button"
                      class="px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    >
                      Change
                    </button>
                  </div>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700">Name</label>
                  <input
                    v-model="profile.name"
                    type="text"
                    class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700">Email</label>
                  <input
                    v-model="profile.email"
                    type="email"
                    class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700">Bio</label>
                  <textarea
                    v-model="profile.bio"
                    rows="3"
                    class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                  ></textarea>
                </div>

                <div class="flex justify-end">
                  <button
                    type="submit"
                    class="px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    Save Changes
                  </button>
                </div>
              </form>
            </div>

            <!-- Privacy Settings -->
            <div v-if="activeSection === 'privacy'" class="p-6">
              <h3 class="text-lg font-medium text-gray-900 mb-6">Privacy Settings</h3>
              <div class="space-y-6">
                <div>
                  <h4 class="text-sm font-medium text-gray-900">Profile Visibility</h4>
                  <div class="mt-2 space-y-4">
                    <div class="flex items-center">
                      <input
                        v-model="privacy.profileVisibility"
                        type="radio"
                        value="public"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <label class="ml-3 block text-sm text-gray-700">
                        Public - Anyone can view your profile
                      </label>
                    </div>
                    <div class="flex items-center">
                      <input
                        v-model="privacy.profileVisibility"
                        type="radio"
                        value="family"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <label class="ml-3 block text-sm text-gray-700">
                        Family Only - Only family members can view your profile
                      </label>
                    </div>
                    <div class="flex items-center">
                      <input
                        v-model="privacy.profileVisibility"
                        type="radio"
                        value="private"
                        class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300"
                      />
                      <label class="ml-3 block text-sm text-gray-700">
                        Private - Only you can view your profile
                      </label>
                    </div>
                  </div>
                </div>

                <div>
                  <h4 class="text-sm font-medium text-gray-900">Data Sharing</h4>
                  <div class="mt-2 space-y-4">
                    <div class="flex items-start">
                      <div class="flex items-center h-5">
                        <input
                          v-model="privacy.shareWithFamily"
                          type="checkbox"
                          class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                        />
                      </div>
                      <div class="ml-3 text-sm">
                        <label class="font-medium text-gray-700">Share with Family</label>
                        <p class="text-gray-500">Allow family members to view your family tree data</p>
                      </div>
                    </div>
                    <div class="flex items-start">
                      <div class="flex items-center h-5">
                        <input
                          v-model="privacy.allowSearch"
                          type="checkbox"
                          class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                        />
                      </div>
                      <div class="ml-3 text-sm">
                        <label class="font-medium text-gray-700">Allow Search</label>
                        <p class="text-gray-500">Let others find your profile in search results</p>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="flex justify-end">
                  <button
                    @click="savePrivacy"
                    class="px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    Save Changes
                  </button>
                </div>
              </div>
            </div>

            <!-- Notification Settings -->
            <div v-if="activeSection === 'notifications'" class="p-6">
              <h3 class="text-lg font-medium text-gray-900 mb-6">Notification Settings</h3>
              <div class="space-y-6">
                <div>
                  <h4 class="text-sm font-medium text-gray-900">Email Notifications</h4>
                  <div class="mt-2 space-y-4">
                    <div class="flex items-start">
                      <div class="flex items-center h-5">
                        <input
                          v-model="notifications.emailUpdates"
                          type="checkbox"
                          class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                        />
                      </div>
                      <div class="ml-3 text-sm">
                        <label class="font-medium text-gray-700">Family Tree Updates</label>
                        <p class="text-gray-500">Receive email notifications when your family tree is updated</p>
                      </div>
                    </div>
                    <div class="flex items-start">
                      <div class="flex items-center h-5">
                        <input
                          v-model="notifications.emailMessages"
                          type="checkbox"
                          class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                        />
                      </div>
                      <div class="ml-3 text-sm">
                        <label class="font-medium text-gray-700">Messages</label>
                        <p class="text-gray-500">Receive email notifications for new messages</p>
                      </div>
                    </div>
                  </div>
                </div>

                <div>
                  <h4 class="text-sm font-medium text-gray-900">Push Notifications</h4>
                  <div class="mt-2 space-y-4">
                    <div class="flex items-start">
                      <div class="flex items-center h-5">
                        <input
                          v-model="notifications.pushUpdates"
                          type="checkbox"
                          class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                        />
                      </div>
                      <div class="ml-3 text-sm">
                        <label class="font-medium text-gray-700">Family Tree Updates</label>
                        <p class="text-gray-500">Receive push notifications when your family tree is updated</p>
                      </div>
                    </div>
                    <div class="flex items-start">
                      <div class="flex items-center h-5">
                        <input
                          v-model="notifications.pushMessages"
                          type="checkbox"
                          class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                        />
                      </div>
                      <div class="ml-3 text-sm">
                        <label class="font-medium text-gray-700">Messages</label>
                        <p class="text-gray-500">Receive push notifications for new messages</p>
                      </div>
                    </div>
                  </div>
                </div>

                <div class="flex justify-end">
                  <button
                    @click="saveNotifications"
                    class="px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    Save Changes
                  </button>
                </div>
              </div>
            </div>

            <!-- Account Settings -->
            <div v-if="activeSection === 'account'" class="p-6">
              <h3 class="text-lg font-medium text-gray-900 mb-6">Account Settings</h3>
              <div class="space-y-6">
                <div>
                  <h4 class="text-sm font-medium text-gray-900">Change Password</h4>
                  <div class="mt-2 space-y-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700">Current Password</label>
                      <input
                        v-model="account.currentPassword"
                        type="password"
                        class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700">New Password</label>
                      <input
                        v-model="account.newPassword"
                        type="password"
                        class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700">Confirm New Password</label>
                      <input
                        v-model="account.confirmPassword"
                        type="password"
                        class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                      />
                    </div>
                  </div>
                </div>

                <div>
                  <h4 class="text-sm font-medium text-gray-900">Delete Account</h4>
                  <div class="mt-2">
                    <p class="text-sm text-gray-500">
                      Once you delete your account, there is no going back. Please be certain.
                    </p>
                    <button
                      @click="deleteAccount"
                      class="mt-4 px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                    >
                      Delete Account
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const activeSection = ref('profile')

const sections = [
  {
    id: 'profile',
    name: 'Profile',
    icon: 'UserIcon'
  },
  {
    id: 'privacy',
    name: 'Privacy',
    icon: 'ShieldCheckIcon'
  },
  {
    id: 'notifications',
    name: 'Notifications',
    icon: 'BellIcon'
  },
  {
    id: 'account',
    name: 'Account',
    icon: 'CogIcon'
  }
]

const profile = ref({
  avatar: '/avatars/default.jpg',
  name: 'John Smith',
  email: 'john@example.com',
  bio: 'Family history enthusiast'
})

const privacy = ref({
  profileVisibility: 'family',
  shareWithFamily: true,
  allowSearch: false
})

const notifications = ref({
  emailUpdates: true,
  emailMessages: true,
  pushUpdates: true,
  pushMessages: false
})

const account = ref({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const saveProfile = async () => {
  try {
    // TODO: Implement profile save logic
    console.log('Saving profile:', profile.value)
  } catch (error) {
    console.error('Error saving profile:', error)
  }
}

const savePrivacy = async () => {
  try {
    // TODO: Implement privacy settings save logic
    console.log('Saving privacy settings:', privacy.value)
  } catch (error) {
    console.error('Error saving privacy settings:', error)
  }
}

const saveNotifications = async () => {
  try {
    // TODO: Implement notification settings save logic
    console.log('Saving notification settings:', notifications.value)
  } catch (error) {
    console.error('Error saving notification settings:', error)
  }
}

const deleteAccount = async () => {
  if (confirm('Are you sure you want to delete your account? This action cannot be undone.')) {
    try {
      // TODO: Implement account deletion logic
      console.log('Deleting account')
      router.push('/')
    } catch (error) {
      console.error('Error deleting account:', error)
    }
  }
}
</script> 