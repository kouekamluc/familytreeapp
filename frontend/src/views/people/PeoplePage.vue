<template>
  <div class="min-h-screen pb-16 font-sans transition-colors duration-300" :class="isLight ? 'bg-[#FAF8F5] text-stone-900' : 'bg-[#0E0F12] text-stone-100'">
    <!-- Header banner -->
    <div
      class="border-b shadow-lg transition-colors"
      :class="isLight ? 'bg-gradient-to-r from-white via-[#FAF6ED] to-white border-[#C5A059]/40 text-stone-900' : 'bg-[#121316] border-[#C5A059]/40 text-white'"
    >
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div class="flex items-center gap-4">
            <div
              class="w-14 h-14 rounded-2xl border-2 border-[#C5A059] flex items-center justify-center p-1 shadow-md flex-shrink-0"
              :class="isLight ? 'bg-amber-50 shadow-amber-900/10' : 'bg-[#090A0C] shadow-black/50'"
            >
              <img src="/logo.png" alt="Kkevo Family Crest" class="w-full h-full object-contain" />
            </div>
            <div>
              <div class="flex items-center gap-2 text-xs font-black tracking-widest uppercase" :class="isLight ? 'text-[#855B14]' : 'text-[#C5A059]'">
                <span>📖 Kkevo Directory</span>
                <span>•</span>
                <span>{{ filteredPeople.length }} {{ filteredPeople.length === 1 ? 'member' : 'members' }}</span>
              </div>
              <h1
                class="text-3xl font-black tracking-wide font-serif uppercase mt-1"
                :class="isLight ? 'text-stone-900' : 'text-transparent bg-clip-text bg-gradient-to-r from-[#F3E5AB] via-[#D4AF37] to-[#C5A059]'"
              >
                Kkevo Family Members
              </h1>
              <p class="text-sm mt-0.5 font-medium" :class="isLight ? 'text-stone-600' : 'text-[#FDFBF7]/80'">
                Browse, search, and connect everyone in our royal lineage and heritage.
              </p>
            </div>
          </div>

          <!-- Add Member Button -->
          <div class="flex items-center gap-3">
            <button
              @click="openAddModal(null)"
              class="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-2xl bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-105 text-black font-black text-sm shadow-lg shadow-black/20 transition-all transform active:scale-95 cursor-pointer"
            >
              <span class="text-lg leading-none">✨</span>
              <span>+ Add Family Member</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Content Container -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 -mt-4">
      <!-- Search and Filter Bar -->
      <div
        class="rounded-3xl shadow-sm border p-4 mb-8 transition-colors"
        :class="isLight ? 'bg-white border-[#C5A059]/40 shadow-amber-900/5' : 'bg-[#16181F] border-[#C5A059]/40 shadow-black/80'"
      >
        <div class="flex flex-col md:flex-row items-stretch md:items-center gap-4">
          <!-- Search input -->
          <div class="relative flex-1">
            <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-xl">
              🔍
            </div>
            <input
              type="text"
              v-model="searchQuery"
              placeholder="Search by name, village, or hometown..."
              class="w-full pl-12 pr-4 py-3.5 text-base rounded-2xl border-2 transition-all font-medium focus:outline-none focus:ring-2 focus:ring-[#C5A059] focus:border-[#C5A059]"
              :class="isLight ? 'border-stone-200 bg-[#FDFBF7] text-stone-900 placeholder-stone-400' : 'border-[#C5A059]/40 bg-[#1F2128] text-stone-100 placeholder-stone-500'"
            />
            <button
              v-if="searchQuery"
              @click="searchQuery = ''"
              class="absolute inset-y-0 right-0 pr-4 flex items-center text-stone-400 hover:text-stone-600"
            >
              ✕
            </button>
          </div>

          <!-- Filter Pills -->
          <div
            class="flex items-center gap-1.5 p-1.5 rounded-2xl border overflow-x-auto"
            :class="isLight ? 'bg-stone-100 border-stone-200' : 'bg-[#1F2128] border-[#C5A059]/30'"
          >
            <button
              @click="selectedFilter = 'all'"
              class="px-4 py-2 rounded-xl text-xs font-black transition-all whitespace-nowrap cursor-pointer"
              :class="[
                selectedFilter === 'all'
                  ? isLight
                    ? 'bg-[#855B14] text-white shadow-sm'
                    : 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black shadow-sm font-black'
                  : isLight
                    ? 'text-stone-600 hover:text-stone-900'
                    : 'text-[#C5A059] hover:text-white'
              ]"
            >
              All ({{ allCount }})
            </button>
            <button
              @click="selectedFilter = 'living'"
              class="px-4 py-2 rounded-xl text-xs font-black transition-all whitespace-nowrap cursor-pointer"
              :class="[
                selectedFilter === 'living'
                  ? isLight
                    ? 'bg-[#855B14] text-white shadow-sm'
                    : 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black shadow-sm font-black'
                  : isLight
                    ? 'text-stone-600 hover:text-stone-900'
                    : 'text-[#C5A059] hover:text-white'
              ]"
            >
              🌱 Living ({{ livingCount }})
            </button>
            <button
              @click="selectedFilter = 'ancestors'"
              class="px-4 py-2 rounded-xl text-xs font-black transition-all whitespace-nowrap cursor-pointer"
              :class="[
                selectedFilter === 'ancestors'
                  ? isLight
                    ? 'bg-[#855B14] text-white shadow-sm'
                    : 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black shadow-sm font-black'
                  : isLight
                    ? 'text-stone-600 hover:text-stone-900'
                    : 'text-[#C5A059] hover:text-white'
              ]"
            >
              🕊️ Ancestors ({{ ancestorCount }})
            </button>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="text-center py-20">
        <div class="inline-block animate-spin w-10 h-10 border-4 border-[#C5A059] border-t-transparent rounded-full mb-3"></div>
        <p class="text-lg font-black" :class="isLight ? 'text-stone-800' : 'text-stone-200'">Loading Kkevo family members...</p>
      </div>

      <!-- People Cards Grid -->
      <div v-else-if="filteredPeople.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="person in filteredPeople"
          :key="person.id"
          class="rounded-3xl border-2 transition-all duration-200 overflow-hidden flex flex-col justify-between group shadow-sm hover:shadow-xl"
          :class="isLight ? 'bg-white border-[#C5A059]/30 hover:border-[#C5A059] text-stone-900' : 'bg-[#16181F] border-[#C5A059]/40 hover:border-[#D4AF37] text-stone-100 shadow-black/60'"
        >
          <!-- Card Top Info -->
          <div class="p-6">
            <div class="flex items-start gap-4">
              <!-- Avatar -->
              <div class="relative flex-shrink-0">
                <img
                  v-if="person.avatar"
                  :src="person.avatar"
                  :alt="person.name"
                  class="w-16 h-16 rounded-2xl object-cover border-2 border-[#C5A059] shadow-inner"
                />
                <div
                  v-else
                  class="w-16 h-16 rounded-2xl flex items-center justify-center text-3xl shadow-inner border-2 border-[#C5A059]/40"
                  :class="isLight ? 'bg-[#FDFBF7]' : 'bg-[#1F2128]'"
                >
                  {{ getEmojiAvatar(person) }}
                </div>
                <!-- Living status pill -->
                <span
                  class="absolute -bottom-1 -right-1 w-4 h-4 rounded-full border-2 shadow-sm"
                  :class="[
                    person.isLiving ? 'bg-[#C5A059]' : 'bg-stone-400',
                    isLight ? 'border-white' : 'border-[#16181F]'
                  ]"
                  :title="person.isLiving ? 'Living' : 'Ancestor'"
                ></span>
              </div>

              <!-- Name & Lifespan -->
              <div class="flex-1 min-w-0">
                <router-link
                  :to="`/people/${person.id}`"
                  class="text-xl font-black transition-colors line-clamp-1"
                  :class="isLight ? 'text-stone-900 hover:text-[#996515]' : 'text-stone-100 hover:text-[#D4AF37]'"
                >
                  {{ person.name }}
                </router-link>

                <!-- Village / Origin -->
                <p class="text-sm font-bold mt-0.5 flex items-center gap-1.5 truncate" :class="isLight ? 'text-[#674B19]' : 'text-[#C5A059]'">
                  <span class="text-base">📍</span>
                  <span>{{ person.village || person.birthPlace || 'Village not listed' }}</span>
                </p>

                <!-- Dates -->
                <p class="text-xs font-medium mt-1" :class="isLight ? 'text-stone-500' : 'text-stone-400'">
                  <span v-if="person.birthDate">Born {{ formatYear(person.birthDate) }}</span>
                  <span v-else>Birth date unknown</span>
                  <span v-if="!person.isLiving && person.deathDate"> • Passed {{ formatYear(person.deathDate) }}</span>
                </p>
              </div>
            </div>

            <!-- Status Pill & Gender Badge -->
            <div class="mt-4 flex flex-wrap gap-2 items-center">
              <span
                class="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-bold"
                :class="person.isLiving ? (isLight ? 'bg-amber-100 text-[#4A3510]' : 'bg-[#C5A059]/20 text-[#F3E5AB]') : (isLight ? 'bg-stone-100 text-stone-700' : 'bg-stone-800 text-stone-300')"
              >
                {{ person.isLiving ? '🌱 Living' : '🕊️ Ancestor' }}
              </span>
              <span
                class="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-bold border"
                :class="isLight ? 'bg-[#FDFBF7] text-[#674B19] border-[#C5A059]/30' : 'bg-[#1F2128] text-[#F3E5AB] border-[#C5A059]/30'"
              >
                {{ person.gender === 'F' ? '👩 Female' : '👨 Male' }}
              </span>
            </div>
          </div>

          <!-- Bottom Action Buttons -->
          <div
            class="px-6 py-3.5 border-t flex items-center justify-between gap-2"
            :class="isLight ? 'bg-[#FAF7F0] border-[#C5A059]/20' : 'bg-[#121316] border-[#C5A059]/30'"
          >
            <!-- View in Tree -->
            <router-link
              :to="{ path: '/tree', query: { root: person.id } }"
              class="flex-1 text-center py-2 px-2.5 rounded-xl text-xs font-black transition-all flex items-center justify-center gap-1.5 border cursor-pointer"
              :class="isLight ? 'bg-white hover:bg-stone-50 border-[#C5A059]/40 text-stone-900 shadow-sm' : 'bg-[#1F2128] hover:bg-[#282C36] text-[#F3E5AB] border-[#C5A059]/30'"
            >
              <span>🌳</span>
              <span>View in Tree</span>
            </router-link>

            <!-- Quick Add Relative -->
            <button
              @click="openAddModal(person)"
              class="flex-1 text-center py-2 px-2.5 rounded-xl bg-gradient-to-r from-[#B8860B] to-[#C5A059] hover:brightness-105 text-black text-xs font-black shadow-sm transition-all flex items-center justify-center gap-1.5 cursor-pointer"
            >
              <span>➕</span>
              <span>Add Relative</span>
            </button>

            <!-- Full Details Link -->
            <router-link
              :to="`/people/${person.id}`"
              class="py-2 px-3 rounded-xl border text-xs font-bold transition-all"
              :class="isLight ? 'bg-white hover:bg-stone-100 border-stone-200 text-stone-700' : 'bg-[#1C1E25] hover:bg-[#252832] border-[#C5A059]/40 text-[#F3E5AB]'"
              title="View full profile"
            >
              👤
            </router-link>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div
        v-else
        class="rounded-3xl border-2 border-dashed p-12 text-center my-8 shadow-sm transition-colors"
        :class="isLight ? 'bg-white border-[#C5A059]/60 text-stone-900' : 'bg-[#16181F] border-[#C5A059]/60 text-stone-100'"
      >
        <div
          class="w-20 h-20 mx-auto rounded-3xl border-2 border-[#C5A059] flex items-center justify-center p-2 mb-4 shadow-xl"
          :class="isLight ? 'bg-amber-50' : 'bg-[#121316]'"
        >
          <img src="/logo.png" alt="Kkevo Crest" class="w-full h-full object-contain" />
        </div>
        <h3 class="text-2xl font-black mb-2" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">
          {{ searchQuery ? 'No family members found' : 'Start Your Kkevo Family Directory' }}
        </h3>
        <p class="text-base max-w-md mx-auto mb-6" :class="isLight ? 'text-stone-600' : 'text-stone-300'">
          {{ searchQuery ? `We couldn't find anyone matching "${searchQuery}". Try another name or village.` : 'Add your parents, children, or grandparents to begin recording your family heritage.' }}
        </p>
        <div class="flex items-center justify-center gap-3 flex-wrap">
          <button
            v-if="searchQuery"
            @click="searchQuery = ''"
            class="inline-flex items-center gap-2 px-5 py-3 rounded-2xl border text-xs font-bold transition-all cursor-pointer"
            :class="isLight ? 'bg-stone-100 hover:bg-stone-200 text-stone-800 border-stone-300' : 'bg-[#1F2128] hover:bg-[#282C36] text-[#F3E5AB] border-[#C5A059]/40'"
          >
            <span>✕</span>
            <span>Clear Search</span>
          </button>
          <button
            @click="openAddModal(null)"
            class="inline-flex items-center gap-2 px-6 py-3.5 rounded-2xl bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] text-black font-black text-xs shadow-lg shadow-black/20 transition-all cursor-pointer"
          >
            <span>✨</span>
            <span>{{ searchQuery ? '+ Add Person Anyway' : '+ Add First Family Member' }}</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Quick Add Relative Modal -->
    <QuickAddRelativeModal
      :is-open="showAddModal"
      :target-person="modalTargetPerson"
      initial-relation="child"
      @close="showAddModal = false"
      @created="onPersonCreated"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { usePeopleStore } from '@/stores/people'
