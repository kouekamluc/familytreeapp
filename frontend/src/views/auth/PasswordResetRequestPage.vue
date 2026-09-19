<template>
  <div class="min-h-screen bg-[#0E0F12] text-stone-100 flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-8 font-sans selection:bg-[#C5A059] selection:text-black">
    <div class="sm:mx-auto sm:w-full sm:max-w-md text-center">
      <div class="relative w-20 h-20 mx-auto mb-4 rounded-2xl overflow-hidden border-2 border-[#C5A059] shadow-2xl shadow-black/80 bg-[#0B0C0E] flex items-center justify-center p-1">
        <img
          src="/logo.png"
          alt="KKEVO FAMILY Crest"
          class="w-full h-full object-contain"
        />
      </div>

      <h1 class="text-2xl font-serif font-black tracking-wider uppercase text-transparent bg-clip-text bg-gradient-to-r from-[#F3E5AB] via-[#D4AF37] to-[#C5A059]">
        Reset Password
      </h1>
      <p class="mt-2 text-xs text-stone-400">
        Enter your registered email address to receive your password recovery link.
      </p>
    </div>

    <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
      <div class="bg-[#16181F] py-8 px-6 sm:px-10 rounded-2xl border border-[#C5A059]/40 shadow-2xl shadow-black/80 relative">
        <div class="absolute -top-px left-1/4 right-1/4 h-px bg-gradient-to-r from-transparent via-[#D4AF37] to-transparent"></div>

        <form class="space-y-5" @submit.prevent="handleSubmit">
          <div>
            <label for="email" class="block text-xs font-black uppercase tracking-wider text-[#F3E5AB]">
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
                class="appearance-none block w-full px-4 py-3 bg-[#1F2128] border border-[#C5A059]/40 rounded-xl shadow-inner text-stone-100 placeholder-stone-500 focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37] sm:text-sm transition-colors"
              />
            </div>
            <p v-if="errors.email" class="mt-1 text-xs text-red-400">{{ errors.email }}</p>
          </div>

          <div v-if="authError" class="p-3 bg-red-950/60 border border-red-500/50 rounded-xl text-red-200 text-xs">
            {{ authError }}
          </div>

          <div v-if="successMessage" class="p-3 bg-emerald-950/60 border border-emerald-500/50 rounded-xl text-emerald-200 text-xs">
            {{ successMessage }}
          </div>

          <div>
            <button
              type="submit"
              :disabled="loading"
              class="w-full flex justify-center items-center py-3.5 px-4 rounded-xl shadow-lg font-black text-sm tracking-wide text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-110 focus:outline-none focus:ring-2 focus:ring-[#D4AF37] disabled:opacity-50 transition-all active:scale-[0.99]"
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
              <span>{{ loading ? 'Sending link...' : 'Send Recovery Link' }}</span>
            </button>
          </div>
        </form>

        <div class="mt-6 text-center border-t border-[#C5A059]/20 pt-4">
          <router-link to="/login" class="text-xs font-bold text-[#D4AF37] hover:underline flex items-center justify-center gap-1">
            <span>&larr;</span>
            <span>Back to Family Login</span>
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const form = reactive({
  email: ''
})

const errors = reactive({
  email: ''
})

const loading = ref(false)
const authError = ref('')
const successMessage = ref('')

const handleSubmit = async () => {
  if (!form.email) {
    errors.email = 'Please enter your email'
    return
  }
  loading.value = true
  authError.value = ''
  try {
    if (authStore.requestPasswordReset) {
      await authStore.requestPasswordReset(form.email)
    }
    successMessage.value = 'A password recovery link has been sent to your email.'
    setTimeout(() => {
      router.push('/password-reset/sent')
    }, 1500)
  } catch (err) {
    authError.value = err.message || 'Unable to process reset request.'
  } finally {
    loading.value = false
  }
}
</script>