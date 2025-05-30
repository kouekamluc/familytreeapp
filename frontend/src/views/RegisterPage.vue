<template>
  <div class="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
    <div class="sm:mx-auto sm:w-full sm:max-w-md">
      <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
        Create your account
      </h2>
      <p class="mt-2 text-center text-sm text-gray-600">
        Or
        <router-link to="/login" class="font-medium text-indigo-600 hover:text-indigo-500">
          sign in to your existing account
        </router-link>
      </p>
    </div>

    <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
        <form class="space-y-6" @submit.prevent="handleRegister">
          <div>
            <label for="email" class="block text-sm font-medium text-gray-700">
              Email address
            </label>
            <div class="mt-1">
              <input
                id="email"
                v-model="form.email"
                name="email"
                type="email"
                autocomplete="email"
                required
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              />
            </div>
          </div>

          <div>
            <label for="username" class="block text-sm font-medium text-gray-700">
              Username
            </label>
            <div class="mt-1">
              <input
                id="username"
                v-model="form.username"
                name="username"
                type="text"
                autocomplete="username"
                required
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              />
            </div>
            <p v-if="usernameError" class="mt-2 text-sm text-red-600">
              {{ usernameError }}
            </p>
          </div>

          <div>
            <label for="password" class="block text-sm font-medium text-gray-700">
              Password
            </label>
            <div class="mt-1">
              <input
                id="password"
                v-model="form.password"
                name="password"
                :type="showPassword ? 'text' : 'password'"
                autocomplete="new-password"
                required
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              />
            </div>
            <div class="mt-2">
              <div class="relative pt-1">
                <div class="flex mb-2 items-center justify-between">
                  <div>
                    <span class="text-xs font-semibold inline-block py-1 px-2 uppercase rounded-full" :class="passwordStrengthClass">
                      {{ passwordStrength }}
                    </span>
                  </div>
                </div>
                <div class="overflow-hidden h-2 mb-4 text-xs flex rounded bg-gray-200">
                  <div
                    :style="{ width: passwordStrengthPercentage + '%' }"
                    class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center transition-all duration-500"
                    :class="passwordStrengthBarClass"
                  ></div>
                </div>
              </div>
            </div>
          </div>

          <div>
            <label for="confirmPassword" class="block text-sm font-medium text-gray-700">
              Confirm Password
            </label>
            <div class="mt-1">
              <input
                id="confirmPassword"
                v-model="form.confirmPassword"
                name="confirmPassword"
                :type="showPassword ? 'text' : 'password'"
                autocomplete="new-password"
                required
                class="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              />
            </div>
            <p v-if="passwordMatchError" class="mt-2 text-sm text-red-600">
              {{ passwordMatchError }}
            </p>
          </div>

          <div class="flex items-center">
            <input
              id="terms"
              v-model="form.acceptTerms"
              name="terms"
              type="checkbox"
              required
              class="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
            />
            <label for="terms" class="ml-2 block text-sm text-gray-900">
              I agree to the
              <router-link to="/terms" class="font-medium text-indigo-600 hover:text-indigo-500">Terms of Service</router-link>
              and
              <router-link to="/privacy" class="font-medium text-indigo-600 hover:text-indigo-500">Privacy Policy</router-link>
            </label>
          </div>

          <div>
            <button
              type="submit"
              :disabled="loading || !isFormValid"
              class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
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
              {{ loading ? 'Creating account...' : 'Create account' }}
            </button>
          </div>
        </form>

        <div class="mt-6">
          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <div class="w-full border-t border-gray-300"></div>
            </div>
            <div class="relative flex justify-center text-sm">
              <span class="px-2 bg-white text-gray-500">Or continue with</span>
            </div>
          </div>

          <div class="mt-6 grid grid-cols-2 gap-3">
            <div>
              <button
                @click="handleOAuthRegister('google')"
                class="w-full inline-flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
              >
                <svg class="w-5 h-5" viewBox="0 0 24 24">
                  <path
                    fill="currentColor"
                    d="M12.545,10.239v3.821h5.445c-0.712,2.315-2.647,3.972-5.445,3.972c-3.332,0-6.033-2.701-6.033-6.032s2.701-6.032,6.033-6.032c1.498,0,2.866,0.549,3.921,1.453l2.814-2.814C17.503,2.988,15.139,2,12.545,2C7.021,2,2.543,6.477,2.543,12s4.478,10,10.002,10c8.396,0,10.249-7.85,9.426-11.748L12.545,10.239z"
                  />
                </svg>
                <span class="ml-2">Google</span>
              </button>
            </div>

            <div>
              <button
                @click="handleOAuthRegister('facebook')"
                class="w-full inline-flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
              >
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path
                    d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"
                  />
                </svg>
                <span class="ml-2">Facebook</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const form = ref({
  email: '',
  username: '',
  password: '',
  confirmPassword: '',
  acceptTerms: false
})