import { useThemeStore } from '@/stores/theme'
import QuickAddRelativeModal from '@/components/QuickAddRelativeModal.vue'

const peopleStore = usePeopleStore()
const themeStore = useThemeStore()
const isLight = computed(() => themeStore.isLight)

// State
const searchQuery = ref('')
const selectedFilter = ref('all') // 'all' | 'living' | 'ancestors'
const loading = ref(false)

// Modal State
const showAddModal = ref(false)
const modalTargetPerson = ref(null)

const openAddModal = (person) => {
  modalTargetPerson.value = person
  showAddModal.value = true
}

const onPersonCreated = async () => {
  await peopleStore.fetchPeople()
}

onMounted(async () => {
  loading.value = true
  try {
    await peopleStore.fetchPeople()
  } finally {
    loading.value = false
  }
})

// Normalized People List
const normalizedPeople = computed(() => {
  const list = Array.isArray(peopleStore.people)
    ? peopleStore.people
    : (peopleStore.people?.results || [])

  return list.map(p => {
    const firstName = p.first_name || p.firstName || ''
    const lastName = p.last_name || p.lastName || ''
    const name = `${firstName} ${lastName}`.trim() || 'Unknown'
    const birthDate = p.date_of_birth || p.birthDate || null
    const deathDate = p.date_of_death || p.deathDate || null
    const birthYear = birthDate ? parseInt(birthDate.slice(0, 4)) : null
    const isAncestor = p.is_living === false || !!deathDate || ((p.generation_tier || p.generationTier) <= 1 && birthYear && birthYear < 1950)
    const isLiving = !isAncestor
    const village = p.birth_place || p.birthPlace || p.village || ''
    const avatar = p.profile_picture || p.avatar || null

    return {
      ...p,
      firstName,
      lastName,
      name,
      birthDate,
      deathDate,
      isLiving,
      isAncestor,
      village,
      avatar
    }
  })
})

