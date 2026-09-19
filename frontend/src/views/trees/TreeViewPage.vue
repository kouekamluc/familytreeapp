<template>
  <div class="min-h-screen bg-gray-50 flex flex-col">
    <!-- Toolbar -->
    <div class="bg-white shadow-sm border-b border-gray-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex flex-col sm:flex-row justify-between items-center py-4 gap-4">
          <div class="flex items-center space-x-3">
            <router-link to="/trees" class="text-gray-400 hover:text-gray-600">
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </router-link>
            <div>
              <h1 class="text-xl font-bold text-gray-900 flex items-center gap-2">
                <span>{{ treeName }}</span>
                <span class="text-xs bg-indigo-100 text-indigo-800 px-2 py-0.5 rounded-full font-medium">
                  {{ people.length }} members
                </span>
              </h1>
              <p v-if="treeDescription" class="text-xs text-gray-500">{{ treeDescription }}</p>
            </div>
          </div>

          <div class="flex items-center flex-wrap gap-3">
            <!-- Search -->
            <div class="relative w-48 sm:w-64">
              <input
                type="text"
                v-model="searchQuery"
                @input="highlightMembers"
                placeholder="Search member..."
                class="block w-full pl-9 pr-3 py-1.5 border border-gray-300 rounded-md text-sm placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500"
              />
              <div class="absolute inset-y-0 left-0 pl-2.5 flex items-center pointer-events-none">
                <svg class="h-4 w-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              </div>
            </div>

            <!-- Zoom Controls -->
            <div class="flex items-center bg-gray-100 rounded-md p-1 space-x-1">
              <button
                @click="zoomOut"
                title="Zoom Out"
                class="p-1.5 rounded hover:bg-white text-gray-600 hover:text-gray-900 transition-colors"
              >
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4" />
                </svg>
              </button>
              <button
                @click="resetZoom"
                title="Reset View"
                class="px-2 py-0.5 text-xs font-medium text-gray-600 hover:bg-white rounded"
              >
                {{ zoomLevel }}%
              </button>
              <button
                @click="zoomIn"
                title="Zoom In"
                class="p-1.5 rounded hover:bg-white text-gray-600 hover:text-gray-900 transition-colors"
              >
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
                </svg>
              </button>
            </div>

            <!-- Add Person Button -->
            <button
              @click="showAddPersonModal = true"
              class="inline-flex items-center px-3 py-1.5 border border-transparent rounded-md text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 shadow-sm"
            >
              <svg class="-ml-0.5 mr-1.5 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
              Add Member
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Visualization Container -->
    <div class="flex-1 relative overflow-hidden">
      <div v-if="loading" class="absolute inset-0 flex items-center justify-center bg-white bg-opacity-75 z-10">
        <div class="text-center">
          <div class="inline-block animate-spin rounded-full h-8 w-8 border-4 border-indigo-600 border-t-transparent"></div>
          <p class="mt-2 text-sm text-gray-600">Loading family tree...</p>
        </div>
      </div>

      <div
        v-if="!loading && people.length === 0"
        class="absolute inset-0 flex flex-col items-center justify-center p-6 text-center"
      >
        <div class="w-16 h-16 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-600 mb-4">
          <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
          </svg>
        </div>
        <h3 class="text-lg font-medium text-gray-900">No members in this tree yet</h3>
        <p class="mt-1 text-sm text-gray-500 max-w-sm">
          Start building your family tree by adding the first family member.
        </p>
        <button
          @click="showAddPersonModal = true"
          class="mt-4 inline-flex items-center px-4 py-2 border border-transparent rounded-md text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
        >
          Add First Member
        </button>
      </div>

      <div ref="treeContainer" class="w-full h-full min-h-[500px]"></div>

      <!-- Quick Person Drawer -->
      <transition name="slide-fade">
        <div
          v-if="selectedPerson"
          class="absolute top-4 right-4 w-80 bg-white rounded-xl shadow-xl border border-gray-200 p-5 z-20"
        >
          <div class="flex justify-between items-start">
            <div class="flex items-center space-x-3">
              <div
                class="w-12 h-12 rounded-full flex items-center justify-center text-white font-bold text-lg"
                :class="selectedPerson.gender === 'F' ? 'bg-pink-500' : 'bg-indigo-600'"
              >
                {{ (selectedPerson.first_name || selectedPerson.firstName || 'U')[0] }}
              </div>
              <div>
                <h4 class="text-base font-bold text-gray-900">
                  {{ selectedPerson.first_name || selectedPerson.firstName }} {{ selectedPerson.last_name || selectedPerson.lastName }}
                </h4>
                <p class="text-xs text-gray-500">
                  {{ selectedPerson.date_of_birth || selectedPerson.birthDate ? formatDate(selectedPerson.date_of_birth || selectedPerson.birthDate) : 'Birth date unknown' }}
                </p>
              </div>
            </div>
            <button @click="selectedPerson = null" class="text-gray-400 hover:text-gray-600">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <div class="mt-4 space-y-2 text-xs text-gray-600 border-t border-gray-100 pt-3">
            <p v-if="selectedPerson.birth_place || selectedPerson.birthPlace">
              <span class="font-semibold text-gray-700">Born in:</span> {{ selectedPerson.birth_place || selectedPerson.birthPlace }}
            </p>
            <p v-if="selectedPerson.biography">
              <span class="font-semibold text-gray-700">Bio:</span> {{ selectedPerson.biography }}
            </p>
          </div>

          <!-- 1-Click Add Relatives -->
          <div class="mt-4 pt-3 border-t border-gray-100">
            <span class="text-[11px] font-bold uppercase tracking-wider text-gray-400 block mb-2">1-Click Add Relative:</span>
            <div class="grid grid-cols-3 gap-1.5">
              <button
                @click="openQuickAdd(selectedPerson, 'child')"
                class="py-1.5 px-1 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 text-xs font-semibold rounded border border-indigo-200 text-center transition-all"
              >
                👶 + Child
              </button>
              <button
                @click="openQuickAdd(selectedPerson, 'spouse')"
                class="py-1.5 px-1 bg-pink-50 hover:bg-pink-100 text-pink-700 text-xs font-semibold rounded border border-pink-200 text-center transition-all"
              >
                💍 + Spouse
              </button>
              <button
                @click="openQuickAdd(selectedPerson, 'father')"
                class="py-1.5 px-1 bg-blue-50 hover:bg-blue-100 text-blue-700 text-xs font-semibold rounded border border-blue-200 text-center transition-all"
              >
                👨 + Parent
              </button>
            </div>
          </div>

          <div class="mt-4 pt-3 border-t border-gray-100 flex gap-2">
            <router-link
              :to="`/people/${selectedPerson.id}`"
              class="flex-1 text-center py-1.5 px-3 bg-indigo-50 text-indigo-700 rounded-md text-xs font-semibold hover:bg-indigo-100"
            >
              Full Profile
            </router-link>
            <router-link
              :to="`/people/${selectedPerson.id}/edit`"
              class="py-1.5 px-3 bg-gray-50 text-gray-700 rounded-md text-xs font-semibold hover:bg-gray-100"
            >
              Edit
            </router-link>
          </div>
        </div>
      </transition>
    </div>

    <!-- Quick Add Relative Modal -->
    <QuickAddRelativeModal
      :is-open="showQuickAddModal"
      :target-person="quickAddTarget"
      :initial-relation="quickAddRole"
      :tree-id="route.params.id"
      @close="showQuickAddModal = false"
      @created="onQuickAddCreated"
    />

    <!-- Add Person Modal -->
    <div
      v-if="showAddPersonModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
    >
      <div class="bg-white rounded-xl max-w-md w-full p-6 shadow-2xl">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-bold text-gray-900">Add Family Member</h3>
          <button @click="showAddPersonModal = false" class="text-gray-400 hover:text-gray-600">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <form @submit.prevent="submitAddPerson" class="space-y-4">
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">First Name *</label>
              <input
                type="text"
                v-model="newPersonForm.firstName"
                required
                class="w-full border border-gray-300 rounded-md px-3 py-1.5 text-sm focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Last Name *</label>
              <input
                type="text"
                v-model="newPersonForm.lastName"
                required
                class="w-full border border-gray-300 rounded-md px-3 py-1.5 text-sm focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500"
              />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Gender</label>
              <select
                v-model="newPersonForm.gender"
                class="w-full border border-gray-300 rounded-md px-3 py-1.5 text-sm focus:ring-1 focus:ring-indigo-500"
              >
                <option value="M">Male</option>
                <option value="F">Female</option>
                <option value="O">Other</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-700 mb-1">Birth Date</label>
              <input
                type="date"
                v-model="newPersonForm.birthDate"
                class="w-full border border-gray-300 rounded-md px-3 py-1.5 text-sm focus:ring-1 focus:ring-indigo-500"
              />
            </div>
          </div>

          <div>
            <label class="block text-xs font-medium text-gray-700 mb-1">Birth Place</label>
            <input
              type="text"
              v-model="newPersonForm.birthPlace"
              placeholder="City, Country"
              class="w-full border border-gray-300 rounded-md px-3 py-1.5 text-sm focus:ring-1 focus:ring-indigo-500"
            />
          </div>

          <div v-if="people.length > 0">
            <label class="block text-xs font-medium text-gray-700 mb-1">Related To Existing Member</label>
            <select
              v-model="newPersonForm.relatedPersonId"
              class="w-full border border-gray-300 rounded-md px-3 py-1.5 text-sm focus:ring-1 focus:ring-indigo-500 mb-2"
            >
              <option value="">None (Standalone)</option>
              <option v-for="p in people" :key="p.id" :value="p.id">
                {{ p.first_name || p.firstName }} {{ p.last_name || p.lastName }}
              </option>
            </select>
            <div v-if="newPersonForm.relatedPersonId" class="flex gap-2">
              <label class="inline-flex items-center text-xs">
                <input type="radio" v-model="newPersonForm.relationshipType" value="CHILD" class="text-indigo-600" />
                <span class="ml-1">Child of selected</span>
              </label>
              <label class="inline-flex items-center text-xs">
                <input type="radio" v-model="newPersonForm.relationshipType" value="PARENT" class="text-indigo-600" />
                <span class="ml-1">Parent of selected</span>
              </label>
              <label class="inline-flex items-center text-xs">
                <input type="radio" v-model="newPersonForm.relationshipType" value="SPOUSE" class="text-indigo-600" />
                <span class="ml-1">Spouse</span>
              </label>
            </div>
          </div>

          <div class="flex justify-end space-x-2 pt-3 border-t border-gray-100">
            <button
              type="button"
              @click="showAddPersonModal = false"
              class="px-3 py-1.5 rounded-md text-sm text-gray-700 hover:bg-gray-100"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="saving"
              class="px-4 py-1.5 rounded-md text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50"
            >
              {{ saving ? 'Adding...' : 'Add Member' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, reactive } from 'vue'
import { useRoute } from 'vue-router'
import { useToast } from 'vue-toastification'
import api from '@/services/api'
import * as d3 from 'd3'
import { format } from 'date-fns'
import QuickAddRelativeModal from '@/components/QuickAddRelativeModal.vue'

const route = useRoute()
const toast = useToast()

// Quick add relative modal state
const showQuickAddModal = ref(false)
const quickAddTarget = ref(null)
const quickAddRole = ref('child')

const openQuickAdd = (target, role) => {
  quickAddTarget.value = target
  quickAddRole.value = role
  showQuickAddModal.value = true
}

const onQuickAddCreated = async () => {
  toast.success('Relative added successfully!')
  await fetchTreeData()
}

const treeContainer = ref(null)
const treeName = ref('Family Tree')
const treeDescription = ref('')
const zoomLevel = ref(100)
const searchQuery = ref('')
const loading = ref(true)
const saving = ref(false)
const showAddPersonModal = ref(false)
const selectedPerson = ref(null)

const people = ref([])
const relationships = ref([])

let simulation = null
let svg = null
let gGroup = null
let zoomBehavior = null

const newPersonForm = reactive({
  firstName: '',
  lastName: '',
  gender: 'M',
  birthDate: '',
  birthPlace: '',
  relatedPersonId: '',
  relationshipType: 'CHILD'
})

const formatDate = (d) => {
  if (!d) return ''
  try {
    return format(new Date(d), 'MMMM d, yyyy')
  } catch (e) {
    return d
  }
}

const loadTreeData = async () => {
  loading.value = true
  const treeId = route.params.id
  try {
    const [treeRes, peopleRes, relsRes] = await Promise.all([
      api.get(`/trees/${treeId}/`),
      api.get('/people/', { params: { tree_id: treeId } }),
      api.get('/relationships/', { params: { tree_id: treeId } })
    ])

    treeName.value = treeRes.data.name || 'Family Tree'
    treeDescription.value = treeRes.data.description || ''

    const rawPeople = Array.isArray(peopleRes.data) ? peopleRes.data : (peopleRes.data.results || [])
    people.value = rawPeople

    const rawRels = Array.isArray(relsRes.data) ? relsRes.data : (relsRes.data.results || [])
    relationships.value = rawRels.map(r => ({
      ...r,
      source: r.source !== undefined ? r.source : r.person1,
      target: r.target !== undefined ? r.target : r.person2
    }))

    renderTree()
  } catch (error) {
    console.error('Error loading tree data:', error)
    toast.error('Failed to load tree data')
  } finally {
    loading.value = false
  }
}

const renderTree = () => {
  if (!treeContainer.value) return

  d3.select(treeContainer.value).selectAll('*').remove()
  if (simulation) simulation.stop()

  if (people.value.length === 0) return

  const width = treeContainer.value.clientWidth || 800
  const height = treeContainer.value.clientHeight || 600

  svg = d3.select(treeContainer.value)
    .append('svg')
    .attr('width', '100%')
    .attr('height', '100%')
    .attr('viewBox', [0, 0, width, height])

  gGroup = svg.append('g')

  zoomBehavior = d3.zoom()
    .scaleExtent([0.2, 3])
    .on('zoom', (event) => {
      gGroup.attr('transform', event.transform)
      zoomLevel.value = Math.round(event.transform.k * 100)
    })

  svg.call(zoomBehavior)

  // Filter relationships to only those where both nodes exist
  const personIds = new Set(people.value.map(p => p.id))
  const validLinks = relationships.value
    .filter(r => personIds.has(r.source) && personIds.has(r.target))
    .map(r => ({ ...r }))

  const nodes = people.value.map(p => ({ ...p }))

  simulation = d3.forceSimulation(nodes)
    .force('link', d3.forceLink(validLinks).id(d => d.id).distance(120))
    .force('charge', d3.forceManyBody().strength(-350))
    .force('center', d3.forceCenter(width / 2, height / 2))
    .force('collision', d3.forceCollide().radius(40))

  const link = gGroup.append('g')
    .selectAll('line')
    .data(validLinks)
    .enter()
    .append('line')
    .attr('stroke', d => d.relationship_type === 'SPOUSE' ? '#ec4899' : '#6366f1')
    .attr('stroke-width', d => d.relationship_type === 'SPOUSE' ? 2.5 : 1.5)
    .attr('stroke-dasharray', d => d.relationship_type === 'SPOUSE' ? '4,3' : 'none')
    .attr('stroke-opacity', 0.8)

  const nodeGroup = gGroup.append('g')
    .selectAll('g')
    .data(nodes)
    .enter()
    .append('g')
    .attr('class', 'cursor-pointer')
    .call(d3.drag()
      .on('start', (event) => {
        if (!event.active) simulation.alphaTarget(0.3).restart()
        event.subject.fx = event.subject.x
        event.subject.fy = event.subject.y
      })
      .on('drag', (event) => {
        event.subject.fx = event.x
        event.subject.fy = event.y
      })
      .on('end', (event) => {
        if (!event.active) simulation.alphaTarget(0)
        event.subject.fx = null
        event.subject.fy = null
      }))
    .on('click', (event, d) => {
      selectedPerson.value = d
    })

  // Outer shadow ring
  nodeGroup.append('circle')
    .attr('r', 24)
    .attr('fill', '#ffffff')
    .attr('stroke', d => d.gender === 'F' ? '#ec4899' : '#4f46e5')
    .attr('stroke-width', 2.5)

  // Inner colored circle
  nodeGroup.append('circle')
    .attr('r', 19)
    .attr('fill', d => d.gender === 'F' ? '#fdf2f8' : '#eef2ff')

  // Initials
  nodeGroup.append('text')
    .text(d => `${(d.first_name || d.firstName || 'U')[0]}${(d.last_name || d.lastName || '')[0] || ''}`.toUpperCase())
    .attr('text-anchor', 'middle')
    .attr('dy', '0.35em')
    .attr('font-size', '11px')
    .attr('font-weight', 'bold')
    .attr('fill', d => d.gender === 'F' ? '#db2777' : '#4338ca')

  // Name labels
  nodeGroup.append('text')
    .text(d => `${d.first_name || d.firstName || ''} ${d.last_name || d.lastName || ''}`.trim())
    .attr('text-anchor', 'middle')
    .attr('dy', '38px')
    .attr('font-size', '12px')
    .attr('font-weight', '600')
    .attr('fill', '#1f2937')

  simulation.on('tick', () => {
    link
      .attr('x1', d => d.source.x)
      .attr('y1', d => d.source.y)
      .attr('x2', d => d.target.x)
      .attr('y2', d => d.target.y)

    nodeGroup.attr('transform', d => `translate(${d.x},${d.y})`)
  })
}

const zoomIn = () => {
  if (svg && zoomBehavior) {
    svg.transition().duration(300).call(zoomBehavior.scaleBy, 1.25)
  }
}

const zoomOut = () => {
  if (svg && zoomBehavior) {
    svg.transition().duration(300).call(zoomBehavior.scaleBy, 0.8)
  }
}

const resetZoom = () => {
  if (svg && zoomBehavior) {
    svg.transition().duration(500).call(zoomBehavior.transform, d3.zoomIdentity)
  }
}

const highlightMembers = () => {
  if (!gGroup) return
  const q = searchQuery.value.toLowerCase().trim()
  gGroup.selectAll('g.cursor-pointer circle:first-child')
    .attr('stroke', d => {
      const name = `${d.first_name || d.firstName || ''} ${d.last_name || d.lastName || ''}`.toLowerCase()
      if (q && name.includes(q)) return '#f59e0b'
      return d.gender === 'F' ? '#ec4899' : '#4f46e5'
    })
    .attr('stroke-width', d => {
      const name = `${d.first_name || d.firstName || ''} ${d.last_name || d.lastName || ''}`.toLowerCase()
      return q && name.includes(q) ? 4 : 2.5
    })
}

const submitAddPerson = async () => {
  saving.value = true
  try {
    const payload = {
      family_tree: route.params.id,
      first_name: newPersonForm.firstName,
      last_name: newPersonForm.lastName,
      gender: newPersonForm.gender,
      date_of_birth: newPersonForm.birthDate || null,
      birth_place: newPersonForm.birthPlace
    }

    const res = await api.post('/people/', payload)
    const newPerson = res.data

    if (newPersonForm.relatedPersonId) {
      const relPayload = {
        person1: newPersonForm.relationshipType === 'PARENT' ? newPerson.id : newPersonForm.relatedPersonId,
        person2: newPersonForm.relationshipType === 'PARENT' ? newPersonForm.relatedPersonId : newPerson.id,
        relationship_type: newPersonForm.relationshipType === 'SPOUSE' ? 'SPOUSE' : 'PARENT'
      }
      try {
        await api.post('/relationships/', relPayload)
      } catch (relErr) {
        console.warn('Could not add relation:', relErr)
      }
    }

    toast.success('Member added to tree!')
    showAddPersonModal.value = false
    newPersonForm.firstName = ''
    newPersonForm.lastName = ''
    newPersonForm.birthDate = ''
    newPersonForm.birthPlace = ''
    newPersonForm.relatedPersonId = ''

    await loadTreeData()
  } catch (error) {
    console.error('Error adding person to tree:', error)
    toast.error('Failed to add person')
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  loadTreeData()
})

onUnmounted(() => {
  if (simulation) simulation.stop()
})
</script>

<style scoped>
.slide-fade-enter-active {
  transition: all 0.2s ease-out;
}
.slide-fade-leave-active {
  transition: all 0.15s cubic-bezier(1, 0.5, 0.8, 1);
}
.slide-fade-enter-from,
.slide-fade-leave-to {
  transform: translateX(20px);
  opacity: 0;
}
</style>