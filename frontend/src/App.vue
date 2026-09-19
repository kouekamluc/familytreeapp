<template>
  <div
    class="min-h-screen font-sans transition-colors duration-300 selection:bg-[#C5A059] selection:text-black"
    :class="[
      isLight ? 'bg-[#FAF8F5] text-stone-900' : 'bg-[#0E0F12] text-stone-100'
    ]"
    :data-theme="currentTheme"
  >
    <!-- ========================================================= -->
    <!-- 1. GUEST / PUBLIC LAYOUT (When NOT logged in)             -->
    <!-- ========================================================= -->
    <div v-if="!isAuthenticated" class="min-h-screen flex flex-col">
      <!-- Clean Top Navbar for Public / Landing / Auth -->
      <nav
        class="border-b sticky top-0 z-30 transition-colors duration-300 shadow-md"
        :class="[
          isLight
            ? 'bg-[#FFFFFF] border-[#C5A059]/40 text-stone-900'
            : 'bg-[#121316] border-[#C5A059]/40 text-stone-100'
        ]"
      >
        <div class="w-full px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center h-20 py-2">
            <!-- Brand Logo -->
            <router-link to="/" class="flex items-center gap-3 group">
              <div
                class="w-11 h-11 rounded-xl overflow-hidden border-2 border-[#C5A059] shadow-md group-hover:scale-105 transition-transform flex items-center justify-center p-0.5"
                :class="isLight ? 'bg-amber-50/50 shadow-amber-900/10' : 'bg-[#0B0C0E] shadow-black/60'"
              >
                <img src="/logo.png" alt="KKEVO FAMILY Logo" class="w-full h-full object-contain" />
              </div>
              <div>
                <span class="text-xl font-black text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] tracking-wider block leading-tight uppercase font-serif">
                  KKEVO FAMILY
                </span>
                <span class="text-[10px] font-bold block uppercase tracking-widest mt-0.5" :class="isLight ? 'text-[#855B14]' : 'text-[#C5A059]/90'">
                  Heritage & Roots
                </span>
              </div>
            </router-link>

            <!-- Public Links -->
            <div class="hidden md:flex items-center space-x-3">
              <router-link
                to="/tree"
                class="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-bold transition-all"
                :class="isLight ? 'text-stone-700 hover:bg-stone-100' : 'text-[#D4AF37]/80 hover:bg-white/5 hover:text-white'"
              >
                <span class="text-lg">🌳</span>
                <span>Explore Tree</span>
              </router-link>
              <router-link
                to="/help"
                class="flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-bold transition-all"
                :class="isLight ? 'text-stone-700 hover:bg-stone-100' : 'text-[#D4AF37]/80 hover:bg-white/5 hover:text-white'"
              >
                <span class="text-lg">💡</span>
                <span>How It Works</span>
              </router-link>
            </div>

            <!-- Public Controls: Theme & Auth -->
            <div class="flex items-center space-x-3">
              <button
                @click="themeStore.toggleTheme"
                :title="isLight ? 'Switch to Royal Dark Mode' : 'Switch to Royal Light Mode'"
                class="flex items-center justify-center w-10 h-10 rounded-xl border transition-all cursor-pointer shadow-sm hover:scale-105 active:scale-95"
                :class="[
                  isLight
                    ? 'bg-amber-50/80 border-[#C5A059]/50 text-[#855B14] hover:bg-amber-100'
                    : 'bg-[#1A1C22] border-[#C5A059]/50 text-[#F3E5AB] hover:bg-[#252831]'
                ]"
              >
                <span v-if="isLight" class="text-lg">🌙</span>
                <span v-else class="text-lg">☀️</span>
              </button>

              <router-link
                to="/login"
                class="text-sm font-bold px-3 py-2 transition-colors"
                :class="isLight ? 'text-[#855B14] hover:text-black' : 'text-[#D4AF37] hover:text-white'"
              >
                Sign In
              </router-link>
              <router-link
                to="/register"
                class="px-4 py-2 bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] text-black text-sm font-black rounded-xl shadow-md hover:brightness-105 active:scale-95 transition-all"
              >
                Join Kkevo Family
              </router-link>
            </div>
          </div>
        </div>
      </nav>

      <!-- Public Page Body -->
      <main class="flex-grow">
        <router-view v-slot="{ Component }">
          <transition name="fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </main>

      <!-- Public Footer -->
      <footer
        class="border-t py-4 text-center text-xs transition-colors duration-300"
        :class="[
          isLight
            ? 'bg-[#FFFFFF] border-[#C5A059]/30 text-stone-600'
            : 'bg-[#121316] border-[#C5A059]/30 text-[#C5A059]/80'
        ]"
      >
        <div class="container mx-auto px-4 flex flex-col sm:flex-row items-center justify-center gap-2">
          <span class="font-serif font-bold tracking-wider" :class="isLight ? 'text-[#855B14]' : 'text-[#F3E5AB]'">
            KKEVO FAMILY
          </span>
          <span class="hidden sm:inline">•</span>
          <p>Preserving our royal heritage, roots, and stories for generations to come.</p>
        </div>
      </footer>
    </div>

    <!-- ========================================================= -->
    <!-- 2. AUTHENTICATED DASHBOARD LAYOUT (Side Nav + Mobile App)  -->
    <!-- ========================================================= -->
    <div v-else class="min-h-screen flex flex-col md:flex-row">
      <!-- 2A. Desktop Side Navigation Sidebar (md and up) -->
      <aside
        class="hidden md:flex w-64 lg:w-72 h-screen sticky top-0 border-r flex-col justify-between shrink-0 transition-colors duration-300 z-30 shadow-xl"
        :class="[
          isLight
            ? 'bg-[#FFFFFF] border-[#C5A059]/40 text-stone-900'
            : 'bg-[#111317] border-[#C5A059]/40 text-stone-100'
        ]"
      >
        <!-- Top: Crest & Lineage Header -->
        <div class="p-5 border-b" :class="isLight ? 'border-[#C5A059]/20' : 'border-[#C5A059]/20'">
          <router-link to="/tree" class="flex items-center gap-3.5 group">
            <div
              class="w-12 h-12 rounded-xl overflow-hidden border-2 border-[#C5A059] shadow-md group-hover:scale-105 transition-transform flex items-center justify-center p-0.5"
              :class="isLight ? 'bg-amber-50/70 shadow-amber-900/10' : 'bg-[#0B0C0E] shadow-black/70'"
            >
              <img src="/logo.png" alt="Kkevo Crest" class="w-full h-full object-contain" />
            </div>
            <div>
              <span class="text-lg font-black text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] tracking-wider block leading-tight uppercase font-serif">
                KKEVO FAMILY
              </span>
              <span class="text-[10px] font-bold block uppercase tracking-widest mt-0.5" :class="isLight ? 'text-[#855B14]' : 'text-[#C5A059]/90'">
                Heritage & Roots
              </span>
            </div>
          </router-link>
        </div>

        <!-- Middle: Navigation Tabs List -->
        <div class="flex-1 overflow-y-auto p-4 space-y-1.5">
          <div class="px-3 pb-2 text-[10px] font-black uppercase tracking-widest" :class="isLight ? 'text-stone-600' : 'text-[#C5A059]/70'">
            Lineage Dashboard
          </div>

          <router-link
            v-for="item in primaryNavItems"
            :key="item.name"
            :to="item.to"
            class="flex items-center justify-between px-3.5 py-3 rounded-xl text-sm font-bold transition-all group"
            :class="[
              $route.path.startsWith(item.to)
                ? isLight
                  ? 'bg-[#C5A059]/20 text-[#543806] border border-[#C5A059] shadow-sm font-black'
                  : 'bg-gradient-to-r from-[#C5A059]/25 to-[#D4AF37]/15 text-[#FFF9E6] border border-[#C5A059]/70 shadow-sm shadow-[#C5A059]/20 font-black'
                : isLight
                  ? 'text-stone-700 hover:bg-stone-100 hover:text-stone-900'
                  : 'text-stone-300 hover:bg-white/5 hover:text-white'
            ]"
          >
            <div class="flex items-center gap-3">
              <span class="text-xl group-hover:scale-110 transition-transform">{{ item.icon }}</span>
              <span>{{ item.name }}</span>
            </div>
            <span
              v-if="item.badge"
              class="text-[10px] font-black uppercase tracking-wider px-2 py-0.5 rounded-full"
              :class="isLight ? 'bg-amber-100 text-[#855B14]' : 'bg-[#C5A059]/20 text-[#F3E5AB] border border-[#C5A059]/40'"
            >
              {{ item.badge }}
            </span>
          </router-link>

          <div class="pt-4 pb-2 px-3 text-[10px] font-black uppercase tracking-widest" :class="isLight ? 'text-stone-600' : 'text-[#C5A059]/70'">
            Preferences & Support
          </div>

          <router-link
            v-for="item in secondaryNavItems"
            :key="item.name"
            :to="item.to"
            class="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all"
            :class="[
              $route.path.startsWith(item.to)
                ? isLight
                  ? 'bg-[#C5A059]/15 text-[#543806] font-black border border-[#C5A059]/60'
                  : 'bg-white/10 text-white font-black border border-[#C5A059]/60'
                : isLight
                  ? 'text-stone-600 hover:bg-stone-100 hover:text-stone-900'
                  : 'text-stone-400 hover:bg-white/5 hover:text-stone-200'
            ]"
          >
            <span class="text-base">{{ item.icon }}</span>
            <span>{{ item.name }}</span>
          </router-link>
        </div>

        <!-- Bottom: User Card, Theme Toggle & Logout -->
        <div class="p-4 border-t space-y-3" :class="isLight ? 'border-[#C5A059]/20 bg-stone-50/50' : 'border-[#C5A059]/20 bg-[#0C0D10]'">
          <!-- User Profile Pill -->
          <router-link
            to="/settings"
            class="flex items-center justify-between p-2.5 rounded-xl border transition-all group"
            :class="isLight ? 'bg-white border-stone-200 hover:border-[#C5A059]' : 'bg-[#16181F] border-[#C5A059]/30 hover:border-[#D4AF37]'"
          >
            <div class="flex items-center gap-2.5 overflow-hidden">
              <div class="w-8 h-8 rounded-full border border-[#C5A059] flex items-center justify-center text-xs font-black shrink-0"
                :class="isLight ? 'bg-amber-100 text-[#855B14]' : 'bg-[#0B0C0E] text-[#D4AF37]'">
                👑
              </div>
              <div class="truncate">
                <div class="text-xs font-black truncate" :class="isLight ? 'text-stone-900' : 'text-stone-100'">
                  {{ currentUser?.first_name || currentUser?.username || 'Kkevo Member' }}
                </div>
                <div class="text-[10px] text-[#C5A059] font-bold">Verified Lineage</div>
              </div>
            </div>
            <span class="text-xs text-stone-400 group-hover:translate-x-0.5 transition-transform">&rarr;</span>
          </router-link>

          <!-- Theme Toggle Button -->
          <button
            @click="themeStore.toggleTheme"
            class="w-full flex items-center justify-between px-3 py-2 rounded-xl border text-xs font-bold transition-all cursor-pointer shadow-sm"
            :class="isLight ? 'bg-white border-stone-200 hover:bg-stone-100 text-stone-800' : 'bg-[#16181F] border-[#C5A059]/30 hover:bg-[#1E2029] text-[#F3E5AB]'"
          >
            <span class="flex items-center gap-2">
              <span v-if="isLight">🌙</span>
              <span v-else>☀️</span>
              <span>{{ isLight ? 'Dark Mode' : 'Light Mode' }}</span>
            </span>
            <span class="text-[10px] uppercase tracking-wider font-black text-[#C5A059]">Switch</span>
          </button>

          <!-- Exit / Logout -->
          <button
            @click="logout"
            class="w-full py-2 px-3 rounded-xl border text-xs font-black tracking-wide transition-all cursor-pointer flex items-center justify-center gap-1.5"
            :class="isLight ? 'bg-red-50 hover:bg-red-100 border-red-200 text-red-700' : 'bg-red-950/30 hover:bg-red-950/60 border-red-900/40 text-red-400'"
          >
            <span>🚪</span>
            <span>Sign Out</span>
          </button>
        </div>
      </aside>

      <!-- 2B. Mobile Header (< md screens) -->
      <header
        class="md:hidden flex items-center justify-between px-4 py-3 border-b sticky top-0 z-30 transition-colors shadow-sm"
        :class="isLight ? 'bg-white border-[#C5A059]/30 text-stone-900' : 'bg-[#121316] border-[#C5A059]/40 text-stone-100'"
      >
        <div class="flex items-center gap-2.5">
          <button
            @click="mobileDrawerOpen = true"
            class="p-2 rounded-xl border border-[#C5A059]/40 text-base transition-all cursor-pointer"
            :class="isLight ? 'bg-amber-50/80 text-stone-800' : 'bg-[#1C1E24] text-[#F3E5AB]'"
            title="Open Lineage Menu"
          >
            ☰
          </button>
          <div class="w-8 h-8 rounded-lg overflow-hidden border border-[#C5A059] p-0.5 flex items-center justify-center"
            :class="isLight ? 'bg-amber-50' : 'bg-black'">
            <img src="/logo.png" alt="Logo" class="w-full h-full object-contain" />
          </div>
          <span class="text-sm font-black font-serif uppercase tracking-wider text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059]">
            Kkevo Family
          </span>
        </div>

        <div class="flex items-center gap-2">
          <!-- Mobile Theme Button -->
          <button
            @click="themeStore.toggleTheme"
            class="w-9 h-9 rounded-xl border flex items-center justify-center text-sm transition-all cursor-pointer"
            :class="isLight ? 'bg-amber-50/80 border-[#C5A059]/50 text-stone-800' : 'bg-[#1A1C22] border-[#C5A059]/50 text-[#F3E5AB]'"
          >
            <span v-if="isLight">🌙</span>
            <span v-else>☀️</span>
          </button>
          <!-- Settings Icon -->
          <router-link
            to="/settings"
            class="w-9 h-9 rounded-xl border flex items-center justify-center text-sm transition-all"
            :class="isLight ? 'bg-amber-50/80 border-[#C5A059]/50 text-stone-800' : 'bg-[#1A1C22] border-[#C5A059]/50 text-[#F3E5AB]'"
          >
            ⚙️
          </router-link>
        </div>
      </header>

      <!-- 2C. Mobile Slide-out Drawer (with smooth overlay) -->
      <transition name="drawer-fade">
        <div
          v-if="mobileDrawerOpen"
          @click="mobileDrawerOpen = false"
          class="fixed inset-0 bg-black/60 backdrop-blur-sm z-40 md:hidden"
        ></div>
      </transition>

      <div
        :class="[
          'fixed inset-y-0 left-0 z-50 w-72 transform transition-transform duration-300 ease-in-out md:hidden flex flex-col justify-between border-r shadow-2xl',
          mobileDrawerOpen ? 'translate-x-0' : '-translate-x-full',
          isLight ? 'bg-white border-[#C5A059]/40 text-stone-900' : 'bg-[#111317] border-[#C5A059]/40 text-stone-100'
        ]"
      >
        <!-- Drawer Header -->
        <div class="p-4 border-b flex items-center justify-between" :class="isLight ? 'border-[#C5A059]/20' : 'border-[#C5A059]/20'">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl overflow-hidden border-2 border-[#C5A059] p-0.5 flex items-center justify-center"
              :class="isLight ? 'bg-amber-50' : 'bg-black'">
              <img src="/logo.png" alt="Logo" class="w-full h-full object-contain" />
            </div>
            <div>
              <div class="text-sm font-black font-serif uppercase tracking-wider text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059]">
                Kkevo Family
              </div>
              <div class="text-[9px] uppercase tracking-widest text-[#C5A059] font-bold">Royal Lineage</div>
            </div>
          </div>
          <button
            @click="mobileDrawerOpen = false"
            class="w-8 h-8 rounded-lg flex items-center justify-center text-stone-400 hover:text-stone-100 text-lg"
          >
            ✕
          </button>
        </div>

        <!-- Drawer Links -->
        <div class="flex-1 overflow-y-auto p-4 space-y-2">
          <router-link
            v-for="item in primaryNavItems"
            :key="item.name"
            :to="item.to"
            @click="mobileDrawerOpen = false"
            class="flex items-center justify-between px-3.5 py-3 rounded-xl text-sm font-bold transition-all"
            :class="[
              $route.path.startsWith(item.to)
                ? isLight
                  ? 'bg-[#C5A059]/20 text-[#543806] border border-[#C5A059] font-black'
                  : 'bg-gradient-to-r from-[#C5A059]/25 to-[#D4AF37]/15 text-[#FFF9E6] border border-[#C5A059] font-black'
                : isLight
                  ? 'text-stone-700 hover:bg-stone-100'
                  : 'text-stone-300 hover:bg-white/5'
            ]"
          >
            <div class="flex items-center gap-3">
              <span class="text-xl">{{ item.icon }}</span>
              <span>{{ item.name }}</span>
            </div>
            <span
              v-if="item.badge"
              class="text-[9px] font-black uppercase px-2 py-0.5 rounded-full"
              :class="isLight ? 'bg-amber-100 text-[#855B14]' : 'bg-[#C5A059]/20 text-[#F3E5AB]'"
            >
              {{ item.badge }}
            </span>
          </router-link>

          <div class="pt-4 border-t border-[#C5A059]/20 space-y-1.5">
            <router-link
              v-for="item in secondaryNavItems"
              :key="item.name"
              :to="item.to"
              @click="mobileDrawerOpen = false"
              class="flex items-center gap-3 px-3 py-2 rounded-xl text-xs font-bold transition-all"
              :class="isLight ? 'text-stone-600 hover:bg-stone-100' : 'text-stone-400 hover:bg-white/5'"
            >
              <span>{{ item.icon }}</span>
              <span>{{ item.name }}</span>
            </router-link>
          </div>
        </div>

        <!-- Drawer Footer -->
        <div class="p-4 border-t space-y-2" :class="isLight ? 'border-[#C5A059]/20 bg-stone-50' : 'border-[#C5A059]/20 bg-[#0C0D10]'">
          <div class="text-xs font-bold text-center" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
            {{ currentUser?.first_name || currentUser?.username || 'Kkevo Family Member' }}
          </div>
          <button
            @click="logout(); mobileDrawerOpen = false"
            class="w-full py-2.5 rounded-xl border text-xs font-black text-red-500 bg-red-500/10 border-red-500/30 text-center"
          >
            Sign Out
          </button>
        </div>
      </div>

      <!-- 2D. Main Application Canvas (Remaining Screen Area) -->
      <main class="flex-1 min-w-0 flex flex-col pb-20 md:pb-0 overflow-x-hidden">
        <router-view v-slot="{ Component }">
          <transition name="fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </main>

      <!-- 2E. Mobile Bottom App Bar (Sticky on Mobile Phones) -->
      <nav
        class="md:hidden fixed bottom-0 left-0 right-0 z-30 border-t flex justify-around items-center py-2 px-1 shadow-2xl backdrop-blur-md transition-colors"
        :class="[
          isLight
            ? 'bg-white/95 border-[#C5A059]/40 text-stone-900'
            : 'bg-[#111317]/95 border-[#C5A059]/40 text-stone-100'
        ]"
      >
        <router-link
          v-for="item in mobileBottomItems"
          :key="item.name"
          :to="item.to"
          class="flex flex-col items-center py-1 px-3 rounded-xl transition-all"
          :class="[
            $route.path.startsWith(item.to)
              ? isLight
                ? 'text-[#634208] bg-[#C5A059]/20 font-black scale-105'
                : 'text-[#F3E5AB] bg-[#C5A059]/25 font-black scale-105'
              : isLight
                ? 'text-stone-500 hover:text-stone-800'
                : 'text-stone-400 hover:text-white'
          ]"
        >
          <span class="text-xl leading-none">{{ item.icon }}</span>
          <span class="text-[10px] font-bold mt-1 tracking-tight">{{ item.label }}</span>
        </router-link>
      </nav>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useThemeStore } from '@/stores/theme'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const themeStore = useThemeStore()

