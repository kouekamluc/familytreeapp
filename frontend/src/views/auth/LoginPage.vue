<template>
  <div class="app-page-shell flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8 font-sans">
    <div class="max-w-md w-full space-y-8 app-card-panel border-2 border-[#C5A059] p-8 rounded-3xl shadow-2xl">
      <div class="text-center">
        <div class="w-24 h-24 mx-auto rounded-2xl border-2 border-[#C5A059] flex items-center justify-center p-2 shadow-xl mb-4 bg-amber-50/20">
          <img src="/logo.png" alt="Kkevo Family Crest" class="w-full h-full object-contain" />
        </div>
        <h2 class="text-2xl font-black text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] font-serif uppercase tracking-wider">
          Kkevo Family
        </h2>
        <p class="mt-1 text-xs font-bold text-[#C5A059] uppercase tracking-widest">
          Royal Heritage & Family Roots
        </p>
        <p class="mt-3 text-xs opacity-80">
          Sign in to view and grow our family lineage
        </p>
      </div>
      <form class="mt-6 space-y-5" @submit.prevent="handleSubmit">
        <div class="space-y-3">
          <div>
            <label for="username" class="block text-xs font-bold text-[#C5A059] mb-1">Username</label>
            <input
              id="username"
              v-model="form.username"
              name="username"
              type="text"
              autocomplete="username"
              required
              class="w-full px-3.5 py-2.5 app-input-theme border rounded-xl text-sm placeholder-stone-400 focus:outline-none focus:ring-2 focus:ring-[#C5A059]"
              :class="{ 'border-red-500': errors.username }"
              placeholder="Enter username"
            />
            <p v-if="errors.username" class="mt-1 text-xs text-red-400">{{ errors.username }}</p>
          </div>
          <div>
            <label for="password" class="block text-xs font-bold text-[#C5A059] mb-1">Password</label>
            <input
              id="password"
              v-model="form.password"
              name="password"
              type="password"
              autocomplete="current-password"
              required
              class="w-full px-3.5 py-2.5 app-input-theme border rounded-xl text-sm placeholder-stone-400 focus:outline-none focus:ring-2 focus:ring-[#C5A059]"
              :class="{ 'border-red-500': errors.password }"
              placeholder="Enter password"
            />
            <p v-if="errors.password" class="mt-1 text-xs text-red-400">{{ errors.password }}</p>
          </div>
        </div>

        <div class="flex items-center justify-between text-xs">
          <div class="flex items-center">
            <input
              id="remember-me"
              v-model="form.rememberMe"
              name="remember-me"
              type="checkbox"
              class="h-4 w-4 text-[#C5A059] focus:ring-[#C5A059] bg-[#1C1E24] border-stone-600 rounded cursor-pointer"
            />
            <label for="remember-me" class="ml-2 block text-stone-300 cursor-pointer">
              Remember me
            </label>
          </div>

          <div>
            <router-link to="/password-reset" class="font-bold text-[#D4AF37] hover:underline">
              Forgot password?
            </router-link>
          </div>
        </div>

        <div class="space-y-3 pt-2">
          <button
            type="submit"
            :disabled="loading"
            class="w-full flex justify-center py-3 px-4 rounded-xl text-sm font-black text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-105 shadow-lg shadow-black/50 transition-all cursor-pointer"
            :class="{ 'opacity-50 cursor-not-allowed': loading }"
          >
            {{ loading ? 'Signing in...' : 'Sign In to Kkevo Family' }}
          </button>

          <!-- Quick 1-Click Demo Login for instant testing -->
          <button
            type="button"
            @click="handleDemoLogin"
            :disabled="loading"
            class="w-full flex items-center justify-center py-2.5 px-4 border border-[#C5A059]/60 rounded-xl text-xs font-black text-[#F3E5AB] bg-[#1C1E24] hover:bg-[#252832] transition-colors shadow-sm cursor-pointer"
          >
            <span class="mr-2">⚡</span>
            <span>Quick Demo Login (testuser)</span>
          </button>
        </div>

        <div v-if="authError" class="rounded-md bg-red-50 p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                <path
                  fill-rule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-red-800">{{ authError }}</h3>
            </div>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const form = reactive({
  username: '',
  password: '',
  rememberMe: false
})

const errors = reactive({
  username: '',
  password: ''
})

const loading = ref(false)
const authError = ref('')

const validateForm = () => {
  let isValid = true
  errors.username = ''
  errors.password = ''

  if (!form.username) {
    errors.username = 'Username is required'
    isValid = false
  }

  if (!form.password) {
    errors.password = 'Password is required'
    isValid = false
  } else if (form.password.length < 8) {
    errors.password = 'Password must be at least 8 characters'
    isValid = false
  }

  return isValid
}

const handleSubmit = async () => {
  if (!validateForm()) return

  loading.value = true
  authError.value = ''

  try {
    const success = await authStore.login({
      username: form.username,
      password: form.password
    })

    if (success) {
      const redirectPath = route.query.redirect || '/dashboard'
      router.push(redirectPath)
    } else {
      authError.value = authStore.error || 'Invalid username or password'
    }
  } catch (error) {
    authError.value = error.response?.data?.error || error.response?.data?.detail || 'Invalid username or password'
  } finally {
    loading.value = false
  }
}

const handleDemoLogin = async () => {
  form.username = 'testuser'
  form.password = 'password123'
  loading.value = true
  authError.value = ''
  try {
    const success = await authStore.login({
      username: 'testuser',
      password: 'password123'
    })
    if (success) {
      const redirectPath = route.query.redirect || '/dashboard'
      router.push(redirectPath)
    }
  } catch (error) {
    authError.value = error.response?.data?.error || 'Failed to sign in with demo account'
  } finally {
    loading.value = false
  }
}
</script> 