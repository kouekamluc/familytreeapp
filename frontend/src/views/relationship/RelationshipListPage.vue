<template>
  <div class="min-h-screen pb-16 font-sans transition-colors duration-300" :class="isLight ? 'bg-[#FAF8F5] text-stone-900' : 'bg-[#0E0F12] text-stone-100'">
    <!-- Top Header Banner -->
    <div
      class="border-b shadow-lg transition-colors"
      :class="isLight ? 'bg-gradient-to-r from-white via-[#FAF6ED] to-white border-[#C5A059]/40 text-stone-900' : 'bg-[#121316] border-[#C5A059]/40 text-white'"
    >
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
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
          <span
            class="font-black uppercase tracking-wider"
            :class="isLight ? 'text-[#855B14]' : 'text-[#D4AF37]'"
          >
            🔗 Kinship & Relationships
          </span>
        </nav>

        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div class="flex items-center gap-4">
            <div
              class="w-14 h-14 rounded-2xl flex items-center justify-center text-3xl border-2 border-[#C5A059] shadow-xl"
              :class="isLight ? 'bg-amber-50 text-[#855B14]' : 'bg-[#1A1C22] text-[#F3E5AB]'"
            >
              🔗
            </div>
            <div>
              <h1
                class="text-2xl sm:text-3xl font-black font-serif uppercase tracking-wider"
                :class="isLight ? 'text-stone-900' : 'text-transparent bg-clip-text bg-gradient-to-r from-[#F3E5AB] via-[#D4AF37] to-[#C5A059]'"
              >
                Kinship & Bloodlines
              </h1>
              <p class="text-xs font-semibold mt-1" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
                Interactive relationship calculator and verified lineage links across the Kkevo dynasty
              </p>
            </div>
          </div>

          <div class="flex items-center gap-3">
            <router-link
              to="/tree"
              class="inline-flex items-center gap-2 px-4 py-2.5 rounded-2xl border text-xs font-black transition-all cursor-pointer shadow-sm"
              :class="isLight ? 'bg-white hover:bg-stone-50 border-[#C5A059]/40 text-stone-800' : 'bg-[#181A22] hover:bg-[#222530] border-[#C5A059]/40 text-[#F3E5AB]'"
            >
              <span>🌳</span>
              <span>Open Tree View</span>
            </router-link>
            <button
              @click="showAddModal = true"
              class="inline-flex items-center gap-2 px-5 py-2.5 rounded-2xl bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] text-black text-xs font-black shadow-lg shadow-black/20 hover:brightness-105 transition-all cursor-pointer"
            >
              <span>➕</span>
              <span>Connect Relative</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Content Container -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
      <!-- 1. Interactive Kinship Calculator & Relationship Explorer -->
      <div
        class="rounded-3xl border-2 p-6 shadow-xl transition-all"
        :class="isLight ? 'bg-white border-[#C5A059] shadow-amber-950/10' : 'bg-[#15171F] border-[#C5A059] shadow-black/80'"
      >
        <div class="flex flex-col lg:flex-row lg:items-center justify-between pb-5 border-b gap-4" :class="isLight ? 'border-[#C5A059]/20' : 'border-[#C5A059]/20'">
          <div>
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-black border mb-2"
              :class="isLight ? 'bg-amber-100 text-[#5B3D0B] border-[#C5A059]/40' : 'bg-[#252834] text-[#F3E5AB] border-[#C5A059]/40'">
              <span>✨</span>
              <span>Interactive Relationship Calculator</span>
            </div>
            <h2 class="text-xl font-black font-serif uppercase tracking-wide" :class="isLight ? 'text-stone-900' : 'text-stone-100'">
              Discover Kinship Between Two Relatives
            </h2>
            <p class="text-xs font-semibold mt-0.5" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
              Select any two family members to calculate their exact biological relationship, generational distance, and bloodline connection.
            </p>
          </div>

          <!-- Quick presets -->
          <div class="flex items-center gap-2 flex-wrap">
            <span class="text-[11px] font-bold uppercase tracking-wider opacity-70">Presets:</span>
            <button
              v-for="preset in calculationPresets"
              :key="preset.label"
              @click="applyPreset(preset)"
              class="px-2.5 py-1 rounded-xl text-xs font-bold border transition-all cursor-pointer"
              :class="isLight ? 'bg-amber-50 hover:bg-amber-100 border-[#C5A059]/40 text-stone-800' : 'bg-[#1F2128] hover:bg-[#282C36] border-[#C5A059]/40 text-[#F3E5AB]'"
            >
              {{ preset.label }}
            </button>
          </div>
        </div>

        <!-- Selector Row -->
        <div class="grid grid-cols-1 md:grid-cols-12 gap-4 items-center my-6">
          <!-- Person A -->
          <div class="md:col-span-5">
            <label class="block text-xs font-black uppercase tracking-wider mb-2" :class="isLight ? 'text-stone-700' : 'text-[#F3E5AB]'">
              Person 1 (Starting Relative)
            </label>
            <select
              v-model="calcPersonAId"
              class="w-full px-4 py-3 rounded-2xl text-xs font-bold border transition-colors focus:outline-none focus:ring-2 focus:ring-[#C5A059] cursor-pointer"
              :class="isLight ? 'bg-[#FAF8F5] border-[#C5A059]/50 text-stone-900' : 'bg-[#1C1E25] border-[#C5A059]/50 text-white'"
            >
              <option v-for="p in peopleList" :key="p.id" :value="p.id">
                {{ p.name }} {{ p.traditionalName ? `(👑 ${p.traditionalName})` : '' }} • Gen {{ p.generationTier || 1 }}
              </option>
            </select>
          </div>

          <!-- Swap Button -->
          <div class="md:col-span-2 flex justify-center">
            <button
              @click="swapCalcPersons"
              title="Swap Relatives"
              class="w-11 h-11 rounded-2xl border flex items-center justify-center text-lg font-black transition-transform hover:scale-110 active:scale-95 cursor-pointer shadow-md"
              :class="isLight ? 'bg-amber-50 border-[#C5A059] text-[#855B14]' : 'bg-[#1F2128] border-[#C5A059] text-[#F3E5AB]'"
            >
              ⇄
            </button>
          </div>

          <!-- Person B -->
          <div class="md:col-span-5">
            <label class="block text-xs font-black uppercase tracking-wider mb-2" :class="isLight ? 'text-stone-700' : 'text-[#F3E5AB]'">
              Person 2 (Relative to Connect)
            </label>
            <select
              v-model="calcPersonBId"
              class="w-full px-4 py-3 rounded-2xl text-xs font-bold border transition-colors focus:outline-none focus:ring-2 focus:ring-[#C5A059] cursor-pointer"
              :class="isLight ? 'bg-[#FAF8F5] border-[#C5A059]/50 text-stone-900' : 'bg-[#1C1E25] border-[#C5A059]/50 text-white'"
            >
              <option v-for="p in peopleList" :key="p.id" :value="p.id">
                {{ p.name }} {{ p.traditionalName ? `(👑 ${p.traditionalName})` : '' }} • Gen {{ p.generationTier || 1 }}
              </option>
            </select>
          </div>
        </div>

        <!-- Kinship Result Box -->
        <div
          v-if="kinshipResult"
          class="rounded-2xl border-2 p-5 transition-all animate-in fade-in"
          :class="isLight ? 'bg-[#FAF6ED] border-[#C5A059]/60 text-stone-900' : 'bg-[#1A1C24] border-[#C5A059]/60 text-stone-100'"
        >
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-[#C5A059]/30">
            <div>
              <div class="flex items-center gap-2 flex-wrap">
                <span class="px-3.5 py-1 rounded-full text-xs font-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] text-black shadow-sm">
                  👑 {{ kinshipResult.title }}
                </span>
                <span v-if="kinshipResult.culturalHonorific" class="px-3 py-1 rounded-full text-xs font-bold border"
                  :class="isLight ? 'bg-amber-100 text-[#5B3D0B] border-[#C5A059]/40' : 'bg-[#252834] text-[#F3E5AB] border-[#C5A059]/40'">
                  {{ kinshipResult.culturalHonorific }}
                </span>
              </div>
              <h3 class="text-lg sm:text-xl font-black font-serif mt-2" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">
                {{ kinshipResult.summary }}
              </h3>
              <p class="text-xs font-medium mt-1 leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-300'">
                {{ kinshipResult.description }}
              </p>
            </div>

            <router-link
              :to="{ path: '/tree', query: { root: calcPersonAId } }"
              class="self-start sm:self-center px-4 py-2 rounded-xl text-xs font-black text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-105 shadow transition-all flex items-center gap-1.5 whitespace-nowrap"
            >
              <span>🌳</span>
              <span>View Branch in Tree</span>
            </router-link>
          </div>

          <!-- Visual Step-by-Step Path Ribbon -->
          <div v-if="kinshipResult.path && kinshipResult.path.length > 1" class="pt-4">
            <div class="text-[10px] font-black uppercase tracking-wider mb-2 opacity-80" :class="isLight ? 'text-stone-600' : 'text-[#C5A059]'">
              Bloodline Connection Path:
            </div>
            <div class="flex items-center gap-2 overflow-x-auto pb-2">
              <template v-for="(person, idx) in kinshipResult.path" :key="person.id">
                <router-link
                  :to="`/people/${person.id}`"
                  class="px-3 py-1.5 rounded-xl border text-xs font-bold transition-transform hover:scale-105 flex items-center gap-2 shrink-0"
                  :class="idx === 0 || idx === kinshipResult.path.length - 1
                    ? (isLight ? 'bg-white border-[#C5A059] text-[#855B14] font-black shadow-xs' : 'bg-[#20232E] border-[#C5A059] text-[#F3E5AB] font-black shadow-xs')
                    : (isLight ? 'bg-stone-100 border-stone-300 text-stone-700' : 'bg-[#16181F] border-stone-700 text-stone-300')"
                >
                  <span>{{ person.gender === 'F' || person.gender === 'Female' ? '👩' : '👨' }}</span>
                  <span>{{ person.first_name || person.firstName }} {{ person.last_name || person.lastName }}</span>
                </router-link>
                <span v-if="idx < kinshipResult.path.length - 1" class="text-xs font-black text-[#C5A059]">➔</span>
              </template>
            </div>
          </div>
        </div>
      </div>

      <!-- 2. Verified Kinship Ties Table & Filters -->
      <div>
        <!-- Search and Filter Bar -->
        <div
          class="mb-6 p-4 rounded-3xl border shadow-md transition-colors flex flex-col md:flex-row items-stretch md:items-center justify-between gap-4"
          :class="isLight ? 'bg-white border-[#C5A059]/30 shadow-amber-950/5' : 'bg-[#16181F] border-[#C5A059]/30 shadow-black/60'"
        >
          <!-- Search Input -->
          <div class="relative flex-1 max-w-md">
            <input
              v-model="filters.search"
              type="text"
              placeholder="Search by relative name or notes..."
              class="w-full pl-10 pr-4 py-2.5 rounded-2xl text-xs font-bold transition-colors focus:outline-none focus:ring-2 focus:ring-[#C5A059]"
              :class="isLight ? 'bg-[#FAF8F5] border border-[#C5A059]/40 text-stone-900 placeholder-stone-400' : 'bg-[#1F2128] border border-[#C5A059]/40 text-white placeholder-stone-500'"
            />
            <span class="absolute left-3.5 top-1/2 -translate-y-1/2 text-sm" :class="isLight ? 'text-stone-400' : 'text-stone-500'">🔍</span>
          </div>

          <!-- Relationship Type Filter -->
          <div class="flex items-center gap-2 overflow-x-auto pb-1 md:pb-0">
            <button
              @click="filters.type = ''"
              class="px-3.5 py-1.5 rounded-xl text-xs font-black transition-all cursor-pointer whitespace-nowrap"
              :class="filters.type === ''
                ? (isLight ? 'bg-[#855B14] text-white shadow-sm' : 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black shadow-sm')
                : (isLight ? 'bg-stone-100 text-stone-700 hover:bg-stone-200' : 'bg-[#1F2128] text-stone-300 hover:bg-[#282C36]')"
            >
              All Types ({{ relationshipsList.length }})
            </button>
            <button
              @click="filters.type = 'PARENT'"
              class="px-3.5 py-1.5 rounded-xl text-xs font-black transition-all cursor-pointer whitespace-nowrap"
              :class="filters.type === 'PARENT'
                ? (isLight ? 'bg-[#855B14] text-white shadow-sm' : 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black shadow-sm')
                : (isLight ? 'bg-stone-100 text-stone-700 hover:bg-stone-200' : 'bg-[#1F2128] text-stone-300 hover:bg-[#282C36]')"
            >
              👑 Parent - Child
            </button>
            <button
              @click="filters.type = 'SPOUSE'"
              class="px-3.5 py-1.5 rounded-xl text-xs font-black transition-all cursor-pointer whitespace-nowrap"
              :class="filters.type === 'SPOUSE'
                ? (isLight ? 'bg-[#855B14] text-white shadow-sm' : 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black shadow-sm')
                : (isLight ? 'bg-stone-100 text-stone-700 hover:bg-stone-200' : 'bg-[#1F2128] text-stone-300 hover:bg-[#282C36]')"
            >
              💍 Spouses / Partners
            </button>
          </div>
        </div>

        <!-- Loading State -->
        <div v-if="loading" class="text-center py-20">
          <div class="inline-block animate-spin w-10 h-10 border-4 border-[#C5A059] border-t-transparent rounded-full mb-3"></div>
          <p class="text-base font-black" :class="isLight ? 'text-stone-800' : 'text-stone-200'">Loading kinship ties...</p>
        </div>

        <!-- Relationships Table / Cards -->
        <div
          v-else-if="filteredRelationships.length > 0"
          class="rounded-3xl border-2 shadow-xl overflow-hidden transition-colors"
          :class="isLight ? 'bg-white border-[#C5A059]/40 shadow-amber-950/10' : 'bg-[#15171E] border-[#C5A059]/40 shadow-black/80'"
        >
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y" :class="isLight ? 'divide-[#C5A059]/20' : 'divide-[#C5A059]/20'">
              <thead :class="isLight ? 'bg-stone-50' : 'bg-[#101115]'">
                <tr>
                  <th scope="col" class="px-6 py-3.5 text-left text-[11px] font-black uppercase tracking-wider" :class="isLight ? 'text-stone-600' : 'text-[#C5A059]'">
                    Elder / First Person
                  </th>
                  <th scope="col" class="px-6 py-3.5 text-center text-[11px] font-black uppercase tracking-wider" :class="isLight ? 'text-stone-600' : 'text-[#C5A059]'">
                    Kinship Connection
                  </th>
                  <th scope="col" class="px-6 py-3.5 text-left text-[11px] font-black uppercase tracking-wider" :class="isLight ? 'text-stone-600' : 'text-[#C5A059]'">
                    Relative / Descendant
                  </th>
                  <th scope="col" class="px-6 py-3.5 text-center text-[11px] font-black uppercase tracking-wider" :class="isLight ? 'text-stone-600' : 'text-[#C5A059]'">
                    Status
                  </th>
                  <th scope="col" class="px-6 py-3.5 text-right text-[11px] font-black uppercase tracking-wider" :class="isLight ? 'text-stone-600' : 'text-[#C5A059]'">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y" :class="isLight ? 'divide-stone-100' : 'divide-[#1E2028]'">
                <tr
                  v-for="rel in filteredRelationships"
                  :key="rel.id"
                  class="transition-colors group"
                  :class="isLight ? 'hover:bg-amber-50/40' : 'hover:bg-white/5'"
                >
                  <!-- Person 1 -->
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-xl flex items-center justify-center text-lg border overflow-hidden shadow-sm"
                        :class="isLight ? 'bg-amber-50 border-[#C5A059]/40' : 'bg-[#1C1E25] border-[#C5A059]/40 text-amber-200'"
                      >
                        <img v-if="rel.p1Avatar" :src="rel.p1Avatar" class="w-full h-full object-cover" />
                        <span v-else>{{ rel.p1Gender === 'F' ? '👩' : '👨' }}</span>
                      </div>
                      <div>
                        <router-link
                          :to="`/people/${rel.p1Id}`"
                          class="text-sm font-black hover:underline"
                          :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'"
                        >
                          {{ rel.p1Name }}
                        </router-link>
                        <span v-if="rel.p1Title" class="text-[10px] block font-semibold text-[#C5A059]">
                          👑 {{ rel.p1Title }}
                        </span>
                      </div>
                    </div>
                  </td>

                  <!-- Relationship Badge -->
                  <td class="px-6 py-4 whitespace-nowrap text-center">
                    <span
                      class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-black border shadow-xs"
                      :class="rel.relationship_type === 'PARENT'
                        ? (isLight ? 'bg-amber-100 text-[#5B3D0B] border-[#C5A059]/40' : 'bg-[#252834] text-[#F3E5AB] border-[#C5A059]/40')
                        : (isLight ? 'bg-rose-50 text-rose-900 border-rose-300' : 'bg-rose-950/40 text-rose-300 border-rose-800/50')"
                    >
                      <span>{{ rel.relationship_type === 'PARENT' ? '👑 Parent of' : '💍 Married to' }}</span>
                    </span>
                  </td>

                  <!-- Person 2 -->
                  <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-xl flex items-center justify-center text-lg border overflow-hidden shadow-sm"
                        :class="isLight ? 'bg-amber-50 border-[#C5A059]/40' : 'bg-[#1C1E25] border-[#C5A059]/40 text-amber-200'"
                      >
                        <img v-if="rel.p2Avatar" :src="rel.p2Avatar" class="w-full h-full object-cover" />
                        <span v-else>{{ rel.p2Gender === 'F' ? '👧' : '👦' }}</span>
                      </div>
                      <div>
                        <router-link
                          :to="`/people/${rel.p2Id}`"
                          class="text-sm font-black hover:underline"
                          :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'"
                        >
                          {{ rel.p2Name }}
                        </router-link>
                        <span v-if="rel.p2Title" class="text-[10px] block font-semibold text-[#C5A059]">
                          👑 {{ rel.p2Title }}
                        </span>
                      </div>
                    </div>
                  </td>

                  <!-- Status -->
                  <td class="px-6 py-4 whitespace-nowrap text-center">
                    <span
                      class="px-2.5 py-0.5 rounded-full text-[10px] font-black border uppercase tracking-wider"
                      :class="isLight ? 'bg-emerald-50 text-emerald-800 border-emerald-300' : 'bg-emerald-950/30 text-emerald-300 border-emerald-800/40'"
                    >
                      Verified
                    </span>
                  </td>

                  <!-- Actions -->
                  <td class="px-6 py-4 whitespace-nowrap text-right text-xs font-bold space-x-2">
                    <router-link
                      :to="{ path: '/tree', query: { root: rel.p1Id } }"
                      class="px-3 py-1.5 rounded-xl border text-xs font-black transition-all inline-flex items-center gap-1"
                      :class="isLight ? 'bg-stone-100 hover:bg-stone-200 text-stone-800 border-stone-300' : 'bg-[#1C1E25] hover:bg-[#252832] text-[#F3E5AB] border-[#C5A059]/30'"
                    >
                      <span>🌳</span>
                      <span>View Tree</span>
                    </router-link>
                    <button
                      @click="handleDelete(rel.id, rel.p1Name, rel.p2Name)"
                      class="px-2.5 py-1.5 rounded-xl border text-xs font-bold transition-all text-red-500 hover:bg-red-500/10 border-red-500/30 cursor-pointer"
                      title="Unlink relationship"
                    >
                      🗑️
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Empty State -->
        <div
          v-else
          class="rounded-3xl border-2 border-dashed p-12 text-center my-8 shadow-sm transition-colors"
          :class="isLight ? 'bg-white border-[#C5A059]/60 text-stone-900' : 'bg-[#16181F] border-[#C5A059]/60 text-stone-100'"
        >
          <div
            class="w-20 h-20 mx-auto rounded-3xl border-2 border-[#C5A059] flex items-center justify-center text-4xl mb-4 shadow-xl"
            :class="isLight ? 'bg-amber-50' : 'bg-[#121316]'"
          >
            🔗
          </div>
          <h3 class="text-2xl font-black mb-2" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">
            {{ filters.search ? 'No kinship ties found' : 'No Relationships Recorded Yet' }}
          </h3>
          <p class="text-base max-w-md mx-auto mb-6" :class="isLight ? 'text-stone-600' : 'text-stone-300'">
            {{ filters.search ? `We couldn't find any relationships matching "${filters.search}". Try clearing your filter.` : 'Connect parents, children, and partners to build the living lineage of the Kkevo family.' }}
          </p>
          <div class="flex items-center justify-center gap-3 flex-wrap">
            <button
              v-if="filters.search || filters.type"
              @click="filters.search = ''; filters.type = ''"
              class="inline-flex items-center gap-2 px-5 py-3 rounded-2xl border text-xs font-bold transition-all cursor-pointer"
              :class="isLight ? 'bg-stone-100 hover:bg-stone-200 text-stone-800 border-stone-300' : 'bg-[#1F2128] hover:bg-[#282C36] text-[#F3E5AB] border-[#C5A059]/40'"
            >
              <span>✕</span>
              <span>Reset Filters</span>
            </button>
            <button
              @click="showAddModal = true"
              class="inline-flex items-center gap-2 px-6 py-3.5 rounded-2xl bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] text-black font-black text-xs shadow-lg shadow-black/20 transition-all cursor-pointer"
            >
              <span>✨</span>
              <span>+ Connect First Relative</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Add Relative Modal -->
    <QuickAddRelativeModal
      :is-open="showAddModal"
      :target-person="null"
      initial-relation="child"
      @close="showAddModal = false"
      @created="loadData"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRelationshipsStore } from '@/stores/relationships'
import { usePeopleStore } from '@/stores/people'
import { useThemeStore } from '@/stores/theme'
import { calculateKinship } from '@/utils/kinship'
import QuickAddRelativeModal from '@/components/QuickAddRelativeModal.vue'

const relationshipsStore = useRelationshipsStore()
const peopleStore = usePeopleStore()
const themeStore = useThemeStore()

const isLight = computed(() => themeStore.isLight)
const loading = ref(false)
const showAddModal = ref(false)

const filters = ref({
  search: '',
  type: ''
})

// Kinship Calculator State
const calcPersonAId = ref(null)
const calcPersonBId = ref(null)

const peopleList = computed(() => {
  const list = Array.isArray(peopleStore.people)
    ? peopleStore.people
    : (peopleStore.people?.results || [])
  return list.map(p => ({
    id: p.id,
    name: p.full_name || `${p.first_name || p.firstName || ''} ${p.last_name || p.lastName || ''}`.trim() || `Person #${p.id}`,
    firstName: p.first_name || p.firstName || '',
    lastName: p.last_name || p.lastName || '',
    gender: p.gender || 'M',
    traditionalName: p.traditional_name || p.traditionalName || '',
    generationTier: p.generation_tier || p.generationTier || 1,
    avatar: p.avatar || p.profile_picture || null
  }))
})

const rawRelationships = computed(() => {
  return Array.isArray(relationshipsStore.relationships)
    ? relationshipsStore.relationships
    : (relationshipsStore.relationships?.results || [])
})

// Compute kinship result reactively
const kinshipResult = computed(() => {
  if (!calcPersonAId.value || !calcPersonBId.value) return null
  return calculateKinship(
    calcPersonAId.value,
    calcPersonBId.value,
    peopleList.value,
    rawRelationships.value
  )
})

const calculationPresets = computed(() => {
  const list = peopleList.value
  const presets = []
  const liam = list.find(p => p.name.toLowerCase().includes('liam'))
  const jean = list.find(p => p.name.toLowerCase().includes('jean'))
  const lucas = list.find(p => p.name.toLowerCase().includes('lucas'))
  const arthur = list.find(p => p.name.toLowerCase().includes('arthur'))
  const chloe = list.find(p => p.name.toLowerCase().includes('chloe'))

  if (liam && jean) presets.push({ label: 'Liam & Grandfather Jean', a: liam.id, b: jean.id })
  if (liam && lucas) presets.push({ label: 'Liam & Cousin Lucas', a: liam.id, b: lucas.id })
  if (arthur && chloe) presets.push({ label: 'Arthur & Sister Chloe', a: arthur.id, b: chloe.id })
  return presets
})

const applyPreset = (preset) => {
  calcPersonAId.value = preset.a
  calcPersonBId.value = preset.b
}

const swapCalcPersons = () => {
  const temp = calcPersonAId.value
  calcPersonAId.value = calcPersonBId.value
  calcPersonBId.value = temp
}

const relationshipsList = computed(() => {
  const peopleMap = new Map(peopleList.value.map(p => [p.id, p]))

  return rawRelationships.value.map(r => {
    const p1Id = r.person1_id || r.person1 || r.source
    const p2Id = r.person2_id || r.person2 || r.target
    const p1 = r.person1_details || peopleMap.get(p1Id) || {}
    const p2 = r.person2_details || peopleMap.get(p2Id) || {}

    return {
      id: r.id,
      relationship_type: (r.relationship_type || r.type || 'PARENT').toUpperCase(),
      notes: r.notes || '',
      p1Id,
      p1Name: p1.name || `${p1.first_name || ''} ${p1.last_name || ''}`.trim() || `Person #${p1Id}`,
      p1Title: p1.traditional_name || p1.traditionalName || '',
      p1Avatar: p1.avatar || p1.profile_picture || null,
      p1Gender: p1.gender || 'M',
      p2Id,
      p2Name: p2.name || `${p2.first_name || ''} ${p2.last_name || ''}`.trim() || `Person #${p2Id}`,
      p2Title: p2.traditional_name || p2.traditionalName || '',
      p2Avatar: p2.avatar || p2.profile_picture || null,
      p2Gender: p2.gender || 'M'
    }
  })
})

const filteredRelationships = computed(() => {
  return relationshipsList.value.filter(rel => {
    const q = filters.value.search.toLowerCase()
    const matchesSearch = !q ||
      rel.p1Name.toLowerCase().includes(q) ||
      rel.p2Name.toLowerCase().includes(q) ||
      rel.notes.toLowerCase().includes(q)

    const matchesType = !filters.value.type || rel.relationship_type === filters.value.type

    return matchesSearch && matchesType
  })
})

const loadData = async () => {
  loading.value = true
  try {
    await Promise.all([
      peopleStore.fetchPeople(),
      relationshipsStore.fetchRelationships()
    ])
    // Auto-select initial calculator pair if not set
    if (!calcPersonAId.value && peopleList.value.length > 0) {
      const liam = peopleList.value.find(p => p.name.toLowerCase().includes('liam'))
      const jean = peopleList.value.find(p => p.name.toLowerCase().includes('jean'))
      if (liam && jean) {
        calcPersonAId.value = liam.id
        calcPersonBId.value = jean.id
      } else if (peopleList.value.length >= 2) {
        calcPersonAId.value = peopleList.value[0].id
        calcPersonBId.value = peopleList.value[1].id
      }
    }
  } catch (err) {
    console.error('Error loading relationships:', err)
  } finally {
    loading.value = false
  }
}

const handleDelete = async (id, p1Name, p2Name) => {
  if (confirm(`Unlink connection between ${p1Name} and ${p2Name}?`)) {
    try {
      await relationshipsStore.deleteRelationship(id)
      await loadData()
    } catch (err) {
      console.error('Failed to delete relationship:', err)
    }
  }
}

onMounted(() => {
  loadData()
})
</script>