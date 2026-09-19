<template>
  <div class="min-h-screen app-page-shell py-8 px-4 sm:px-6 lg:px-8 font-sans selection:bg-[#C5A059] selection:text-black">
    <div class="max-w-6xl mx-auto">
      <!-- Back Link -->
      <div class="mb-6 flex items-center justify-between">
        <router-link
          to="/media"
          class="inline-flex items-center gap-2 text-xs font-bold text-[#D4AF37] hover:underline"
        >
          <span>&larr;</span>
          <span>Return to Photos & Stories Vault</span>
        </router-link>

        <div :class="['w-8 h-8 rounded-xl border border-[#C5A059] p-0.5 flex items-center justify-center', isLight ? 'bg-white shadow-sm' : 'bg-[#0B0C0E]']">
          <img src="/logo.png" alt="Kkevo Crest" class="w-full h-full object-contain" />
        </div>
      </div>

      <!-- Main Viewer Container -->
      <div class="app-card-panel rounded-2xl shadow-2xl overflow-hidden grid grid-cols-1 lg:grid-cols-2 gap-8 p-6 sm:p-8">
        <!-- Media Visual / Audio Player -->
        <div class="space-y-4 flex flex-col justify-between">
          <div :class="['h-80 sm:h-96 rounded-2xl overflow-hidden border flex items-center justify-center p-2 relative group',
            isLight ? 'border-[#C5A059]/30 bg-stone-100' : 'border-[#C5A059]/30 bg-[#0B0C0E]']">
            <img
              :src="media.url || '/logo.png'"
              :alt="media.title"
              class="w-full h-full object-contain"
              @error="handleImageError"
            />
            <div :class="['absolute top-3 left-3 px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-wider border',
              isLight ? 'bg-white/90 text-stone-900 border-[#C5A059]/60 shadow-sm' : 'bg-black/80 text-[#F3E5AB] border-[#C5A059]/60']">
              {{ media.category || 'Historical Archive' }}
            </div>
          </div>

          <!-- Action buttons -->
          <div class="flex gap-3 pt-2">
            <button
              @click="handleDownload"
              class="flex-1 py-3 px-4 rounded-xl font-black text-xs uppercase tracking-wider text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-110 shadow-lg shadow-[#C5A059]/30 transition-all text-center"
            >
              📥 Download Artifact
            </button>
            <button
              @click="handleShare"
              :class="['flex-1 py-3 px-4 rounded-xl font-bold text-xs border transition-all text-center',
                isLight ? 'bg-white text-stone-800 hover:bg-stone-50 border-[#C5A059]/50 shadow-sm' : 'bg-[#1F2128] text-[#F3E5AB] hover:bg-[#282B33] border-[#C5A059]/50']"
            >
              🔗 Share with Clan
            </button>
          </div>
        </div>

        <!-- Details & Annotations -->
        <div class="space-y-6 flex flex-col justify-between">
          <div>
            <h1 :class="['text-2xl sm:text-3xl font-serif font-black', isLight ? 'text-stone-900' : 'text-[#F3E5AB]']">
              {{ media.title }}
            </h1>
            <p :class="['text-xs mt-1', isLight ? 'text-stone-600' : 'text-stone-400']">
              Archived into Kkevo Lineage records on {{ media.date || 'Historical Period' }}
            </p>

            <div class="mt-6 space-y-4">
              <div>
                <h3 class="text-xs font-black uppercase tracking-wider text-[#C5A059]">Story & Significance</h3>
                <p :class="['mt-1 text-sm leading-relaxed', isLight ? 'text-stone-700' : 'text-stone-300']">
                  {{ media.description || 'A cherished artifact commemorating the enduring traditions and lineage continuity of the Kkevo family.' }}
                </p>
              </div>

              <!-- Metadata Grid -->
              <div class="pt-4 border-t border-[#C5A059]/20">
                <h3 class="text-xs font-black uppercase tracking-wider text-[#C5A059] mb-3">Record Details</h3>
                <dl class="grid grid-cols-2 gap-4 text-xs">
                  <div class="p-3 rounded-xl app-sub-panel">
                    <dt :class="isLight ? 'text-stone-500 font-semibold' : 'text-stone-400 font-semibold'">Location / Homeland</dt>
                    <dd :class="['font-bold mt-0.5', isLight ? 'text-stone-900' : 'text-stone-200']">{{ media.location || 'Bafoussam / West Region' }}</dd>
                  </div>
                  <div class="p-3 rounded-xl app-sub-panel">
                    <dt :class="isLight ? 'text-stone-500 font-semibold' : 'text-stone-400 font-semibold'">Document Type</dt>
                    <dd :class="['font-bold mt-0.5 capitalize', isLight ? 'text-stone-900' : 'text-stone-200']">{{ media.type || 'Photograph' }}</dd>
                  </div>
                </dl>
              </div>

              <!-- Linked Kin / Relatives -->
              <div class="pt-4 border-t border-[#C5A059]/20">
                <h3 class="text-xs font-black uppercase tracking-wider text-[#C5A059] mb-3">Associated Relatives</h3>
                <div class="flex flex-wrap gap-2">
                  <router-link
                    to="/people"
                    class="px-3 py-1.5 rounded-lg text-xs font-bold app-sub-panel hover:border-[#D4AF37] text-[#D4AF37] transition-all flex items-center gap-1.5"
                  >
                    <span>👤</span>
                    <span>Luc Kouekam & Branch</span>
                  </router-link>
                  <router-link
                    to="/tree"
                    class="px-3 py-1.5 rounded-lg text-xs font-bold app-sub-panel hover:border-[#D4AF37] text-[#D4AF37] transition-all flex items-center gap-1.5"
                  >
                    <span>🌳</span>
                    <span>Locate on Tree</span>
                  </router-link>
                </div>
              </div>
            </div>
          </div>

          <div class="pt-6 border-t border-[#C5A059]/20 text-xs text-stone-500 flex items-center justify-between">
            <span>Kkevo Heritage Vault #{{ $route.params.id }}</span>
            <router-link to="/media" class="text-[#D4AF37] hover:underline font-bold">
              View All Photos & Stories
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useThemeStore } from '../../stores/theme'

const route = useRoute()
const themeStore = useThemeStore()
const isLight = computed(() => themeStore.isLight)

const media = ref({
  id: route.params.id,
  title: 'Kkevo Royal Clan Crest & Insignia',
  type: 'photo',
  category: 'Royal Regalia',
  date: 'Ancestral Lineage',
  location: 'Homeland Compound',
  description: 'The sacred royal crest of the Kkevo lineage symbolizing strength, continuity, and ancestral wisdom.',
  url: '/logo.png'
})

onMounted(() => {
  const id = Number(route.params.id)
  if (id === 2) {
    media.value.title = 'Elder Council Gathering & Blessing'
    media.value.category = 'Elder Assembly'
    media.value.date = '1984'
  } else if (id === 3) {
    media.value.title = 'Traditional Wedding of the Heirs'
    media.value.category = 'Ceremony'
    media.value.date = '1992'
  } else if (id === 4) {
    media.value.title = 'Clan Patriarch Oral Genealogy Recitation'
    media.value.category = 'Oral Tradition'
    media.value.date = 'Recorded 2001'
  }
})

const handleImageError = (e) => {
  e.target.src = '/logo.png'
}

const handleDownload = () => {
  alert('Downloading artifact from Kkevo vault...')
}

const handleShare = () => {
  if (navigator.clipboard) {
    navigator.clipboard.writeText(window.location.href)
    alert('Link to memory copied to clipboard!')
  } else {
    alert('Share URL: ' + window.location.href)
  }
}
</script>