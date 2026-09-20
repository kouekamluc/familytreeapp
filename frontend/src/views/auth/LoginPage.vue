<template>
  <div class="app-page-shell flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8 font-sans">
    <div class="max-w-md w-full space-y-6 app-card-panel border-2 border-[#C5A059] p-8 rounded-3xl shadow-2xl relative overflow-hidden">
      <!-- Top Decorative Gold Accent Line -->
      <div class="absolute top-0 left-0 right-0 h-1.5 bg-gradient-to-r from-[#B8860B] via-[#FFD700] to-[#C5A059]"></div>

      <div class="text-center">
        <div class="w-24 h-24 mx-auto rounded-2xl border-2 border-[#C5A059] flex items-center justify-center p-2 shadow-xl mb-4 bg-amber-50/20 relative group">
          <img src="/logo.png" alt="Kkevo Family Crest" class="w-full h-full object-contain transition-transform duration-300 group-hover:scale-105" />
          <div class="absolute -bottom-2 bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black text-[10px] font-black px-2 py-0.5 rounded-full uppercase tracking-wider shadow">
            Dynasty
          </div>
        </div>
        <h2 class="text-2xl font-black text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] font-serif uppercase tracking-wider">
          Kkevo Family
        </h2>
        <p class="mt-1 text-xs font-bold text-[#C5A059] uppercase tracking-widest">
          Royal Heritage & Family Roots
        </p>
        <p class="mt-2 text-xs opacity-80">
          Sign in to unlock and explore the sacred lineage archive
        </p>
      </div>

      <!-- Login Method Switcher Tabs -->
      <div class="flex p-1 bg-[#15171E] border border-[#C5A059]/40 rounded-2xl">
        <button
          type="button"
          @click="activeTab = 'heritage_key'"
          class="flex-1 py-2.5 px-3 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer"
          :class="activeTab === 'heritage_key' ? 'bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] text-black shadow-md' : 'text-stone-300 hover:text-[#C5A059]'"
        >
          <span>🔑</span>
          <span>Heritage Key</span>
          <span v-if="activeTab === 'heritage_key'" class="w-1.5 h-1.5 rounded-full bg-black ml-1"></span>
        </button>
        <button
          type="button"
          @click="activeTab = 'credentials'"
          class="flex-1 py-2.5 px-3 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer"
          :class="activeTab === 'credentials' ? 'bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] text-black shadow-md' : 'text-stone-300 hover:text-[#C5A059]'"
        >
          <span>👤</span>
          <span>Password</span>
        </button>
      </div>

      <!-- TAB 1: SIGN IN WITH HERITAGE KEY -->
      <form v-if="activeTab === 'heritage_key'" class="space-y-5" @submit.prevent="handleHeritageKeySubmit">
        <div class="space-y-2">
          <div class="flex items-center justify-between">
            <label for="heritage-key" class="block text-xs font-bold text-[#C5A059]">
              Sacred Heritage Passkey
            </label>
            <button
              type="button"
              @click="pasteKeyFromClipboard"
              class="text-[11px] text-[#D4AF37] hover:underline flex items-center gap-1 font-semibold"
            >
              <span>📋</span> Paste Key
            </button>
          </div>

          <div class="relative">
            <input
              id="heritage-key"
              v-model="heritageKeyInput"
              type="text"
              required
              class="w-full px-3.5 py-3 app-input-theme border-2 border-[#C5A059]/60 rounded-xl text-sm font-mono tracking-wider uppercase placeholder-stone-500 focus:outline-none focus:ring-2 focus:ring-[#C5A059] focus:border-[#C5A059]"
              :class="{ 'border-red-500': errors.heritageKey }"
              placeholder="e.g. KKEVO-ROYAL-2026-ROOT"
            />
            <button
              v-if="heritageKeyInput"
              type="button"
              @click="heritageKeyInput = ''"
              class="absolute right-3 top-3 text-xs text-stone-400 hover:text-stone-200"
            >
              ✕
            </button>
          </div>
          <p v-if="errors.heritageKey" class="text-xs text-red-400 mt-1">{{ errors.heritageKey }}</p>
          <p class="text-[11px] opacity-70">
            Enter your personal lineage key to authenticate securely without a password.
          </p>
        </div>

        <!-- Quick 1-Click Preset Heritage Keys for Demo/Testing -->
        <div class="pt-1">
          <p class="text-[11px] font-bold text-[#C5A059] uppercase tracking-wider mb-2">
            ✨ Quick Access Keys
          </p>
          <div class="flex flex-col gap-2">
            <button
              type="button"
              @click="applyHeritageKey('KKEVO-ROYAL-2026-ROOT')"
              class="w-full text-left py-2 px-3 rounded-xl text-xs border border-[#C5A059]/40 bg-[#1C1E24] hover:bg-[#282B37] transition-all flex items-center justify-between group"
            >
              <div class="flex items-center gap-2">
                <span class="text-base">👑</span>
                <div>
                  <div class="font-bold text-[#F3E5AB]">Curator Royal Passkey</div>
                  <div class="font-mono text-[10px] text-stone-400">KKEVO-ROYAL-2026-ROOT</div>
                </div>
              </div>
              <span class="text-[10px] font-bold text-[#C5A059] group-hover:translate-x-0.5 transition-transform">Use ➔</span>
            </button>

            <button
              type="button"
              @click="applyHeritageKey('KKEVO-ELDER-7777')"
              class="w-full text-left py-2 px-3 rounded-xl text-xs border border-[#C5A059]/40 bg-[#1C1E24] hover:bg-[#282B37] transition-all flex items-center justify-between group"
            >
              <div class="flex items-center gap-2">
                <span class="text-base">🏛️</span>
                <div>
                  <div class="font-bold text-[#F3E5AB]">Elder Patriarch Key</div>
                  <div class="font-mono text-[10px] text-stone-400">KKEVO-ELDER-7777</div>
                </div>
              </div>
              <span class="text-[10px] font-bold text-[#C5A059] group-hover:translate-x-0.5 transition-transform">Use ➔</span>
            </button>
          </div>
        </div>

        <!-- Submit Button for Heritage Key -->
        <div class="pt-2">
          <button
            type="submit"
            :disabled="loading"
            class="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl text-sm font-black text-black bg-gradient-to-r from-[#B8860B] via-[#FFD700] to-[#C5A059] hover:brightness-105 shadow-lg shadow-black/50 transition-all cursor-pointer"
            :class="{ 'opacity-50 cursor-not-allowed': loading }"
          >
            <span v-if="!loading">🔑</span>
            <span v-if="loading" class="animate-spin">⏳</span>
            <span>{{ loading ? 'Unlocking Sacred Vault...' : 'Unlock Vault with Heritage Key' }}</span>
          </button>
        </div>

        <!-- Error Alert -->
        <div v-if="authError" class="rounded-xl bg-red-900/30 border border-red-500/50 p-3.5">
          <div class="flex items-start gap-2.5">
            <span class="text-red-400 text-base">⚠️</span>
            <div class="text-xs text-red-300 font-medium leading-relaxed">{{ authError }}</div>
          </div>
        </div>
      </form>

      <!-- TAB 2: SIGN IN WITH USERNAME & PASSWORD -->
      <form v-else class="space-y-5" @submit.prevent="handleSubmit">
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

          <!-- Quick 1-Click Demo Login -->
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

        <div v-if="authError" class="rounded-xl bg-red-900/30 border border-red-500/50 p-3.5">
          <div class="flex items-start gap-2.5">
            <span class="text-red-400 text-base">⚠️</span>
            <div class="text-xs text-red-300 font-medium leading-relaxed">{{ authError }}</div>
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