const mobileDrawerOpen = ref(false)

// Close drawer automatically on navigation
watch(() => route.path, () => {
  mobileDrawerOpen.value = false
})

onMounted(() => {
  themeStore.initTheme()
})

const currentTheme = computed(() => themeStore.currentTheme)
const isLight = computed(() => themeStore.isLight)
const isAuthenticated = computed(() => authStore.isAuthenticated)
const currentUser = computed(() => authStore.currentUser || authStore.user)

const primaryNavItems = [
  { name: 'Our Tree', to: '/tree', icon: '🌳', badge: 'Interactive' },
  { name: 'Family Members', to: '/people', icon: '👥', badge: 'Directory' },
  { name: 'Photos & Stories', to: '/media', icon: '📸', badge: 'Vault' }
]

const secondaryNavItems = [
  { name: 'Settings & Profile', to: '/settings', icon: '⚙️' },
  { name: 'Help & Heritage', to: '/help', icon: '💡' }
]

const mobileBottomItems = [
  { name: 'Tree', to: '/tree', icon: '🌳', label: 'Tree' },
  { name: 'People', to: '/people', icon: '👥', label: 'Members' },
  { name: 'Media', to: '/media', icon: '📸', label: 'Vault' },
  { name: 'Settings', to: '/settings', icon: '⚙️', label: 'Settings' }
]

const logout = async () => {
  await authStore.logout()
  router.push('/login')
}
</script>

<style>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.drawer-fade-enter-active,
.drawer-fade-leave-active {
  transition: opacity 0.25s ease;
}

.drawer-fade-enter-from,
.drawer-fade-leave-to {
  opacity: 0;
}
</style>