<template>
  <div class="app-page-shell py-8 px-4 sm:px-6 lg:px-8 font-sans transition-colors duration-300">
    <div class="max-w-6xl mx-auto">
      <!-- Royal Help Header Banner -->
      <div class="mb-10 text-center max-w-2xl mx-auto">
        <div
          class="w-16 h-16 mx-auto mb-4 rounded-2xl border-2 border-[#C5A059] p-1 flex items-center justify-center shadow-xl"
          :class="isLight ? 'bg-amber-50 shadow-amber-900/10' : 'bg-[#0B0C0E] shadow-black/80'"
        >
          <img src="/logo.png" alt="Kkevo Logo" class="w-full h-full object-contain" />
        </div>
        <h1
          class="text-3xl sm:text-4xl font-serif font-black tracking-wider uppercase"
          :class="isLight ? 'text-stone-900' : 'text-transparent bg-clip-text bg-gradient-to-r from-[#F3E5AB] via-[#D4AF37] to-[#C5A059]'"
        >
          Kkevo Family Guide & Help
        </h1>
        <p class="mt-2 text-sm" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
          Learn how to explore our pedigree, add relatives with 1 click, and preserve our oral history
        </p>

        <!-- Search Bar -->
        <div class="mt-6 relative max-w-lg mx-auto">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search guides, adding relatives, privacy..."
            class="w-full pl-10 pr-4 py-3 rounded-xl text-sm shadow-lg transition-colors focus:outline-none focus:ring-1 focus:ring-[#D4AF37]"
            :class="isLight ? 'bg-white border-2 border-stone-200 text-stone-900 placeholder-stone-400' : 'bg-[#16181F] border border-[#C5A059]/40 text-stone-100 placeholder-stone-500'"
          />
          <span class="absolute left-3.5 top-1/2 -translate-y-1/2 text-sm" :class="isLight ? 'text-stone-400' : 'text-stone-500'">🔍</span>
        </div>
      </div>

      <!-- Quick Action Cards -->
      <div class="mb-12 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <router-link
          to="/tree"
          class="p-5 rounded-2xl border transition-all shadow-lg group flex flex-col justify-between"
          :class="isLight ? 'bg-white border-[#C5A059]/35 hover:border-[#C5A059] shadow-amber-900/5' : 'bg-[#16181F] border-[#C5A059]/30 hover:border-[#D4AF37] shadow-black/60'"
        >
          <div>
            <div class="text-3xl mb-3">🌳</div>
            <h3 class="font-serif font-bold text-sm" :class="isLight ? 'text-stone-900 group-hover:text-[#996515]' : 'text-[#F3E5AB] group-hover:text-white'">Interactive Tree</h3>
            <p class="text-xs mt-1" :class="isLight ? 'text-stone-600' : 'text-stone-400'">Navigate family pedigree, view ancestral connections.</p>
          </div>
          <div class="text-[11px] font-bold mt-4 flex items-center gap-1" :class="isLight ? 'text-[#855B14]' : 'text-[#D4AF37]'">
            <span>Explore Tree</span>
            <span>&rarr;</span>
          </div>
        </router-link>

        <router-link
          to="/people"
          class="p-5 rounded-2xl border transition-all shadow-lg group flex flex-col justify-between"
          :class="isLight ? 'bg-white border-[#C5A059]/35 hover:border-[#C5A059] shadow-amber-900/5' : 'bg-[#16181F] border-[#C5A059]/30 hover:border-[#D4AF37] shadow-black/60'"
        >
          <div>
            <div class="text-3xl mb-3">👥</div>
            <h3 class="font-serif font-bold text-sm" :class="isLight ? 'text-stone-900 group-hover:text-[#996515]' : 'text-[#F3E5AB] group-hover:text-white'">Family Directory</h3>
            <p class="text-xs mt-1" :class="isLight ? 'text-stone-600' : 'text-stone-400'">Search clan members by name, generation, or village.</p>
          </div>
          <div class="text-[11px] font-bold mt-4 flex items-center gap-1" :class="isLight ? 'text-[#855B14]' : 'text-[#D4AF37]'">
            <span>Find Members</span>
            <span>&rarr;</span>
          </div>
        </router-link>

        <router-link
          to="/media"
          class="p-5 rounded-2xl border transition-all shadow-lg group flex flex-col justify-between"
          :class="isLight ? 'bg-white border-[#C5A059]/35 hover:border-[#C5A059] shadow-amber-900/5' : 'bg-[#16181F] border-[#C5A059]/30 hover:border-[#D4AF37] shadow-black/60'"
        >
          <div>
            <div class="text-3xl mb-3">📸</div>
            <h3 class="font-serif font-bold text-sm" :class="isLight ? 'text-stone-900 group-hover:text-[#996515]' : 'text-[#F3E5AB] group-hover:text-white'">Photos & Stories</h3>
            <p class="text-xs mt-1" :class="isLight ? 'text-stone-600' : 'text-stone-400'">Safeguard treasured photos, ceremonies, and recordings.</p>
          </div>
          <div class="text-[11px] font-bold mt-4 flex items-center gap-1" :class="isLight ? 'text-[#855B14]' : 'text-[#D4AF37]'">
            <span>Open Vault</span>
            <span>&rarr;</span>
          </div>
        </router-link>

        <router-link
          to="/settings"
          class="p-5 rounded-2xl border transition-all shadow-lg group flex flex-col justify-between"
          :class="isLight ? 'bg-white border-[#C5A059]/35 hover:border-[#C5A059] shadow-amber-900/5' : 'bg-[#16181F] border-[#C5A059]/30 hover:border-[#D4AF37] shadow-black/60'"
        >
          <div>
            <div class="text-3xl mb-3">🛡️</div>
            <h3 class="font-serif font-bold text-sm" :class="isLight ? 'text-stone-900 group-hover:text-[#996515]' : 'text-[#F3E5AB] group-hover:text-white'">Privacy Controls</h3>
            <p class="text-xs mt-1" :class="isLight ? 'text-stone-600' : 'text-stone-400'">Control your branch visibility and profile security.</p>
          </div>
          <div class="text-[11px] font-bold mt-4 flex items-center gap-1" :class="isLight ? 'text-[#855B14]' : 'text-[#D4AF37]'">
            <span>Edit Settings</span>
            <span>&rarr;</span>
          </div>
        </router-link>
      </div>

      <!-- FAQ & Step-by-Step Guidance -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div
          v-for="guide in filteredGuides"
          :key="guide.title"
          class="p-6 rounded-2xl border shadow-xl transition-colors"
          :class="isLight ? 'bg-white border-[#C5A059]/35 text-stone-900 shadow-amber-900/5' : 'bg-[#16181F] border-[#C5A059]/30 text-stone-100 shadow-black/80'"
        >
          <div class="flex items-center gap-3 mb-4">
            <span class="text-2xl">{{ guide.icon }}</span>
            <h3 class="font-serif font-bold text-lg" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">{{ guide.title }}</h3>
          </div>
          <p class="text-xs leading-relaxed mb-4" :class="isLight ? 'text-stone-700' : 'text-stone-300'">
            {{ guide.summary }}
          </p>
          <ol
            class="space-y-2 text-xs list-decimal list-inside border-t pt-3"
            :class="isLight ? 'border-stone-200 text-stone-600' : 'border-[#C5A059]/20 text-stone-400'"
          >
            <li v-for="(step, sIdx) in guide.steps" :key="sIdx">
              <span class="font-semibold" :class="isLight ? 'text-stone-900' : 'text-stone-200'">{{ step.title }}:</span>
              {{ step.desc }}
            </li>
          </ol>
        </div>
      </div>

      <!-- Need Direct Support -->
      <div
        class="mt-12 text-center p-8 rounded-2xl border transition-colors"
        :class="isLight ? 'bg-gradient-to-br from-white to-[#FAF6ED] border-[#C5A059]/40 text-stone-900 shadow-md' : 'bg-[#14151B] border-[#C5A059]/30 text-stone-100'"
      >
        <h3 class="text-xl font-serif font-bold" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">Have Questions About Your Branch?</h3>
        <p class="text-xs mt-2 max-w-md mx-auto leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
          The Kkevo family lineage council is here to assist with historical dates, clan verification, and oral genealogy records.
        </p>
        <div class="mt-6 flex justify-center gap-4">
          <router-link
            to="/help/contact"
            class="px-5 py-2.5 rounded-xl font-bold text-xs uppercase tracking-wider text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-110 shadow-md transition-all"
          >
            Contact Family Support
          </router-link>
          <router-link
            to="/tree"
            :class="['px-5 py-2.5 rounded-xl font-bold text-xs uppercase tracking-wider border transition-all',
              isLight ? 'bg-white hover:bg-stone-50 border-[#C5A059] text-stone-800' : 'bg-[#1F2128] hover:bg-[#282B33] border-[#C5A059]/40 text-[#F3E5AB]']"
          >
            Return to Tree View
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useThemeStore } from '@/stores/theme'

