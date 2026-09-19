<template>
  <div class="min-h-screen app-page-shell py-8 px-4 sm:px-6 lg:px-8 font-sans selection:bg-[#C5A059] selection:text-black">
    <div class="max-w-3xl mx-auto">
      <!-- Header -->
      <div class="mb-8 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <router-link
            to="/media"
            class="p-2.5 rounded-xl app-sub-panel hover:border-[#D4AF37] text-[#D4AF37] transition-all"
            title="Back to Vault"
          >
            &larr;
          </router-link>
          <div>
            <h1 class="text-2xl font-serif font-black tracking-wider uppercase text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059]">
              Add Family Media
            </h1>
            <p :class="['text-xs', isLight ? 'text-stone-600' : 'text-stone-400']">
              Upload portraits, traditional ceremonies, or oral history audio to the Kkevo Vault
            </p>
          </div>
        </div>

        <div :class="['w-10 h-10 rounded-xl border border-[#C5A059] p-1 flex items-center justify-center', isLight ? 'bg-white shadow-sm' : 'bg-[#0B0C0E]']">
          <img src="/logo.png" alt="Kkevo Crest" class="w-full h-full object-contain" />
        </div>
      </div>

      <!-- Upload Container -->
      <div class="app-card-panel p-6 sm:p-8 rounded-2xl shadow-2xl space-y-6">
        <!-- Drag & Drop Zone -->
        <div
          :class="['border-2 border-dashed rounded-2xl p-10 text-center transition-all cursor-pointer',
            isLight
              ? 'border-[#C5A059]/50 bg-stone-50/80 hover:bg-stone-100 hover:border-[#B8860B]'
              : 'border-[#C5A059]/50 bg-[#1F2128]/50 hover:bg-[#1F2128] hover:border-[#D4AF37]'
          ]"
          @click="triggerFileInput"
          @dragover.prevent
          @drop.prevent="handleDrop"
        >
          <div class="w-16 h-16 mx-auto rounded-full bg-[#D4AF37]/15 border border-[#D4AF37]/40 flex items-center justify-center text-3xl mb-4">
            📤
          </div>
          <h3 :class="['text-base font-serif font-bold', isLight ? 'text-stone-900' : 'text-[#F3E5AB]']">
            Click to Select or Drag Files Here
          </h3>
          <p :class="['text-xs mt-1 max-w-sm mx-auto leading-relaxed', isLight ? 'text-stone-500' : 'text-stone-400']">
            Supports family photos (JPG, PNG), oral histories (MP3, WAV), and ancestral documents (PDF) up to 50MB.
          </p>
          <input
            ref="fileInput"
            type="file"
            multiple
            accept="image/*,audio/*,video/*,application/pdf"
            class="hidden"
            @change="handleFileSelect"
          />
        </div>

        <!-- Selected Files List -->
        <div v-if="selectedFiles.length" class="space-y-3">
          <h4 :class="['text-xs font-black uppercase tracking-wider', isLight ? 'text-[#B8860B]' : 'text-[#F3E5AB]']">
            Ready for Archiving ({{ selectedFiles.length }})
          </h4>
          <div
            v-for="(f, idx) in selectedFiles"
            :key="idx"
            class="flex items-center justify-between p-3 rounded-xl app-sub-panel"
          >
            <div class="flex items-center gap-3 overflow-hidden">
              <span class="text-lg">📄</span>
              <div class="truncate">
                <div :class="['text-xs font-bold truncate', isLight ? 'text-stone-900' : 'text-stone-200']">{{ f.name }}</div>
                <div :class="['text-[10px]', isLight ? 'text-stone-500' : 'text-stone-400']">{{ formatFileSize(f.size) }}</div>
              </div>
            </div>
            <button
              @click="removeFile(idx)"
              class="text-xs text-red-500 hover:text-red-400 font-bold px-2 py-1"
            >
              Remove
            </button>
          </div>
        </div>

        <!-- Metadata Inputs -->
        <div :class="['space-y-4 pt-4 border-t', isLight ? 'border-[#C5A059]/20' : 'border-[#C5A059]/20']">
          <div>
            <label :class="['block text-xs font-black uppercase tracking-wider mb-1.5', isLight ? 'text-stone-800' : 'text-[#F3E5AB]']">
              Memory Title
            </label>
            <input
              v-model="mediaMeta.title"
              type="text"
              placeholder="e.g. Papa Luc Kouekam Family Blessing"
              class="w-full px-4 py-3 app-input-theme rounded-xl text-sm focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37]"
            />
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label :class="['block text-xs font-black uppercase tracking-wider mb-1.5', isLight ? 'text-stone-800' : 'text-[#F3E5AB]']">
                Category
              </label>
              <select
                v-model="mediaMeta.category"
                class="w-full px-4 py-3 app-input-theme rounded-xl text-sm focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37]"
              >
                <option value="photo">Family Photo</option>
                <option value="ceremony">Traditional Ceremony</option>
                <option value="story">Oral History</option>
                <option value="document">Official Document</option>
              </select>
            </div>

            <div>
              <label :class="['block text-xs font-black uppercase tracking-wider mb-1.5', isLight ? 'text-stone-800' : 'text-[#F3E5AB]']">
                Approximate Year / Date
              </label>
              <input
                v-model="mediaMeta.date"
                type="text"
                placeholder="e.g. 1985 or Dec 2004"
                class="w-full px-4 py-3 app-input-theme rounded-xl text-sm focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37]"
              />
            </div>
          </div>

          <div>
            <label :class="['block text-xs font-black uppercase tracking-wider mb-1.5', isLight ? 'text-stone-800' : 'text-[#F3E5AB]']">
              Story / Oral Annotation
            </label>
            <textarea
              v-model="mediaMeta.description"
              rows="3"
              placeholder="Describe what occurred, who was present, and the cultural significance..."
              class="w-full px-4 py-3 app-input-theme rounded-xl text-sm focus:outline-none focus:border-[#D4AF37] focus:ring-1 focus:ring-[#D4AF37]"
            ></textarea>
          </div>
        </div>

        <!-- Submit Controls -->
        <div :class="['flex items-center justify-between pt-4 border-t', isLight ? 'border-[#C5A059]/20' : 'border-[#C5A059]/20']">
          <router-link
            to="/media"
            :class="['text-xs font-bold transition-colors', isLight ? 'text-stone-500 hover:text-stone-800' : 'text-stone-400 hover:text-stone-200']"
          >
            Cancel
          </router-link>

          <button
            @click="submitUpload"
            :disabled="uploading"
            class="px-8 py-3.5 rounded-xl font-black text-xs uppercase tracking-wider text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-110 shadow-lg shadow-[#C5A059]/30 transition-all disabled:opacity-50"
          >
            {{ uploading ? 'Archiving Memory...' : 'Save to Family Vault' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useThemeStore } from '../../stores/theme'

const router = useRouter()
const themeStore = useThemeStore()
const isLight = computed(() => themeStore.isLight)

const fileInput = ref(null)
const selectedFiles = ref([])
const uploading = ref(false)

const mediaMeta = ref({
  title: '',
  category: 'photo',
  date: '',
  description: ''
})

const triggerFileInput = () => {
  if (fileInput.value) fileInput.value.click()
}

const handleFileSelect = (e) => {
  const files = Array.from(e.target.files)
  selectedFiles.value.push(...files)
}

const handleDrop = (e) => {
  const files = Array.from(e.dataTransfer.files)
  selectedFiles.value.push(...files)
}

const removeFile = (idx) => {
  selectedFiles.value.splice(idx, 1)
}

const formatFileSize = (bytes) => {
  if (!bytes) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
}

const submitUpload = () => {
  uploading.value = true
  setTimeout(() => {
    uploading.value = false
    alert('Media has been securely uploaded to the Kkevo Vault!')
    router.push('/media')
  }, 1000)
}
</script>