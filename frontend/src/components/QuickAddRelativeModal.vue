<template>
  <div v-if="isOpen" class="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
    <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
      <!-- Background overlay -->
      <div class="fixed inset-0 bg-gray-900 bg-opacity-60 transition-opacity" @click="$emit('close')"></div>

      <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>

      <!-- Modal panel -->
      <div
        class="inline-block align-bottom rounded-3xl text-left overflow-hidden shadow-2xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full border-2"
        :class="isLight ? 'bg-white text-stone-900 border-[#C5A059]' : 'bg-[#16181F] text-stone-100 border-[#C5A059]'"
      >
        <!-- Kkevo Royal Header -->
        <div
          class="px-6 py-4 flex items-center justify-between border-b"
          :class="isLight ? 'bg-gradient-to-r from-white via-amber-50/60 to-white text-stone-900 border-[#C5A059]/40' : 'bg-[#121316] text-white border-[#C5A059]/40'"
        >
          <div class="flex items-center space-x-3">
            <div
              class="w-11 h-11 rounded-xl border border-[#C5A059] flex items-center justify-center p-1 shadow-inner flex-shrink-0"
              :class="isLight ? 'bg-amber-50' : 'bg-[#0B0C0E]'"
            >
              <img src="/logo.png" alt="Kkevo Logo" class="w-full h-full object-contain" />
            </div>
            <div>
              <h3
                class="text-lg font-black leading-tight font-serif uppercase tracking-wide"
                :class="isLight ? 'text-stone-900' : 'text-transparent bg-clip-text bg-gradient-to-r from-[#F3E5AB] via-[#D4AF37] to-[#C5A059]'"
                id="modal-title"
              >
                {{ targetPerson ? 'Add to Kkevo Family' : 'Add Family Member' }}
              </h3>
              <p class="text-xs font-semibold" :class="isLight ? 'text-[#855B14]' : 'text-[#C5A059]'">
                <span v-if="targetPerson">Connected to <span class="px-2 py-0.5 rounded-md font-bold" :class="isLight ? 'bg-amber-100/70 text-[#634208] border border-[#C5A059]/40' : 'bg-[#1D1F25] text-[#F3E5AB] border border-[#C5A059]/40'">{{ targetPersonName }}</span></span>
                <span v-else>Record their heritage details</span>
              </p>
            </div>
          </div>
          <button
            @click="$emit('close')"
            class="w-8 h-8 rounded-full flex items-center justify-center transition-colors cursor-pointer"
            :class="isLight ? 'bg-stone-100 hover:bg-stone-200 text-stone-700' : 'bg-white/10 hover:bg-white/20 text-[#C5A059]'"
          >
            ✕
          </button>
        </div>

        <!-- Form Body -->
        <form @submit.prevent="handleSubmit" class="p-6 space-y-4">
          <!-- Big 4 Relationship Tiles (only if targetPerson is present) -->
          <div v-if="targetPerson">
            <label
              class="block text-xs font-black uppercase tracking-wider mb-2"
              :class="isLight ? 'text-[#634208]' : 'text-[#F3E5AB]'"
            >
              Who are you adding to {{ targetPersonName }}?
            </label>
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
              <button
                type="button"
                v-for="rel in relationships"
                :key="rel.id"
                @click="selectRelationship(rel.id)"
                class="py-3 px-2 rounded-2xl border-2 text-center transition-all flex flex-col items-center gap-1 shadow-sm cursor-pointer"
                :class="[
                  selectedRelation === rel.id
                    ? isLight
                      ? 'border-[#C5A059] bg-[#FDFBF7] text-black font-black ring-2 ring-[#C5A059] scale-102 shadow-md'
                      : 'border-[#C5A059] bg-[#222530] text-[#F3E5AB] font-black ring-2 ring-[#C5A059] scale-102 shadow-md'
                    : isLight
                      ? 'border-stone-200 bg-white text-stone-700 hover:bg-stone-50'
                      : 'border-[#C5A059]/30 bg-[#1C1E25] text-stone-300 hover:bg-[#252832]'
                ]"
              >
                <span class="text-2xl">{{ rel.icon }}</span>
                <span class="text-xs font-black leading-tight">{{ rel.label }}</span>
                <span class="text-[10px] font-normal" :class="isLight ? 'text-stone-500' : 'text-stone-400'">{{ rel.sub }}</span>
              </button>
            </div>
          </div>

          <!-- Name fields -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
            <div>
              <label class="block text-xs font-bold mb-1" :class="isLight ? 'text-stone-800' : 'text-stone-200'">First Name *</label>
              <input
                type="text"
                v-model="form.firstName"
                required
                placeholder="e.g. Papa Jean, Marie, Lucas"
                class="w-full px-3.5 py-2.5 text-base border-2 rounded-xl focus:ring-2 focus:ring-[#C5A059] focus:border-[#C5A059] transition-colors"
                :class="isLight ? 'bg-white border-stone-200 text-stone-900 placeholder-stone-400' : 'bg-[#1F2128] border-[#C5A059]/40 text-white placeholder-stone-500'"
              />
            </div>
            <div>
              <label class="block text-xs font-bold mb-1" :class="isLight ? 'text-stone-800' : 'text-stone-200'">Family / Last Name *</label>
              <input
                type="text"
                v-model="form.lastName"
                required
                placeholder="e.g. Kkevo, Henderson"
                class="w-full px-3.5 py-2.5 text-base border-2 rounded-xl focus:ring-2 focus:ring-[#C5A059] focus:border-[#C5A059] transition-colors"
                :class="isLight ? 'bg-white border-stone-200 text-stone-900 placeholder-stone-400' : 'bg-[#1F2128] border-[#C5A059]/40 text-white placeholder-stone-500'"
              />
            </div>
          </div>

          <!-- Village / Hometown / Origin -->
          <div>
            <label class="block text-xs font-bold mb-1" :class="isLight ? 'text-stone-800' : 'text-stone-200'">
              🏡 Village / Hometown / City of Origin
            </label>
            <input
              type="text"
              v-model="form.birthPlace"
              placeholder="e.g. Bafoussam, Douala, Yaoundé, London"
              class="w-full px-3.5 py-2.5 text-sm border-2 rounded-xl focus:ring-2 focus:ring-[#C5A059] focus:border-[#C5A059] transition-colors"
              :class="isLight ? 'bg-white border-stone-200 text-stone-900 placeholder-stone-400' : 'bg-[#1F2128] border-[#C5A059]/40 text-white placeholder-stone-500'"
            />
          </div>

          <!-- Birthday & Status -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 items-center">
            <div>
              <label class="block text-xs font-bold mb-1" :class="isLight ? 'text-stone-800' : 'text-stone-200'">Date or Year of Birth</label>
              <input
                type="date"
                v-model="form.birthDate"
                class="w-full px-3.5 py-2.5 text-sm border-2 rounded-xl focus:ring-2 focus:ring-[#C5A059] focus:border-[#C5A059] transition-colors"
                :class="isLight ? 'bg-white border-stone-200 text-stone-900' : 'bg-[#1F2128] border-[#C5A059]/40 text-white'"
              />
            </div>
            <div>
              <label class="block text-xs font-bold mb-1" :class="isLight ? 'text-stone-800' : 'text-stone-200'">Status</label>
              <div
                class="flex items-center space-x-3 p-2 border-2 rounded-xl"
                :class="isLight ? 'bg-stone-50 border-stone-200' : 'bg-[#1F2128] border-[#C5A059]/40'"
              >
                <label class="inline-flex items-center text-xs font-bold cursor-pointer" :class="isLight ? 'text-stone-800' : 'text-stone-200'">
                  <input type="radio" :value="true" v-model="form.isLiving" class="text-[#C5A059] focus:ring-[#C5A059]" />
                  <span class="ml-1.5">🌱 Living</span>
                </label>
                <label class="inline-flex items-center text-xs font-bold cursor-pointer" :class="isLight ? 'text-stone-800' : 'text-stone-200'">
                  <input type="radio" :value="false" v-model="form.isLiving" class="text-[#C5A059] focus:ring-[#C5A059]" />
                  <span class="ml-1.5">🕊️ Ancestor</span>
                </label>
              </div>
            </div>
          </div>

          <!-- Error Alert -->
          <div v-if="errorMessage" class="p-3 bg-red-50 text-red-700 rounded-xl text-xs font-bold border border-red-200">
            ⚠️ {{ errorMessage }}
          </div>

          <!-- Big Friendly Action Buttons -->
          <div class="mt-5 pt-4 border-t flex justify-end space-x-3" :class="isLight ? 'border-stone-200' : 'border-[#C5A059]/30'">
            <button
              type="button"
              @click="$emit('close')"
              class="px-4 py-2.5 border-2 rounded-xl text-sm font-bold transition-colors cursor-pointer"
              :class="isLight ? 'border-stone-300 text-stone-700 hover:bg-stone-100' : 'border-[#C5A059]/40 text-stone-300 hover:bg-white/5'"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="saving"
              class="px-6 py-2.5 rounded-xl text-sm font-black text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-105 shadow-md shadow-amber-950/20 flex items-center gap-2 cursor-pointer transition-all"
              :class="{ 'opacity-50 cursor-not-allowed': saving }"
            >
              <span v-if="saving" class="animate-spin">⏳</span>
              <span v-else>✨</span>
              <span>{{ saving ? 'Saving to Database...' : 'Save & Connect' }}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useThemeStore } from '@/stores/theme'