const allCount = computed(() => normalizedPeople.value.length)
const livingCount = computed(() => normalizedPeople.value.filter(p => p.isLiving).length)
const ancestorCount = computed(() => normalizedPeople.value.filter(p => p.isAncestor).length)

// Filtered People
const filteredPeople = computed(() => {
  let list = normalizedPeople.value

  // Search filter
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase().trim()
    list = list.filter(p =>
      p.name.toLowerCase().includes(q) ||
      (p.village && p.village.toLowerCase().includes(q))
    )
  }

  // Status filter
  if (selectedFilter.value === 'living') {
    list = list.filter(p => p.isLiving)
  } else if (selectedFilter.value === 'ancestors') {
    list = list.filter(p => p.isAncestor)
  }

  // Sort alphabetically by last name then first name
  return list.sort((a, b) => a.name.localeCompare(b.name))
})

const formatYear = (dateStr) => {
  if (!dateStr) return ''
  return dateStr.slice(0, 4)
}

const getEmojiAvatar = (person) => {
  const birthYear = person.birthDate ? parseInt(person.birthDate.slice(0, 4)) : null
  const isElder = !person.isLiving || (birthYear && birthYear < 1965)

  if (person.gender === 'F') {
    return isElder ? '👵' : '👩'
  } else {
    return isElder ? '👴' : '👨'
  }
}
</script>