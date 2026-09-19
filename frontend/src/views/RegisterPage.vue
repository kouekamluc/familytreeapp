<template>
  <div class="app-page-shell flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-8 font-sans">
    <!-- Centered Logo and Brand Header -->
    <div class="sm:mx-auto sm:w-full sm:max-w-md text-center">
      <div class="relative w-20 h-20 mx-auto mb-4 rounded-2xl overflow-hidden border-2 border-[#C5A059] shadow-2xl bg-amber-50/20 flex items-center justify-center p-1">
        <img
          src="/logo.png"
          alt="KKEVO FAMILY Crest"
          class="w-full h-full object-contain"
        />
      </div>

      <h1 class="text-2xl sm:text-3xl font-serif font-black tracking-wider uppercase text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059]">
        KKEVO FAMILY
      </h1>
      <p class="text-xs font-bold text-[#C5A059] uppercase tracking-widest mt-1">
        Create Your Family Account
      </p>
      <p class="mt-2 text-sm opacity-80">
        Already registered?
        <router-link to="/login" class="font-bold text-[#B8860B] hover:underline ml-1">
          Sign In Here
        </router-link>
      </p>
    </div>

    <!-- Registration Card -->
    <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <div class="app-card-panel py-8 px-6 sm:px-10 rounded-3xl border-2 border-[#C5A059] shadow-2xl relative">
        <!-- Ambient subtle gold border glow -->
        <div class="absolute -top-px left-1/4 right-1/4 h-px bg-gradient-to-r from-transparent via-[#D4AF37] to-transparent"></div>

        <form class="space-y-5" @submit.prevent="handleRegister">
          <!-- Full Name or Username -->
          <div>
            <label for="username" class="block text-xs font-bold uppercase tracking-wider text-[#C5A059]">
              Username
            </label>
            <div class="mt-1.5">
              <input
                id="username"
                v-model="form.username"
                name="username"
                type="text"
                autocomplete="username"
                required
                placeholder="e.g. kouekamluc"
                class="appearance-none block w-full px-4 py-3 app-input-theme border rounded-xl shadow-inner placeholder-stone-400 focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37] sm:text-sm transition-colors"
              />
            </div>
            <p v-if="usernameError" class="mt-1.5 text-xs text-red-400 font-medium">
              {{ usernameError }}
            </p>
          </div>

          <!-- Email -->
          <div>
            <label for="email" class="block text-xs font-bold uppercase tracking-wider text-[#C5A059]">
              Email Address
            </label>
            <div class="mt-1.5">
              <input
                id="email"
                v-model="form.email"
                name="email"
                type="email"
                autocomplete="email"
                required
                placeholder="you@family.org"
                class="appearance-none block w-full px-4 py-3 app-input-theme border rounded-xl shadow-inner placeholder-stone-400 focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37] sm:text-sm transition-colors"
              />
            </div>
          </div>

          <!-- Password -->
          <div>
            <div class="flex items-center justify-between">
              <label for="password" class="block text-xs font-bold uppercase tracking-wider text-[#C5A059]">
                Password
              </label>
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="text-xs text-[#B8860B] hover:underline cursor-pointer"
              >
                {{ showPassword ? 'Hide' : 'Show' }}
              </button>
            </div>
            <div class="mt-1.5">
              <input
                id="password"
                v-model="form.password"
                name="password"
                :type="showPassword ? 'text' : 'password'"
                autocomplete="new-password"
                required
                placeholder="••••••••"
                class="appearance-none block w-full px-4 py-3 app-input-theme border rounded-xl shadow-inner placeholder-stone-400 focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37] sm:text-sm transition-colors"
              />
            </div>

            <!-- Password strength indicator -->
            <div v-if="form.password" class="mt-2">
              <div class="flex justify-between items-center text-[10px] opacity-70 mb-1">
                <span>Strength: <strong :class="passwordStrengthColor">{{ passwordStrength }}</strong></span>
                <span>{{ passwordStrengthPercentage }}%</span>
              </div>
              <div class="w-full bg-stone-200 dark:bg-[#121316] rounded-full h-1.5 overflow-hidden border border-[#C5A059]/20">
                <div
                  class="h-full transition-all duration-300 rounded-full"
                  :class="passwordStrengthBarColor"
                  :style="{ width: `${passwordStrengthPercentage}%` }"
                ></div>
              </div>
            </div>
          </div>

          <!-- Confirm Password -->
          <div>
            <label for="confirmPassword" class="block text-xs font-bold uppercase tracking-wider text-[#C5A059]">
              Confirm Password
            </label>
            <div class="mt-1.5">
              <input
                id="confirmPassword"
                v-model="form.confirmPassword"
                name="confirmPassword"
                :type="showPassword ? 'text' : 'password'"
                autocomplete="new-password"
                required
                placeholder="••••••••"
                class="appearance-none block w-full px-4 py-3 app-input-theme border rounded-xl shadow-inner placeholder-stone-400 focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37] sm:text-sm transition-colors"
              />
            </div>
            <p v-if="passwordMatchError" class="mt-1.5 text-xs text-red-400 font-medium">
              {{ passwordMatchError }}
            </p>
          </div>

          <!-- Terms acceptance with working links -->
          <div class="flex items-start gap-2 pt-1">
            <input
              id="terms"
              v-model="form.acceptTerms"
              name="terms"
              type="checkbox"
              required
              class="mt-1 h-4 w-4 rounded text-[#B8860B] focus:ring-[#C5A059]"
            />
            <label for="terms" class="text-xs opacity-80 leading-normal">
              I agree to the
              <router-link to="/help/terms" class="font-bold text-[#B8860B] hover:underline">
                Terms of Service
              </router-link>
              and
              <router-link to="/help/privacy" class="font-bold text-[#B8860B] hover:underline">
                Privacy Policy
              </router-link>
            </label>
          </div>

          <!-- Error Alert -->
          <div v-if="registrationError" class="p-3 bg-red-500/10 border border-red-500/50 rounded-xl text-red-500 text-xs">
            {{ registrationError }}
          </div>

          <!-- Submit Button -->
          <div class="pt-2">
            <button
              type="submit"
              :disabled="loading || !isFormValid"
              class="w-full flex justify-center items-center py-3.5 px-4 rounded-xl shadow-lg font-black text-sm tracking-wide text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-110 focus:outline-none focus:ring-2 focus:ring-[#D4AF37] disabled:opacity-50 disabled:cursor-not-allowed transition-all active:scale-[0.99] cursor-pointer"
            >
              <svg
                v-if="loading"
                class="animate-spin -ml-1 mr-3 h-5 w-5 text-black"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <span>{{ loading ? 'Creating Account...' : 'Create Family Account' }}</span>
            </button>
          </div>
        </form>

        <!-- Back to Home link -->
        <div class="mt-6 text-center border-t border-[#C5A059]/20 pt-4">
          <router-link to="/" class="text-xs font-bold opacity-70 hover:opacity-100 flex items-center justify-center gap-1">
            <span>&larr;</span>
            <span>Return to Kkevo Welcome Page</span>
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
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
const registrationError = ref('')

