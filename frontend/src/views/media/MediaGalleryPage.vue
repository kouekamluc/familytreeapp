<template>
  <div class="app-page-shell py-8 px-4 sm:px-6 lg:px-8 font-sans transition-colors duration-300">
    <div class="max-w-7xl mx-auto">
      <!-- Royal Media Vault Banner -->
      <div
        class="mb-8 p-6 rounded-2xl border shadow-xl flex flex-col md:flex-row md:items-center md:justify-between gap-4 transition-colors"
        :class="isLight ? 'bg-gradient-to-r from-white via-[#FAF6ED] to-white border-[#C5A059]/40 text-stone-900 shadow-amber-900/5' : 'bg-gradient-to-r from-[#171922] via-[#1C1F2B] to-[#171922] border-[#C5A059]/40 text-white shadow-black/80'"
      >
        <div class="flex items-center gap-4">
          <div
            class="w-14 h-14 rounded-2xl border-2 border-[#C5A059] p-1 flex items-center justify-center shadow-lg"
            :class="isLight ? 'bg-amber-50' : 'bg-[#0B0C0E]'"
          >
            <img src="/logo.png" alt="Kkevo Crest" class="w-full h-full object-contain" />
          </div>
          <div>
            <div class="flex items-center gap-2">
              <h1
                class="text-2xl sm:text-3xl font-serif font-black tracking-wider uppercase"
                :class="isLight ? 'text-stone-900' : 'text-transparent bg-clip-text bg-gradient-to-r from-[#F3E5AB] via-[#D4AF37] to-[#C5A059]'"
              >
                Photos & Stories Vault
              </h1>
              <span
                class="px-2.5 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider border"
                :class="isLight ? 'bg-amber-100 text-[#634208] border-[#C5A059]/50' : 'bg-[#C5A059]/20 text-[#F3E5AB] border-[#C5A059]/50'"
              >
                Heritage
              </span>
            </div>
            <p class="text-xs mt-1" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
              Safeguarding historical portraits, oral traditions, ceremonies, and family archives
            </p>
          </div>
        </div>

        <!-- Action Controls -->
        <div class="flex items-center gap-3">
          <router-link
            to="/media/upload"
            class="px-5 py-2.5 rounded-xl font-black text-xs uppercase tracking-wider text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-110 shadow-lg shadow-[#C5A059]/30 transition-all flex items-center gap-2 active:scale-95"
          >
            <span>📸</span>
            <span>Upload Memory</span>
          </router-link>

          <router-link
            to="/tree"
            class="px-4 py-2.5 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 shadow-sm"
            :class="isLight ? 'bg-white hover:bg-stone-100 text-stone-800 border border-[#C5A059]/50' : 'bg-[#1A1C24] hover:bg-[#222530] text-[#F3E5AB] border border-[#C5A059]/50'"
          >
            <span>🌳</span>
            <span>View Tree</span>
          </router-link>
        </div>
      </div>

      <!-- Filters & Search Bar -->
      <div
        class="mb-8 flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4 p-4 rounded-2xl border shadow-lg transition-colors"
        :class="isLight ? 'bg-white border-[#C5A059]/30 shadow-amber-900/5' : 'bg-[#16181F] border-[#C5A059]/30 shadow-black/60'"
      >
        <!-- Search -->
        <div class="relative flex-1 max-w-md">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search stories, people, ceremonies..."
            class="w-full pl-10 pr-4 py-2.5 rounded-xl text-sm transition-colors focus:outline-none focus:ring-1 focus:ring-[#D4AF37]"
            :class="isLight ? 'bg-[#FDFBF7] border border-stone-300 text-stone-900 placeholder-stone-400' : 'bg-[#1F2128] border border-[#C5A059]/40 text-stone-100 placeholder-stone-500'"
          />
          <span class="absolute left-3.5 top-1/2 -translate-y-1/2 text-sm" :class="isLight ? 'text-stone-400' : 'text-stone-500'">🔍</span>
        </div>

        <!-- Filter Pills -->
        <div class="flex flex-wrap gap-2">
          <button
            v-for="tab in filterTabs"
            :key="tab.type"
            @click="filterType = tab.type"
            class="px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer"
            :class="[
              filterType === tab.type
                ? isLight
                  ? 'bg-amber-100 text-[#634208] border-2 border-[#C5A059] font-black shadow-sm'
                  : 'bg-gradient-to-r from-[#C5A059]/30 to-[#D4AF37]/20 text-[#F3E5AB] border border-[#C5A059] shadow-sm'
                : isLight
                  ? 'text-stone-600 hover:text-stone-900 bg-stone-100 border border-transparent'
                  : 'text-stone-400 hover:text-stone-200 bg-[#1F2128] border border-transparent'
            ]"
          >
            {{ tab.label }}
          </button>
        </div>
      </div>

      <!-- Gallery Grid -->
      <div v-if="filteredMedia.length" class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
        <div
          v-for="item in filteredMedia"
          :key="item.id"
          class="rounded-2xl border shadow-xl overflow-hidden cursor-pointer transition-all hover:-translate-y-1 flex flex-col group"
          :class="isLight ? 'bg-white border-[#C5A059]/35 hover:border-[#C5A059] shadow-amber-900/5' : 'bg-[#16181F] border-[#C5A059]/30 hover:border-[#D4AF37] shadow-black/80'"
          @click="goToDetail(item.id)"
        >
          <!-- Image or Media Thumbnail -->
          <div
            class="relative h-48 overflow-hidden flex items-center justify-center border-b"
            :class="isLight ? 'bg-[#FAF6ED] border-[#C5A059]/20' : 'bg-[#0B0C0E] border-[#C5A059]/20'"
          >
            <img
              :src="item.thumbnail"
              :alt="item.title"
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
              @error="handleImageError($event)"
            />
            <div class="absolute top-3 right-3 px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider bg-black/70 text-[#F3E5AB] border border-[#C5A059]/60 backdrop-blur-sm">
              {{ item.typeLabel }}
            </div>
            <div class="absolute bottom-2 left-3 text-[11px] font-bold text-stone-300 bg-black/60 px-2 py-0.5 rounded backdrop-blur-sm">
              {{ item.date || 'Historical' }}
            </div>
          </div>

          <!-- Content Details -->
          <div class="p-4 flex-1 flex flex-col justify-between">
            <div>
              <h3
                class="font-serif font-bold text-base transition-colors truncate"
                :class="isLight ? 'text-stone-900 group-hover:text-[#996515]' : 'text-[#F3E5AB] group-hover:text-white'"
              >
                {{ item.title }}
              </h3>
              <p class="text-xs mt-1 line-clamp-2 leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
                {{ item.description }}
              </p>
            </div>

            <div
              class="mt-4 pt-3 border-t flex items-center justify-between text-xs"
              :class="isLight ? 'border-stone-100 text-stone-500' : 'border-[#C5A059]/20 text-stone-400'"
            >
              <span class="flex items-center gap-1">
                <span>📍</span>
                <span>{{ item.location || 'Ancestral Homeland' }}</span>
              </span>
              <span class="font-bold group-hover:underline" :class="isLight ? 'text-[#855B14]' : 'text-[#D4AF37]'">
                View &rarr;
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div
        v-else
        class="text-center py-20 rounded-2xl border p-8 max-w-xl mx-auto transition-colors"
        :class="isLight ? 'bg-white border-[#C5A059]/30 text-stone-900 shadow-amber-900/5' : 'bg-[#16181F] border-[#C5A059]/30 text-stone-100'"
      >
        <div class="w-16 h-16 mx-auto rounded-full bg-[#D4AF37]/10 border border-[#D4AF37]/40 flex items-center justify-center text-3xl mb-4">
          📜
        </div>
        <h3 class="text-xl font-serif font-bold" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">No Memories Found</h3>
        <p class="text-xs mt-2 max-w-sm mx-auto leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
          No family photos or oral recordings matched your filter. Try clearing your search or upload a new photo.
        </p>
        <button
          @click="searchQuery = ''; filterType = ''"
          class="mt-6 px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer"
          :class="isLight ? 'bg-stone-100 hover:bg-stone-200 text-stone-800 border border-stone-300' : 'bg-[#1F2128] hover:bg-[#282B33] text-[#F3E5AB] border border-[#C5A059]/50'"
        >
          Reset Filters
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useThemeStore } from '@/stores/theme'