import api from '@/api'

const themeStore = useThemeStore()
const isLight = computed(() => themeStore.isLight)

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false
  },
  targetPerson: {
    type: Object,
    default: null
  },
  initialRelation: {
    type: String,
    default: 'child' // 'child', 'spouse', 'father', 'mother'
  },
  treeId: {
    type: [Number, String],
    default: null
  }
})

const emit = defineEmits(['close', 'created'])

const relationships = [
  { id: 'father', label: 'Papa', sub: 'Father', icon: '👨' },
  { id: 'mother', label: 'Mama', sub: 'Mother', icon: '👩' },
  { id: 'spouse', label: 'Partner', sub: 'Husband / Wife', icon: '💍' },
  { id: 'child', label: 'Child', sub: 'Son / Daughter', icon: '👶' }
]

const selectedRelation = ref('child')
const saving = ref(false)
const errorMessage = ref('')

const form = ref({
  firstName: '',
  lastName: '',
  gender: 'M',
  isLiving: true,
  birthDate: '',
  birthPlace: '',
  deathDate: ''
})

const targetPersonName = computed(() => {
  if (!props.targetPerson) return 'Member'
  return `${props.targetPerson.firstName || props.targetPerson.first_name || ''} ${props.targetPerson.lastName || props.targetPerson.last_name || ''}`.trim()
})

