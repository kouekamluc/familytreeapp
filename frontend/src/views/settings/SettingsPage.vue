<template>
  <div class="app-page-shell py-8 px-4 sm:px-6 lg:px-8 font-sans transition-colors duration-300">
    <div class="max-w-6xl mx-auto">
      <!-- Royal Header Banner -->
      <div
        class="mb-8 p-6 rounded-2xl border shadow-xl flex flex-col md:flex-row md:items-center md:justify-between gap-4 transition-colors"
        :class="isLight ? 'bg-gradient-to-r from-white via-[#FAF6ED] to-white border-[#C5A059]/40 text-stone-900 shadow-amber-900/5' : 'bg-gradient-to-r from-[#171922] via-[#1C1F2B] to-[#171922] border-[#C5A059]/40 text-white shadow-black/80'"
      >
        <div class="flex items-center gap-4">
          <div
            class="w-14 h-14 rounded-2xl border-2 border-[#C5A059] p-1 flex items-center justify-center shadow-lg"
            :class="isLight ? 'bg-amber-50' : 'bg-[#0B0C0E]'"
          >
            <img src="/logo.png" alt="Kkevo Logo" class="w-full h-full object-contain" />
          </div>
          <div>
            <h1
              class="text-2xl sm:text-3xl font-serif font-black tracking-wider uppercase"
              :class="isLight ? 'text-stone-900' : 'text-transparent bg-clip-text bg-gradient-to-r from-[#F3E5AB] via-[#D4AF37] to-[#C5A059]'"
            >
              Settings & Preferences
            </h1>
            <p class="text-xs mt-0.5" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
              Manage your personal Kkevo profile, appearance mode, and privacy controls
            </p>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <router-link
            to="/tree"
            class="px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 shadow-sm"
            :class="isLight ? 'bg-white hover:bg-stone-100 text-stone-800 border border-[#C5A059]/50' : 'bg-[#1A1C24] hover:bg-[#222530] text-[#F3E5AB] border border-[#C5A059]/50'"
          >
            <span>🌳</span>
            <span>Back to Tree</span>
          </router-link>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
        <!-- Sidebar Navigation -->
        <div class="lg:col-span-1">
          <nav
            class="space-y-2 p-3 rounded-2xl border shadow-lg transition-colors"
            :class="isLight ? 'bg-white border-[#C5A059]/30 text-stone-900 shadow-amber-900/5' : 'bg-[#16181F] border-[#C5A059]/30 text-stone-100 shadow-black/60'"
          >
            <button
              v-for="section in sections"
              :key="section.id"
              @click="activeSection = section.id"
              class="w-full flex items-center gap-3 px-4 py-3 text-sm font-bold rounded-xl transition-all text-left cursor-pointer"
              :class="[
                activeSection === section.id
                  ? isLight
                    ? 'bg-amber-50 text-[#634208] border-2 border-[#C5A059] shadow-sm'
                    : 'bg-gradient-to-r from-[#C5A059]/25 to-[#D4AF37]/15 text-[#F3E5AB] border border-[#C5A059] shadow-sm'
                  : isLight
                    ? 'text-stone-600 hover:text-stone-900 hover:bg-stone-50'
                    : 'text-stone-400 hover:text-stone-200 hover:bg-white/5'
              ]"
            >
              <span class="text-lg">{{ section.emoji }}</span>
              <span>{{ section.name }}</span>
            </button>
          </nav>

          <!-- User Card Preview -->
          <div
            class="mt-4 p-4 rounded-2xl border text-center transition-colors"
            :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/30 text-stone-900' : 'bg-[#16181F] border-[#C5A059]/20 text-stone-100'"
          >
            <div
              class="w-16 h-16 mx-auto rounded-full border-2 border-[#D4AF37] p-0.5 overflow-hidden mb-2 shadow-inner"
              :class="isLight ? 'bg-amber-50' : 'bg-[#0B0C0E]'"
            >
              <img :src="profile.avatar || '/logo.png'" alt="Avatar" class="w-full h-full object-cover" />
            </div>
            <div class="font-serif font-bold text-sm" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">{{ profile.name || 'Family Member' }}</div>
            <div class="text-[11px]" :class="isLight ? 'text-stone-500' : 'text-stone-400'">{{ profile.email || 'Member of Kkevo Family' }}</div>
          </div>
        </div>

        <!-- Main Content Area -->
        <div class="lg:col-span-3">
          <div
            class="p-6 sm:p-8 rounded-2xl border shadow-2xl relative transition-colors"
            :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900 shadow-amber-900/5' : 'bg-[#16181F] border-[#C5A059]/40 text-stone-100 shadow-black/80'"
          >
            <!-- Toast notification -->
            <transition name="fade">
              <div
                v-if="statusMessage"
                class="mb-6 p-4 rounded-xl border border-emerald-500/50 bg-emerald-950/70 text-emerald-200 text-sm flex items-center gap-2"
              >
                <span>✓</span>
                <span>{{ statusMessage }}</span>
              </div>
            </transition>

            <!-- Profile Section -->
            <div v-if="activeSection === 'profile'">
              <div class="border-b border-[#C5A059]/20 pb-4 mb-6">
                <h2 class="text-xl font-serif font-bold text-[#F3E5AB]">Profile Information</h2>
                <p class="text-xs text-stone-400 mt-1">Update your display name, contact email, and bio.</p>
              </div>

              <form @submit.prevent="saveProfile" class="space-y-6">
                <div>
                  <label :class="['block text-xs font-black uppercase tracking-wider mb-2', isLight ? 'text-stone-800' : 'text-[#F3E5AB]']">
                    Profile Picture
                  </label>
                  <div class="flex items-center gap-4">
                    <div :class="['w-16 h-16 rounded-full border-2 border-[#C5A059] p-0.5 overflow-hidden', isLight ? 'bg-amber-50' : 'bg-[#0E0F12]']">
                      <img :src="profile.avatar || '/logo.png'" alt="Avatar" class="w-full h-full object-cover" />
                    </div>
                    <button
                      type="button"
                      @click="triggerAvatarUpload"
                      :class="['px-4 py-2 border border-[#C5A059]/50 text-xs font-bold rounded-xl transition-all',
                        isLight ? 'bg-stone-100 hover:bg-stone-200 text-stone-800' : 'bg-[#1F2128] hover:bg-[#2A2D37] text-[#F3E5AB]']"
                    >
                      Change Photo
                    </button>
                    <input
                      ref="fileInput"
                      type="file"
                      accept="image/*"
                      class="hidden"
                      @change="handleAvatarChange"
                    />
                  </div>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label :class="['block text-xs font-black uppercase tracking-wider mb-1.5', isLight ? 'text-stone-800' : 'text-[#F3E5AB]']">
                      Full Name
                    </label>
                    <input
                      v-model="profile.name"
                      type="text"
                      class="w-full px-4 py-3 app-input-theme rounded-xl text-sm focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37]"
                    />
                  </div>

                  <div>
                    <label :class="['block text-xs font-black uppercase tracking-wider mb-1.5', isLight ? 'text-stone-800' : 'text-[#F3E5AB]']">
                      Email Address
                    </label>
                    <input
                      v-model="profile.email"
                      type="email"
                      class="w-full px-4 py-3 app-input-theme rounded-xl text-sm focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37]"
                    />
                  </div>
                </div>

                <div>
                  <label :class="['block text-xs font-black uppercase tracking-wider mb-1.5', isLight ? 'text-stone-800' : 'text-[#F3E5AB]']">
                    Family Biography / Ancestral Branch
                  </label>
                  <textarea
                    v-model="profile.bio"
                    rows="3"
                    placeholder="Tell your story, your village origins, or notable memories..."
                    class="w-full px-4 py-3 app-input-theme rounded-xl text-sm focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37]"
                  ></textarea>
                </div>

                <div class="flex justify-end pt-2">
                  <button
                    type="submit"
                    class="px-6 py-3 rounded-xl font-black text-xs uppercase tracking-wider text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-110 shadow-lg shadow-[#C5A059]/30 transition-all"
                  >
                    Save Profile Changes
                  </button>
                </div>
              </form>
            </div>

            <!-- Privacy Section -->
            <div v-if="activeSection === 'privacy'">
              <div class="border-b border-[#C5A059]/20 pb-4 mb-6">
                <h2 :class="['text-xl font-serif font-bold', isLight ? 'text-stone-900' : 'text-[#F3E5AB]']">Privacy & Sharing</h2>
                <p :class="['text-xs mt-1', isLight ? 'text-stone-600' : 'text-stone-400']">Control who can see your branch, photos, and personal details.</p>
              </div>

              <div class="space-y-6">
                <div>
                  <label :class="['block text-xs font-black uppercase tracking-wider mb-3', isLight ? 'text-stone-800' : 'text-[#F3E5AB]']">
                    Lineage Visibility
                  </label>
                  <div class="space-y-3">
                    <label class="flex items-center gap-3 p-3.5 rounded-xl app-sub-panel cursor-pointer hover:border-[#D4AF37]">
                      <input
                        v-model="privacy.profileVisibility"
                        type="radio"
                        value="family"
                        class="text-[#D4AF37] focus:ring-[#D4AF37] bg-transparent border-[#C5A059]/60"
                      />
                      <div>
                        <div :class="['text-sm font-bold', isLight ? 'text-stone-900' : 'text-stone-200']">Verified Family Members Only (Recommended)</div>
                        <div :class="['text-xs', isLight ? 'text-stone-600' : 'text-stone-400']">Only signed-in descendants of the Kkevo lineage can view your profile</div>
                      </div>
                    </label>

                    <label class="flex items-center gap-3 p-3.5 rounded-xl app-sub-panel cursor-pointer hover:border-[#D4AF37]">
                      <input
                        v-model="privacy.profileVisibility"
                        type="radio"
                        value="public"
                        class="text-[#D4AF37] focus:ring-[#D4AF37] bg-transparent border-[#C5A059]/60"
                      />
                      <div>
                        <div :class="['text-sm font-bold', isLight ? 'text-stone-900' : 'text-stone-200']">Public Heritage Archive</div>
                        <div :class="['text-xs', isLight ? 'text-stone-600' : 'text-stone-400']">Allows general diaspora visitors to discover shared lineage records</div>
                      </div>
                    </label>

                    <label class="flex items-center gap-3 p-3.5 rounded-xl app-sub-panel cursor-pointer hover:border-[#D4AF37]">
                      <input
                        v-model="privacy.profileVisibility"
                        type="radio"
                        value="private"
                        class="text-[#D4AF37] focus:ring-[#D4AF37] bg-transparent border-[#C5A059]/60"
                      />
                      <div>
                        <div :class="['text-sm font-bold', isLight ? 'text-stone-900' : 'text-stone-200']">Private to Me</div>
                        <div :class="['text-xs', isLight ? 'text-stone-600' : 'text-stone-400']">Only you can view and edit your profile</div>
                      </div>
                    </label>
                  </div>
                </div>

                <div class="pt-2 border-t border-[#C5A059]/20 space-y-3">
                  <label class="flex items-center gap-3 cursor-pointer">
                    <input
                      v-model="privacy.shareWithFamily"
                      type="checkbox"
                      class="w-4 h-4 rounded text-[#D4AF37] focus:ring-[#D4AF37] bg-transparent border-[#C5A059]/60"
                    />
                    <span :class="['text-sm', isLight ? 'text-stone-700' : 'text-stone-300']">Allow cousins and kin to contribute photos to my memories</span>
                  </label>
                  <label class="flex items-center gap-3 cursor-pointer">
                    <input
                      v-model="privacy.allowSearch"
                      type="checkbox"
                      class="w-4 h-4 rounded text-[#D4AF37] focus:ring-[#D4AF37] bg-transparent border-[#C5A059]/60"
                    />
                    <span :class="['text-sm', isLight ? 'text-stone-700' : 'text-stone-300']">Allow relatives to find me in the Family Directory</span>
                  </label>
                </div>

                <div class="flex justify-end pt-4">
                  <button
                    @click="savePrivacy"
                    class="px-6 py-3 rounded-xl font-black text-xs uppercase tracking-wider text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-110 shadow-lg shadow-[#C5A059]/30 transition-all"
                  >
                    Save Privacy Settings
                  </button>
                </div>
              </div>
            </div>

            <!-- Notifications Section -->
            <div v-if="activeSection === 'notifications'">
              <div class="border-b border-[#C5A059]/20 pb-4 mb-6">
                <h2 :class="['text-xl font-serif font-bold', isLight ? 'text-stone-900' : 'text-[#F3E5AB]']">Family Notifications</h2>
                <p :class="['text-xs mt-1', isLight ? 'text-stone-600' : 'text-stone-400']">Choose how and when you wish to be alerted about lineage additions.</p>
              </div>

              <div class="space-y-4">
                <label class="flex items-start gap-3 p-4 rounded-xl app-sub-panel cursor-pointer">
                  <input
                    v-model="notifications.emailUpdates"
                    type="checkbox"
                    class="mt-1 w-4 h-4 rounded text-[#D4AF37] focus:ring-[#D4AF37] bg-transparent border-[#C5A059]/60"
                  />
                  <div>
                    <div :class="['text-sm font-bold', isLight ? 'text-stone-900' : 'text-stone-200']">New Relative Added to My Branch</div>
                    <div :class="['text-xs', isLight ? 'text-stone-600' : 'text-stone-400']">Receive an email when an elder, partner, or child is linked to your family branch.</div>
                  </div>
                </label>

                <label class="flex items-start gap-3 p-4 rounded-xl app-sub-panel cursor-pointer">
                  <input
                    v-model="notifications.emailMessages"
                    type="checkbox"
                    class="mt-1 w-4 h-4 rounded text-[#D4AF37] focus:ring-[#D4AF37] bg-transparent border-[#C5A059]/60"
                  />
                  <div>
                    <div :class="['text-sm font-bold', isLight ? 'text-stone-900' : 'text-stone-200']">New Historical Photo or Story Uploaded</div>
                    <div :class="['text-xs', isLight ? 'text-stone-600' : 'text-stone-400']">Get notified when a new family portrait or oral history document is added.</div>
                  </div>
                </label>

                <label class="flex items-start gap-3 p-4 rounded-xl app-sub-panel cursor-pointer">
                  <input
                    v-model="notifications.pushUpdates"
                    type="checkbox"
                    class="mt-1 w-4 h-4 rounded text-[#D4AF37] focus:ring-[#D4AF37] bg-transparent border-[#C5A059]/60"
                  />
                  <div>
                    <div :class="['text-sm font-bold', isLight ? 'text-stone-900' : 'text-stone-200']">Upcoming Family Anniversaries & Gatherings</div>
                    <div :class="['text-xs', isLight ? 'text-stone-600' : 'text-stone-400']">Reminders for traditional gatherings, ceremonies, and birthdays.</div>
                  </div>
                </label>

                <div class="flex justify-end pt-4">
                  <button
                    @click="saveNotifications"
                    class="px-6 py-3 rounded-xl font-black text-xs uppercase tracking-wider text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-110 shadow-lg shadow-[#C5A059]/30 transition-all"
                  >
                    Save Notification Preferences
                  </button>
                </div>
              </div>
            </div>

            <!-- Account & Security Section -->
            <div v-if="activeSection === 'account'">
              <div class="border-b border-[#C5A059]/20 pb-4 mb-6">
                <h2 :class="['text-xl font-serif font-bold', isLight ? 'text-stone-900' : 'text-[#F3E5AB]']">Account Security</h2>
                <p :class="['text-xs mt-1', isLight ? 'text-stone-600' : 'text-stone-400']">Change your password and manage account credentials.</p>
              </div>

              <form @submit.prevent="updatePassword" class="space-y-4 max-w-md">
                <div>
                  <label :class="['block text-xs font-black uppercase tracking-wider mb-1.5', isLight ? 'text-stone-800' : 'text-[#F3E5AB]']">
                    Current Password
                  </label>
                  <input
                    v-model="account.currentPassword"
                    type="password"
                    placeholder="••••••••"
                    class="w-full px-4 py-3 app-input-theme rounded-xl text-sm focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37]"
                  />
                </div>

                <div>
                  <label :class="['block text-xs font-black uppercase tracking-wider mb-1.5', isLight ? 'text-stone-800' : 'text-[#F3E5AB]']">
                    New Password
                  </label>
                  <input
                    v-model="account.newPassword"
                    type="password"
                    placeholder="••••••••"
                    class="w-full px-4 py-3 app-input-theme rounded-xl text-sm focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37]"
                  />
                </div>

                <div>
                  <label :class="['block text-xs font-black uppercase tracking-wider mb-1.5', isLight ? 'text-stone-800' : 'text-[#F3E5AB]']">
                    Confirm New Password
                  </label>
                  <input
                    v-model="account.confirmPassword"
                    type="password"
                    placeholder="••••••••"
                    class="w-full px-4 py-3 app-input-theme rounded-xl text-sm focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37]"
                  />
                </div>

                <div class="pt-2">
                  <button
                    type="submit"
                    class="px-6 py-3 rounded-xl font-black text-xs uppercase tracking-wider text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-110 shadow-lg shadow-[#C5A059]/30 transition-all"
                  >
                    Update Password
                  </button>
                </div>
              </form>

              <!-- Danger Zone -->
              <div class="mt-12 pt-6 border-t border-red-900/40">
                <h3 class="text-sm font-black uppercase tracking-wider text-red-400 mb-2">Delete Account</h3>
                <p class="text-xs text-stone-400 mb-4 leading-relaxed">
                  Removing your account will revoke your edit privileges. Any ancestral relatives you documented will remain safe in the Kkevo family archive.
                </p>
                <button
                  @click="deleteAccount"
                  class="px-4 py-2.5 rounded-xl text-xs font-bold text-red-300 bg-red-950/40 border border-red-700/60 hover:bg-red-900/60 transition-colors cursor-pointer"
                >
                  Request Account Deletion
                </button>
              </div>
            </div>

            <!-- Appearance & Display Theme Section -->
            <div v-if="activeSection === 'appearance'">
              <div class="border-b pb-4 mb-6" :class="isLight ? 'border-[#C5A059]/20' : 'border-[#C5A059]/20'">
                <h2 class="text-xl font-serif font-bold" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">Display & Theme Preferences</h2>
                <p class="text-xs mt-1" :class="isLight ? 'text-stone-600' : 'text-stone-400'">Select your preferred visual aesthetic across all pages of the Kkevo family application.</p>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
                <!-- Royal Obsidian Dark -->
                <div
                  @click="themeStore.setTheme('dark')"
                  class="p-6 rounded-2xl border-2 cursor-pointer transition-all flex flex-col justify-between shadow-lg"
                  :class="!isLight ? 'border-[#C5A059] bg-[#0E0F12] text-white ring-2 ring-[#C5A059] shadow-amber-950/20' : 'border-stone-200 bg-stone-50 text-stone-800 hover:border-[#C5A059]'"
                >
                  <div>
                    <div class="flex items-center justify-between mb-4">
                      <span class="text-3xl">🌙</span>
                      <span v-if="!isLight" class="text-xs font-black px-2.5 py-1 rounded-full bg-[#C5A059] text-black shadow">Active Theme</span>
                    </div>
                    <h3 class="font-serif font-black text-lg">Royal Obsidian Dark</h3>
                    <p class="text-xs opacity-80 mt-2 leading-relaxed">
                      Deep obsidian black canvas with metallic gold borders, glowing pedigree connection lines, and dramatic contrast.
                    </p>
                  </div>
                  <div class="mt-6 flex items-center gap-2 pt-4 border-t border-white/10">
                    <span class="w-4 h-4 rounded-full bg-[#0E0F12] border border-[#C5A059]"></span>
                    <span class="w-4 h-4 rounded-full bg-[#16181F] border border-[#C5A059]/50"></span>
                    <span class="w-4 h-4 rounded-full bg-[#C5A059]"></span>
                    <span class="text-[11px] opacity-70 ml-auto">Obsidian & Gold</span>
                  </div>
                </div>

                <!-- Royal Alabaster Ivory -->
                <div
                  @click="themeStore.setTheme('light')"
                  class="p-6 rounded-2xl border-2 cursor-pointer transition-all flex flex-col justify-between shadow-lg"
                  :class="isLight ? 'border-[#C5A059] bg-white text-stone-900 ring-2 ring-[#C5A059] shadow-amber-950/10' : 'border-[#C5A059]/30 bg-[#16181F] text-stone-300 hover:border-[#C5A059]'"
                >
                  <div>
                    <div class="flex items-center justify-between mb-4">
                      <span class="text-3xl">☀️</span>
                      <span v-if="isLight" class="text-xs font-black px-2.5 py-1 rounded-full bg-[#C5A059] text-black shadow">Active Theme</span>
                    </div>
                    <h3 class="font-serif font-black text-lg">Royal Alabaster Ivory</h3>
                    <p class="text-xs opacity-80 mt-2 leading-relaxed">
                      Warm ivory parchment aesthetic with clean white cards, antique brass trims, and effortless readability for elders and youth.
                    </p>
                  </div>
                  <div class="mt-6 flex items-center gap-2 pt-4 border-t border-stone-200/40">
                    <span class="w-4 h-4 rounded-full bg-[#FAF8F5] border border-[#C5A059]"></span>
                    <span class="w-4 h-4 rounded-full bg-white border border-[#C5A059]/50"></span>
                    <span class="w-4 h-4 rounded-full bg-[#C5A059]"></span>
                    <span class="text-[11px] opacity-70 ml-auto">Ivory & Gold</span>
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
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useThemeStore } from '@/stores/theme'