const themeStore = useThemeStore()
const isLight = computed(() => themeStore.isLight)

const searchQuery = ref('')

const guides = [
  {
    icon: '⚡',
    title: 'How to Add a Relative with 1 Click',
    summary: 'Anyone can build the family tree easily without complex forms.',
    steps: [
      { title: 'Locate Person', desc: 'Click any person card on the Tree view or in the Family Directory.' },
      { title: 'Click Quick Add', desc: 'Tap the prominent "Add Relative" button.' },
      { title: 'Select Relationship', desc: 'Choose Child, Wife / Husband, Father, or Mother.' },
      { title: 'Enter Name', desc: 'Type their name and click "Add to Family Tree" to link them instantly!' }
    ]
  },
  {
    icon: '🔍',
    title: 'Searching Village & Clan Origins',
    summary: 'Trace lineage back to ancestral homelands and village settlements.',
    steps: [
      { title: 'Open Directory', desc: 'Click "Family Members" in the top navigation.' },
      { title: 'Filter by Village', desc: 'Use the village search input to find all kin hailing from Bafoussam, Yaoundé, Douala, or the diaspora.' },
      { title: 'Inspect Details', desc: 'Click any person card to view their generational depth and direct parents.' }
    ]
  },
  {
    icon: '📸',
    title: 'Preserving Oral Histories & Photos',
    summary: 'Safeguard memories for children and great-grandchildren.',
    steps: [
      { title: 'Visit Vault', desc: 'Navigate to "Photos & Stories" from the top menu.' },
      { title: 'Upload Artifact', desc: 'Click "Upload Memory" and choose your photo, ceremony video, or voice recording.' },
      { title: 'Add Cultural Context', desc: 'Add notes about who was present, the year, and the occasion.' }
    ]
  },
  {
    icon: '👑',
    title: 'Royal Titles & Elder Honors',
    summary: 'Recognizing traditional titles and patriarchal / matriarchal lineage.',
    steps: [
      { title: 'Elder Profiles', desc: 'Elders are adorned with royal crest insignia on the pedigree tree.' },
      { title: 'Direct Lineage', desc: 'Solid antique gold lines indicate direct lineage continuity.' },
      { title: 'Preservation', desc: 'All ancestral entries are safeguarded in the central Kkevo registry.' }
    ]
  }
]

const filteredGuides = computed(() => {
  const q = searchQuery.value.toLowerCase().trim()
  if (!q) return guides
  return guides.filter(g =>
    g.title.toLowerCase().includes(q) ||
    g.summary.toLowerCase().includes(q) ||
    g.steps.some(s => s.title.toLowerCase().includes(q) || s.desc.toLowerCase().includes(q))
  )
})
</script>