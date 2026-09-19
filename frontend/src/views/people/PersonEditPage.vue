<template>
  <div class="min-h-screen pb-16 font-sans transition-colors duration-300" :class="isLight ? 'bg-[#FAF8F5] text-stone-900' : 'bg-[#0E0F12] text-stone-100'">
    <!-- Top Header -->
    <div
      class="border-b shadow-lg transition-colors"
      :class="isLight ? 'bg-gradient-to-r from-white via-[#FAF6ED] to-white border-[#C5A059]/40 text-stone-900' : 'bg-[#121316] border-[#C5A059]/40 text-white'"
    >
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Breadcrumbs Navigation Bar -->
        <nav aria-label="Breadcrumb" class="flex items-center gap-2 text-xs font-black mb-6 flex-wrap">
          <router-link
            to="/tree"
            class="inline-flex items-center gap-1.5 transition-colors uppercase tracking-wider"
            :class="isLight ? 'text-stone-600 hover:text-stone-900' : 'text-stone-400 hover:text-stone-100'"
          >
            <span>🌳</span>
            <span>Family Tree</span>
          </router-link>
          <span class="opacity-40 font-bold" :class="isLight ? 'text-stone-400' : 'text-stone-600'">/</span>
          <router-link
            to="/people"
            class="inline-flex items-center gap-1.5 transition-colors uppercase tracking-wider"
            :class="isLight ? 'text-stone-600 hover:text-stone-900' : 'text-stone-400 hover:text-stone-100'"
          >
            <span>👥</span>
            <span>Family Members</span>
          </router-link>
          <span class="opacity-40 font-bold" :class="isLight ? 'text-stone-400' : 'text-stone-600'">/</span>
          <router-link
            :to="`/people/${route.params.id}`"
            class="inline-flex items-center gap-1.5 transition-colors uppercase tracking-wider truncate max-w-[150px] sm:max-w-none"
            :class="isLight ? 'text-stone-600 hover:text-stone-900' : 'text-stone-400 hover:text-stone-100'"
          >
            <span>{{ form.first_name }} {{ form.last_name }}</span>
          </router-link>
          <span class="opacity-40 font-bold" :class="isLight ? 'text-stone-400' : 'text-stone-600'">/</span>
          <span
            class="font-black uppercase tracking-wider"
            :class="isLight ? 'text-[#855B14]' : 'text-[#D4AF37]'"
          >
            ✏️ Edit Profile
          </span>
        </nav>

        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div class="flex items-center gap-3">
            <div
              class="w-12 h-12 rounded-2xl flex items-center justify-center text-2xl border-2 border-[#C5A059] shadow-md"
              :class="isLight ? 'bg-amber-50 text-[#855B14]' : 'bg-[#1A1C22] text-[#F3E5AB]'"
            >
              ✏️
            </div>
            <div>
              <h1
                class="text-2xl sm:text-3xl font-black font-serif uppercase tracking-wide"
                :class="isLight ? 'text-stone-900' : 'text-transparent bg-clip-text bg-gradient-to-r from-[#F3E5AB] via-[#D4AF37] to-[#C5A059]'"
              >
                Edit Family Member
              </h1>
              <p class="text-xs font-medium" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
                Update profile, traditional name, village, and oral lineage
              </p>
            </div>
          </div>

          <button
            type="button"
            @click="deletePerson"
            class="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-black border border-red-500/40 text-red-500 hover:bg-red-500 hover:text-white transition-all cursor-pointer self-start sm:self-auto"
          >
            <span>🗑️</span>
            <span>Delete Member</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Main Form Container -->
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 -mt-4">
      <form @submit.prevent="savePerson" class="space-y-6">
        <!-- African Cultural Lineage Section (Highlight Card) -->
        <div
          class="rounded-3xl shadow-sm border p-6 transition-colors"
          :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900 shadow-amber-950/5' : 'bg-[#16181F] border-[#C5A059]/40 text-stone-100 shadow-black/80'"
        >
          <div class="flex items-center gap-2 mb-4">
            <span class="text-xl">👑</span>
            <h2 class="text-lg font-black font-serif uppercase tracking-wide" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">
              African Cultural Lineage & Clan Identity
            </h2>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <!-- Traditional Name / Nom Coutumier -->
            <div>
              <label class="block text-xs font-black uppercase tracking-wider mb-1" :class="isLight ? 'text-stone-700' : 'text-[#F3E5AB]'">
                Nom Coutumier / Titre
              </label>
              <input
                type="text"
                v-model="person.traditionalName"
                placeholder="e.g. Nji, Tadji, Ma'ah, Fo..."
                class="w-full px-4 py-2.5 rounded-xl border text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-[#C5A059] transition-colors"
                :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/40 text-stone-900 placeholder-stone-400' : 'bg-[#1F2128] border-[#C5A059]/40 text-white placeholder-stone-500'"
              />
              <span class="text-[10px] block mt-1" :class="isLight ? 'text-stone-500' : 'text-stone-400'">Honorific or customary family title</span>
            </div>

            <!-- Village of Origin / Chefferie -->
            <div>
              <label class="block text-xs font-black uppercase tracking-wider mb-1" :class="isLight ? 'text-stone-700' : 'text-[#F3E5AB]'">
                Village d'Origine / Chefferie
              </label>
              <input
                type="text"
                v-model="person.villageOfOrigin"
                placeholder="e.g. Bandjoun, Bafoussam, Dschang..."
                class="w-full px-4 py-2.5 rounded-xl border text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-[#C5A059] transition-colors"
                :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/40 text-stone-900 placeholder-stone-400' : 'bg-[#1F2128] border-[#C5A059]/40 text-white placeholder-stone-500'"
              />
              <span class="text-[10px] block mt-1" :class="isLight ? 'text-stone-500' : 'text-stone-400'">Ancestral village, kingdom, or region</span>
            </div>

            <!-- Clan Totem / Symbole -->
            <div>
              <label class="block text-xs font-black uppercase tracking-wider mb-1" :class="isLight ? 'text-stone-700' : 'text-[#F3E5AB]'">
                Totem du Clan / Symbole
              </label>
              <input
                type="text"
                v-model="person.clanTotem"
                placeholder="e.g. Leopard 🐆, Elephant 🐘, Lion 🦁"
                class="w-full px-4 py-2.5 rounded-xl border text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-[#C5A059] transition-colors"
                :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/40 text-stone-900 placeholder-stone-400' : 'bg-[#1F2128] border-[#C5A059]/40 text-white placeholder-stone-500'"
              />
              <span class="text-[10px] block mt-1" :class="isLight ? 'text-stone-500' : 'text-stone-400'">Clan protector symbol or emblem</span>
            </div>
          </div>
        </div>

        <!-- Basic Civil Information -->
        <div
          class="rounded-3xl shadow-sm border p-6 transition-colors"
          :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900 shadow-amber-950/5' : 'bg-[#16181F] border-[#C5A059]/40 text-stone-100 shadow-black/80'"
        >
          <div class="flex items-center gap-2 mb-4">
            <span class="text-xl">👤</span>
            <h2 class="text-lg font-black font-serif uppercase tracking-wide" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">
              Civil Identity & Birth
            </h2>
          </div>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <!-- First Name -->
            <div>
              <label class="block text-xs font-black uppercase tracking-wider mb-1" :class="isLight ? 'text-stone-700' : 'text-[#F3E5AB]'">
                First Name *
              </label>
              <input
                type="text"
                v-model="person.firstName"
                required
                class="w-full px-4 py-2.5 rounded-xl border text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-[#C5A059] transition-colors"
                :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/40 text-stone-900' : 'bg-[#1F2128] border-[#C5A059]/40 text-white'"
              />
            </div>

            <!-- Last Name -->
            <div>
              <label class="block text-xs font-black uppercase tracking-wider mb-1" :class="isLight ? 'text-stone-700' : 'text-[#F3E5AB]'">
                Last Name *
              </label>
              <input
                type="text"
                v-model="person.lastName"
                required
                class="w-full px-4 py-2.5 rounded-xl border text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-[#C5A059] transition-colors"
                :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/40 text-stone-900' : 'bg-[#1F2128] border-[#C5A059]/40 text-white'"
              />
            </div>

            <!-- Gender -->
            <div>
              <label class="block text-xs font-black uppercase tracking-wider mb-1" :class="isLight ? 'text-stone-700' : 'text-[#F3E5AB]'">
                Gender *
              </label>
              <select
                v-model="person.gender"
                required
                class="w-full px-4 py-2.5 rounded-xl border text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-[#C5A059] transition-colors"
                :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/40 text-stone-900' : 'bg-[#1F2128] border-[#C5A059]/40 text-white'"
              >
                <option value="M">Male (Homme)</option>
                <option value="F">Female (Femme)</option>
                <option value="O">Other</option>
              </select>
            </div>

            <!-- Birth Date -->
            <div>
              <label class="block text-xs font-black uppercase tracking-wider mb-1" :class="isLight ? 'text-stone-700' : 'text-[#F3E5AB]'">
                Birth Date
              </label>
              <input
                type="date"
                v-model="person.birthDate"
                class="w-full px-4 py-2.5 rounded-xl border text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-[#C5A059] transition-colors"
                :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/40 text-stone-900' : 'bg-[#1F2128] border-[#C5A059]/40 text-white'"
              />
            </div>

            <!-- Birth Place -->
            <div>
              <label class="block text-xs font-black uppercase tracking-wider mb-1" :class="isLight ? 'text-stone-700' : 'text-[#F3E5AB]'">
                Birth Place / City
              </label>
              <input
                type="text"
                v-model="person.birthPlace"
                placeholder="e.g. Yaoundé, Douala, Paris..."
                class="w-full px-4 py-2.5 rounded-xl border text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-[#C5A059] transition-colors"
                :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/40 text-stone-900' : 'bg-[#1F2128] border-[#C5A059]/40 text-white'"
              />
            </div>

            <!-- Death Date (if Ancestor) -->
            <div>
              <label class="block text-xs font-black uppercase tracking-wider mb-1" :class="isLight ? 'text-stone-700' : 'text-[#F3E5AB]'">
                Passing Date (If Ancestor)
              </label>
              <input
                type="date"
                v-model="person.deathDate"
                class="w-full px-4 py-2.5 rounded-xl border text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-[#C5A059] transition-colors"
                :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/40 text-stone-900' : 'bg-[#1F2128] border-[#C5A059]/40 text-white'"
              />
            </div>
          </div>
        </div>

        <!-- Biography / Oral Notes -->
        <div
          class="rounded-3xl shadow-sm border p-6 transition-colors"
          :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900 shadow-amber-950/5' : 'bg-[#16181F] border-[#C5A059]/40 text-stone-100 shadow-black/80'"
        >
          <div class="flex items-center gap-2 mb-4">
            <span class="text-xl">📖</span>
            <h2 class="text-lg font-black font-serif uppercase tracking-wide" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">
              Biography & Family Stories
            </h2>
          </div>

          <div>
            <textarea
              v-model="person.notes"
              rows="4"
              placeholder="Record cherished stories, life milestones, lineage memory, or anecdotes passed down..."
              class="w-full px-4 py-3 rounded-xl border text-sm font-medium focus:outline-none focus:ring-2 focus:ring-[#C5A059] transition-colors"
              :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/40 text-stone-900 placeholder-stone-400' : 'bg-[#1F2128] border-[#C5A059]/40 text-white placeholder-stone-500'"
            ></textarea>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex items-center justify-end gap-3 pt-4">
          <button
            type="button"
            @click="cancel"
            class="px-6 py-3 rounded-2xl font-black text-sm border transition-all cursor-pointer"
            :class="isLight ? 'bg-white hover:bg-stone-50 text-stone-700 border-stone-300' : 'bg-[#1A1C22] hover:bg-[#252832] text-stone-300 border-stone-700'"
          >
            Cancel
          </button>
          <button
            type="submit"
            :disabled="saving"
            class="px-8 py-3 rounded-2xl bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-105 text-black font-black text-sm shadow-lg shadow-black/20 transition-all transform active:scale-95 cursor-pointer disabled:opacity-50"
          >
            {{ saving ? 'Saving Changes...' : '✨ Save Changes' }}
          </button>
        </div>
      </form>
    </div>

    <!-- Delete Confirmation Modal -->
    <div
      v-if="showDeleteModal"
      class="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4"
    >
      <div
        class="rounded-3xl max-w-md w-full p-6 border-2 border-red-500/50 shadow-2xl"
        :class="isLight ? 'bg-white text-stone-900' : 'bg-[#16181F] text-stone-100'"
      >
        <div class="w-12 h-12 rounded-2xl bg-red-500/20 text-red-500 flex items-center justify-center text-2xl mb-4">
          ⚠️
        </div>
        <h3 class="text-xl font-black font-serif uppercase tracking-wide text-red-500 mb-2">
          Confirm Deletion
        </h3>
        <p class="text-sm font-medium mb-6" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
          Are you sure you want to remove this family member from the clan? Any immediate parent-child ties connected to this person will be unlinked.
        </p>
        <div class="flex items-center justify-end gap-3">
          <button
            type="button"
            @click="showDeleteModal = false"
            class="px-5 py-2.5 rounded-xl font-bold text-xs border cursor-pointer"
            :class="isLight ? 'bg-stone-100 text-stone-700 border-stone-300' : 'bg-stone-800 text-stone-300 border-stone-700'"
          >
            Cancel
          </button>
          <button
            type="button"
            @click="confirmDelete"
            class="px-5 py-2.5 rounded-xl font-black text-xs bg-red-600 hover:bg-red-700 text-white cursor-pointer"
          >
            Confirm Delete
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useToast } from 'vue-toastification'
import { usePeopleStore } from '@/stores/people'
import { useThemeStore } from '@/stores/theme'

const router = useRouter()
const route = useRoute()
const toast = useToast()
const peopleStore = usePeopleStore()
const themeStore = useThemeStore()

const isLight = computed(() => themeStore.isLight)
const saving = ref(false)
const showDeleteModal = ref(false)

const person = ref({
  firstName: '',
  lastName: '',
  traditionalName: '',
  villageOfOrigin: '',
  clanTotem: '',
  gender: 'M',
  birthDate: '',
  birthPlace: '',
  deathDate: '',
  notes: ''
})

onMounted(async () => {
  try {
    const personId = route.params.id
    const data = await peopleStore.fetchPersonDetails(personId)
    if (data) {
      person.value = {
        firstName: data.first_name || data.firstName || '',
        lastName: data.last_name || data.lastName || '',
        traditionalName: data.traditional_name || data.traditionalName || '',
        villageOfOrigin: data.village_of_origin || data.villageOfOrigin || data.birth_place || '',
        clanTotem: data.clan_totem || data.clanTotem || '',
        gender: data.gender === 'Female' ? 'F' : (data.gender === 'Male' ? 'M' : (data.gender || 'M')),
        birthDate: data.date_of_birth || data.birthDate || '',
        birthPlace: data.birth_place || data.birthPlace || '',
        deathDate: data.date_of_death || data.deathDate || '',
        notes: data.biography || ''
      }
    }
  } catch (error) {
    toast.error('Failed to load person data')
    console.error('Error loading person:', error)
  }
})

const cancel = () => {
  router.push(`/people/${route.params.id}`)
}

const savePerson = async () => {
  saving.value = true
  try {
    const personId = route.params.id
    const payload = {
      first_name: person.value.firstName,
      last_name: person.value.lastName,
      traditional_name: person.value.traditionalName,
      village_of_origin: person.value.villageOfOrigin,
      clan_totem: person.value.clanTotem,
      gender: person.value.gender,
      date_of_birth: person.value.birthDate || null,
      birth_place: person.value.birthPlace,
      date_of_death: person.value.deathDate || null,
      biography: person.value.notes
    }

    await peopleStore.updatePerson(personId, payload)
    toast.success('Family member updated!')
    router.push(`/people/${personId}`)
  } catch (error) {
    toast.error('Failed to update person')
    console.error('Error updating person:', error)
  } finally {
    saving.value = false
  }
}

const deletePerson = () => {
  showDeleteModal.value = true
}

const confirmDelete = async () => {
  try {
    const personId = route.params.id
    await peopleStore.deletePerson(personId)
    showDeleteModal.value = false
    toast.success('Member removed from tree')
    router.push('/people')
  } catch (error) {
    toast.error('Failed to delete person')
    console.error('Error deleting person:', error)
  }
}
</script>