const router = useRouter()
const authStore = useAuthStore()
const themeStore = useThemeStore()

const isLight = computed(() => themeStore.isLight)
const activeSection = ref('appearance')
const statusMessage = ref('')
const fileInput = ref(null)

const sections = [
  { id: 'appearance', name: 'Display & Theme', emoji: '🎨' },
  { id: 'profile', name: 'Profile & Bio', emoji: '👤' },
  { id: 'privacy', name: 'Privacy & Sharing', emoji: '🛡️' },
  { id: 'notifications', name: 'Notifications', emoji: '🔔' },
  { id: 'account', name: 'Account & Security', emoji: '⚙️' }
]

const profile = ref({
  avatar: '/logo.png',
  name: '',
  email: '',
  bio: 'Honoring and preserving the Kkevo family roots and heritage.'
})

const privacy = ref({
  profileVisibility: 'family',
  shareWithFamily: true,
  allowSearch: true
})

const notifications = ref({
  emailUpdates: true,
  emailMessages: true,
  pushUpdates: false
})

const account = ref({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

onMounted(() => {
  const user = authStore.currentUser || authStore.user
  if (user) {
    profile.value.name = user.first_name ? `${user.first_name} ${user.last_name || ''}`.trim() : user.username || 'Family Member'
    profile.value.email = user.email || 'user@kkevo.org'
  }
})

const showToast = (msg) => {
  statusMessage.value = msg
  setTimeout(() => {
    statusMessage.value = ''
  }, 3500)
}

const triggerAvatarUpload = () => {
  if (fileInput.value) {
    fileInput.value.click()
  }
}

const handleAvatarChange = (e) => {
  const file = e.target.files[0]
  if (file) {
    const reader = new FileReader()
    reader.onload = (evt) => {
      profile.value.avatar = evt.target.result
      showToast('Profile photo updated successfully!')
    }
    reader.readAsDataURL(file)
  }
}

const saveProfile = () => {
  showToast('Profile changes saved successfully!')
}

const savePrivacy = () => {
  showToast('Privacy preferences updated!')
}

const saveNotifications = () => {
  showToast('Notification settings saved!')
}

const updatePassword = () => {
  if (!account.value.newPassword) {
    alert('Please enter a new password.')
    return
  }
  if (account.value.newPassword !== account.value.confirmPassword) {
    alert('New passwords do not match.')
    return
  }
  account.value.currentPassword = ''
  account.value.newPassword = ''
  account.value.confirmPassword = ''
  showToast('Password updated successfully!')
}

const deleteAccount = () => {
  if (confirm('Are you sure you want to request account deletion?')) {
    alert('Your deletion request has been submitted to the family administrator.')
  }
}
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>