const selectRelationship = (relId) => {
  selectedRelation.value = relId
  if (relId === 'father') {
    form.value.gender = 'M'
  } else if (relId === 'mother') {
    form.value.gender = 'F'
  } else if (relId === 'spouse') {
    // default opposite gender if known
    const targetGender = props.targetPerson?.gender
    form.value.gender = targetGender === 'M' ? 'F' : 'M'
  }
}

watch(() => props.isOpen, (newVal) => {
  if (newVal) {
    errorMessage.value = ''
    selectedRelation.value = props.initialRelation || 'child'
    const targetLastName = props.targetPerson?.lastName || props.targetPerson?.last_name || ''
    form.value = {
      firstName: '',
      lastName: selectedRelation.value === 'mother' ? '' : targetLastName,
      gender: selectedRelation.value === 'mother' ? 'F' : (selectedRelation.value === 'father' ? 'M' : (props.targetPerson?.gender === 'M' ? 'F' : 'M')),
      isLiving: true,
      birthDate: '',
      birthPlace: props.targetPerson?.birthPlace || props.targetPerson?.birth_place || '',
      deathDate: ''
    }
  }
})

const handleSubmit = async () => {
  if (!form.value.firstName || !form.value.lastName) {
    errorMessage.value = 'Please provide both first and last name.'
    return
  }

  saving.value = true
  errorMessage.value = ''

  try {
    const activeTreeId = props.treeId || props.targetPerson?.family_tree || props.targetPerson?.familyTree || props.targetPerson?.family_tree_id || 1

    // 1. Create the person
    const personPayload = {
      first_name: form.value.firstName,
      last_name: form.value.lastName,
      gender: form.value.gender,
      is_living: form.value.isLiving,
      birth_place: form.value.birthPlace,
      date_of_birth: form.value.birthDate || null,
      date_of_death: !form.value.isLiving && form.value.deathDate ? form.value.deathDate : null,
      family_tree: activeTreeId
    }

    const personRes = await api.post('/people/', personPayload)
    const newPerson = personRes.data

    // 2. Create the relationship
    // Golden rule:
    // PARENT relationship: person1 is PARENT / Elder, person2 is CHILD
    // SPOUSE relationship: person1 & person2 are partners
    let relPayload = null
    const targetId = props.targetPerson?.id

    if (selectedRelation.value === 'child') {
      // targetPerson is Parent (person1), newPerson is Child (person2)
      relPayload = {
        person1: targetId,
        person2: newPerson.id,
        relationship_type: 'PARENT'
      }
    } else if (selectedRelation.value === 'father' || selectedRelation.value === 'mother') {
      // newPerson is Parent (person1), targetPerson is Child (person2)
      relPayload = {
        person1: newPerson.id,
        person2: targetId,
        relationship_type: 'PARENT'
      }
    } else if (selectedRelation.value === 'spouse') {
      relPayload = {
        person1: targetId,
        person2: newPerson.id,
        relationship_type: 'SPOUSE'
      }
    }

    if (relPayload && targetId) {
      await api.post('/relationships/', relPayload)

      // If adding a child and targetPerson has a registered spouse, link child to spouse as well
      if (selectedRelation.value === 'child') {
        const spouseId = props.targetPerson?.spouse?.id || (props.targetPerson?.spouses && props.targetPerson.spouses[0]?.id)
        if (spouseId) {
          try {
            await api.post('/relationships/', {
              person1: spouseId,
              person2: newPerson.id,
              relationship_type: 'PARENT'
            })
          } catch (spouseRelErr) {
            console.warn('Could not auto-link child to partner:', spouseRelErr)
          }
        }
      }
    }

    emit('created', { newPerson, relationship: relPayload })
    emit('close')
  } catch (err) {
    console.error('Error creating relative:', err)
    errorMessage.value = err.response?.data?.detail || err.response?.data?.error || 'Failed to save relative. Please check your connection and try again.'
  } finally {
    saving.value = false
  }
}
</script>