const loading = ref(false)
const showPassword = ref(false)
const usernameError = ref('')
const passwordMatchError = ref('')

const passwordStrength = computed(() => {
  const password = form.value.password
  if (!password) return 'No password'
  if (password.length < 8) return 'Too weak'
  if (password.length < 12) return 'Weak'
  if (password.length < 16) return 'Medium'
  return 'Strong'
})

const passwordStrengthPercentage = computed(() => {
  const password = form.value.password
  if (!password) return 0
  if (password.length < 8) return 25
  if (password.length < 12) return 50
  if (password.length < 16) return 75
  return 100
})

const passwordStrengthClass = computed(() => {
  const strength = passwordStrength.value
  switch (strength) {
    case 'Too weak':
      return 'text-red-600 bg-red-100'
    case 'Weak':
      return 'text-orange-600 bg-orange-100'
    case 'Medium':
      return 'text-yellow-600 bg-yellow-100'
    case 'Strong':
      return 'text-green-600 bg-green-100'
    default:
      return 'text-gray-600 bg-gray-100'
  }
})

const passwordStrengthBarClass = computed(() => {
  const strength = passwordStrength.value
  switch (strength) {
    case 'Too weak':
      return 'bg-red-500'
    case 'Weak':
      return 'bg-orange-500'
    case 'Medium':
      return 'bg-yellow-500'
    case 'Strong':
      return 'bg-green-500'
    default:
      return 'bg-gray-500'
  }
})

const isFormValid = computed(() => {
  return (
    form.value.email &&
    form.value.username &&
    form.value.password &&
    form.value.confirmPassword &&
    form.value.acceptTerms &&
    !usernameError.value &&
    !passwordMatchError.value &&
    passwordStrength.value !== 'Too weak'
  )
})

watch(() => form.value.username, async (newUsername) => {
  if (newUsername.length < 3) {
    usernameError.value = 'Username must be at least 3 characters long'
  } else {
    try {
      const isAvailable = await authStore.checkUsernameAvailability(newUsername)
      usernameError.value = isAvailable ? '' : 'Username is already taken'
    } catch (error) {
      console.error('Error checking username:', error)
      usernameError.value = 'Error checking username availability'
    }
  }
})

watch(() => form.value.confirmPassword, (newConfirmPassword) => {
  passwordMatchError.value =
    newConfirmPassword && newConfirmPassword !== form.value.password
      ? 'Passwords do not match'
      : ''
})

const handleRegister = async () => {
  try {
    loading.value = true
    await authStore.register({
      email: form.value.email,
      username: form.value.username,
      password: form.value.password
    })
    router.push('/dashboard')
  } catch (error) {
    console.error('Registration error:', error)
    // Handle error (show notification, etc.)
  } finally {
    loading.value = false
  }
}

const handleOAuthRegister = async (provider) => {
  try {
    loading.value = true
    await authStore.registerWithOAuth(provider)
    router.push('/dashboard')
  } catch (error) {
    console.error('OAuth registration error:', error)
    // Handle error (show notification, etc.)
  } finally {
    loading.value = false
  }
}
</script> 