const router = useRouter()
const themeStore = useThemeStore()
const isLight = computed(() => themeStore.isLight)

const searchQuery = ref('')
const filterType = ref('')

const filterTabs = [
  { label: 'All Records', type: '' },
  { label: 'Family Portraits', type: 'photo' },
  { label: 'Traditions & Ceremonies', type: 'ceremony' },
  { label: 'Oral Histories', type: 'story' },
  { label: 'Documents', type: 'document' }
]

// Authentic initial heritage items with reliable fallbacks
const mediaItems = ref([
  {
    id: 1,
    title: 'Kkevo Royal Clan Crest & Insignia',
    type: 'photo',
    typeLabel: 'Crest',
    date: 'Heritage',
    location: 'Bafoussam / West Region',
    description: 'The sacred royal crest of the Kkevo lineage symbolizing strength, continuity, and ancestral wisdom.',
    thumbnail: '/logo.png'
  },
  {
    id: 2,
    title: 'Elder Council Gathering & Blessing',
    type: 'ceremony',
    typeLabel: 'Ceremony',
    date: '1984',
    location: 'Family Compound',
    description: 'Historical assembly of clan elders convening to bless the expanding branches and counsel the youth.',
    thumbnail: '/logo.png'
  },
  {
    id: 3,
    title: 'Traditional Wedding of the Heirs',
    type: 'ceremony',
    typeLabel: 'Ceremony',
    date: '1992',
    location: 'Homeland',
    description: 'A joyous traditional alliance ceremony honoring customs, palm wine rites, and ancestral blessings.',
    thumbnail: '/logo.png'
  },
  {
    id: 4,
    title: 'Clan Patriarch Oral Genealogy Recitation',
    type: 'story',
    typeLabel: 'Oral Story',
    date: 'Recorded 2001',
    location: 'Ancestral Homestead',
    description: 'Full tape recording preserving the names and deeds of the earliest recorded Kkevo forebears.',
    thumbnail: '/logo.png'
  }
])

const filteredMedia = computed(() => {
  return mediaItems.value.filter(item => {
    const matchesType = !filterType.value || item.type === filterType.value
    const q = searchQuery.value.toLowerCase().trim()
    const matchesQuery = !q ||
      item.title.toLowerCase().includes(q) ||
      item.description.toLowerCase().includes(q) ||
      (item.location && item.location.toLowerCase().includes(q))
    return matchesType && matchesQuery
  })
})

const goToDetail = (id) => {
  router.push(`/media/${id}`)
}

const handleImageError = (e) => {
  e.target.src = '/logo.png'
}
</script>