const activeTab = ref('heritage_key')
const heritageKeyInput = ref('KKEVO-ROYAL-2026-ROOT')

const form = reactive({
  username: '',
  password: '',
  rememberMe: false
})

const errors = reactive({
  username: '',
  password: '',
  heritageKey: ''
})

const loading = ref(false)
const authError = ref('')

const applyHeritageKey = (key) => {
  heritageKeyInput.value = key
  errors.heritageKey = ''
  authError.value = ''
}

const pasteKeyFromClipboard = async () => {
  try {
    if (navigator.clipboard) {
      const text = await navigator.clipboard.readText()
      if (text) {
        heritageKeyInput.value = text.trim().toUpperCase()
      }
    }
  } catch (e) {
    console.warn('Clipboard paste failed:', e)
  }
}

const handleHeritageKeySubmit = async () => {
  errors.heritageKey = ''
  authError.value = ''

  const cleanedKey = heritageKeyInput.value.trim()
  if (!cleanedKey) {
    errors.heritageKey = 'Please enter your Heritage Key'
    return
  }

  loading.value = true
  try {
    const result = await authStore.loginWithHeritageKey(cleanedKey)
    if (result && result.user) {
      const redirectPath = route.query.redirect || '/dashboard'
      router.push(redirectPath)
    }
  } catch (error) {
    authError.value = error.response?.data?.error || error.message || 'Invalid Heritage Key. Please verify and try again.'
  } finally {
    loading.value = false
  }
}

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