const usernameError = computed(() => {
  if (!form.value.username) return ''
  if (form.value.username.length < 3) return 'Username must be at least 3 characters'
  return ''
})

const passwordMatchError = computed(() => {
  if (!form.value.confirmPassword) return ''
  if (form.value.password !== form.value.confirmPassword) {
    return 'Passwords do not match'
  }
  return ''
})

const passwordStrengthPercentage = computed(() => {
  const p = form.value.password
  if (!p) return 0
  let score = 0
  if (p.length >= 6) score += 25
  if (p.length >= 8) score += 25
  if (/[0-9]/.test(p)) score += 25
  if (/[^A-Za-z0-9]/.test(p)) score += 25
  return Math.min(score, 100)
})

const passwordStrength = computed(() => {
  const pct = passwordStrengthPercentage.value
  if (pct === 0) return 'None'
  if (pct < 50) return 'Weak'
  if (pct < 75) return 'Good'
  return 'Strong'
})

const passwordStrengthColor = computed(() => {
  const pct = passwordStrengthPercentage.value
  if (pct < 50) return 'text-amber-400'
  if (pct < 75) return 'text-yellow-400'
  return 'text-emerald-400'
})

const passwordStrengthBarColor = computed(() => {
  const pct = passwordStrengthPercentage.value
  if (pct < 50) return 'bg-amber-500'
  if (pct < 75) return 'bg-yellow-500'
  return 'bg-emerald-500'
})

const isFormValid = computed(() => {
  return (
    form.value.username.length >= 3 &&
    form.value.email.includes('@') &&
    form.value.password.length >= 6 &&
    form.value.password === form.value.confirmPassword &&
    form.value.acceptTerms
  )
})

const handleRegister = async () => {
  if (!isFormValid.value) return
  loading.value = true
  registrationError.value = ''

  try {
    const success = await authStore.register({
      username: form.value.username,
      email: form.value.email,
      password: form.value.password
    })

    if (success) {
      router.push('/tree')
    } else {
      registrationError.value = authStore.error || 'Registration failed. Please try again.'
    }
  } catch (err) {
    registrationError.value = err.message || 'An unexpected error occurred during registration.'
  } finally {
    loading.value = false
  }
}
</script>