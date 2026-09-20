<template>
  <div class="min-h-screen pb-16 font-sans transition-colors duration-300" :class="isLight ? 'bg-[#FAF8F5] text-stone-900' : 'bg-[#0E0F12] text-stone-100'">
    <!-- Header Banner -->
    <div
      class="border-b shadow-lg transition-colors"
      :class="isLight ? 'bg-gradient-to-r from-white via-[#FAF6ED] to-white border-[#C5A059]/40 text-stone-900' : 'bg-[#121316] border-[#C5A059]/40 text-white'"
    >
      <div class="max-w-6xl mx-auto px-3 sm:px-6 lg:px-8 py-4 sm:py-8">
        <!-- Breadcrumbs Navigation Bar -->
        <nav aria-label="Breadcrumb" class="flex items-center gap-1.5 text-[11px] sm:text-xs font-black mb-3 sm:mb-6 flex-wrap">
          <router-link
            to="/tree"
            class="inline-flex items-center gap-1 transition-colors uppercase tracking-wider"
            :class="isLight ? 'text-stone-600 hover:text-stone-900' : 'text-stone-400 hover:text-stone-100'"
          >
            <span>🌳</span>
            <span>Tree</span>
          </router-link>
          <span class="opacity-40 font-bold" :class="isLight ? 'text-stone-400' : 'text-stone-600'">/</span>
          <router-link
            to="/people"
            class="inline-flex items-center gap-1 transition-colors uppercase tracking-wider"
            :class="isLight ? 'text-stone-600 hover:text-stone-900' : 'text-stone-400 hover:text-stone-100'"
          >
            <span>👥</span>
            <span>Members</span>
          </router-link>
          <span class="opacity-40 font-bold" :class="isLight ? 'text-stone-400' : 'text-stone-600'">/</span>
          <span
            class="font-black uppercase tracking-wider truncate max-w-[160px] sm:max-w-none"
            :class="isLight ? 'text-[#855B14]' : 'text-[#D4AF37]'"
          >
            {{ person.firstName }} {{ person.lastName }}
          </span>
        </nav>

        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 sm:gap-6">
          <div class="flex items-start sm:items-center gap-3 sm:gap-5">
            <!-- Large Avatar with Royal Gold Border -->
            <div class="relative shrink-0">
              <img
                v-if="person.photo && person.photo !== '/avatars/default-avatar.svg'"
                :src="person.photo"
                :alt="`${person.firstName} ${person.lastName}`"
                class="w-14 h-14 sm:w-24 sm:h-24 rounded-2xl sm:rounded-3xl object-cover border-2 sm:border-4 border-[#C5A059] shadow-xl"
              />
              <div
                v-else
                class="w-14 h-14 sm:w-24 sm:h-24 rounded-2xl sm:rounded-3xl flex items-center justify-center text-2xl sm:text-5xl shadow-xl border-2 sm:border-4 border-[#C5A059]"
                :class="isLight ? 'bg-amber-50 text-[#855B14]' : 'bg-[#1A1C22] text-[#F3E5AB]'"
              >
                {{ person.gender === 'Female' ? '👩' : '👨' }}
              </div>
            </div>

            <div class="min-w-0">
              <!-- Badges Row -->
              <div class="flex items-center gap-1.5 sm:gap-2 flex-wrap">
                <span
                  class="px-2 py-0.5 sm:px-3 sm:py-1 rounded-full text-[10px] sm:text-xs font-black"
                  :class="person.deathDate ? (isLight ? 'bg-stone-200 text-stone-800' : 'bg-stone-700 text-stone-200') : 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black'"
                >
                  {{ person.deathDate ? '🕊️ Ancestor' : '🌱 Living' }}
                </span>

                <span
                  v-if="person.traditionalName"
                  class="px-2 py-0.5 sm:px-3 sm:py-1 rounded-full text-[10px] sm:text-xs font-black border"
                  :class="isLight ? 'bg-amber-100/70 text-[#5B3D0B] border-[#C5A059]/50' : 'bg-[#252834] text-[#F3E5AB] border-[#C5A059]/50'"
                >
                  👑 {{ person.traditionalName }}
                </span>

                <span
                  v-if="person.clanTotem"
                  class="px-2 py-0.5 sm:px-3 sm:py-1 rounded-full text-[10px] sm:text-xs font-bold border"
                  :class="isLight ? 'bg-amber-50 text-[#674B19] border-[#C5A059]/40' : 'bg-[#1C1E25] text-[#F3E5AB] border-[#C5A059]/40'"
                >
                  Totem: {{ person.clanTotem }}
                </span>

                <span
                  v-if="person.village || person.birthPlace"
                  class="px-2 py-0.5 sm:px-3 sm:py-1 rounded-full text-[10px] sm:text-xs font-bold border"
                  :class="isLight ? 'bg-amber-50 text-[#674B19] border-[#C5A059]/40' : 'bg-[#1C1E25] text-[#F3E5AB] border-[#C5A059]/40'"
                >
                  📍 {{ person.village || person.birthPlace }}
                </span>
              </div>

              <h1
                class="text-xl sm:text-4xl font-black font-serif uppercase tracking-wide mt-1 sm:mt-1.5 truncate"
                :class="isLight ? 'text-stone-900' : 'text-transparent bg-clip-text bg-gradient-to-r from-[#F3E5AB] via-[#D4AF37] to-[#C5A059]'"
              >
                {{ person.firstName }} {{ person.lastName }}
              </h1>

              <p class="text-xs sm:text-sm font-medium mt-0.5 sm:mt-1" :class="isLight ? 'text-stone-600' : 'text-[#FDFBF7]/80'">
                <span v-if="person.birthDate">Born {{ person.birthDate }}</span>
                <span v-else>Birth date unknown</span>
                <span v-if="person.deathDate"> • Passed {{ person.deathDate }}</span>
                <span v-if="person.generationTier" class="ml-1 sm:ml-2 font-bold text-[#C5A059]">• Gen {{ person.generationTier }}</span>
              </p>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="flex flex-wrap items-center gap-1.5 sm:gap-2.5">
            <router-link
              :to="{ path: '/tree', query: { root: person.id } }"
              class="inline-flex items-center gap-1 sm:gap-2 px-3 py-1.5 sm:px-4 sm:py-2.5 rounded-xl sm:rounded-2xl bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-105 text-black font-black text-xs shadow-md transition-all active:scale-95"
            >
              <span>🌳</span>
              <span>View in Tree</span>
            </router-link>

            <button
              type="button"
              @click="openAddRelative('child')"
              class="inline-flex items-center gap-1 sm:gap-1.5 px-3 py-1.5 sm:px-4 sm:py-2.5 rounded-xl sm:rounded-2xl font-black text-xs border transition-all active:scale-95 cursor-pointer shadow-sm"
              :class="isLight ? 'bg-white hover:bg-stone-50 text-stone-900 border-[#C5A059]' : 'bg-[#1A1C22] hover:bg-[#252832] text-[#F3E5AB] border-[#C5A059]'"
            >
              <span>✨</span>
              <span>+ Relative</span>
            </button>

            <button
              type="button"
              @click="showShareModal = true"
              class="inline-flex items-center gap-1 sm:gap-1.5 px-3 py-1.5 sm:px-4 sm:py-2.5 rounded-xl sm:rounded-2xl font-black text-xs border transition-all active:scale-95 cursor-pointer shadow-sm bg-emerald-600 hover:bg-emerald-700 text-white border-emerald-500"
              title="Share branch via WhatsApp"
            >
              <span>📲</span>
              <span>Share</span>
            </button>

            <button
              type="button"
              @click="editPerson"
              class="p-2 sm:p-2.5 rounded-xl sm:rounded-2xl font-bold text-xs transition-all border cursor-pointer"
              :class="isLight ? 'bg-stone-100 hover:bg-stone-200 text-stone-700 border-stone-300' : 'bg-white/10 hover:bg-white/20 text-[#C5A059] border-[#C5A059]/40'"
              title="Edit details"
            >
              ✏️
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Main Content Container -->
    <div class="max-w-6xl mx-auto px-3 sm:px-6 lg:px-8 -mt-2 sm:-mt-4">
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 sm:gap-6">
        <!-- Family Connections & Oral Vault (2 cols) -->
        <div class="lg:col-span-2 space-y-4 sm:space-y-6">
          <!-- Family Connections Card -->
          <div
            class="rounded-2xl sm:rounded-3xl shadow-sm border p-3.5 sm:p-6 transition-colors"
            :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900 shadow-amber-950/5' : 'bg-[#16181F] border-[#C5A059]/40 text-stone-100 shadow-black/80'"
          >
            <div class="flex items-center justify-between mb-3 sm:mb-6">
              <div>
                <h2
                  class="text-base sm:text-xl font-black flex items-center gap-2 font-serif uppercase tracking-wide"
                  :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'"
                >
                  <span>👨‍👩‍👧‍👦</span>
                  <span>Family Connections</span>
                </h2>
                <p class="text-[11px] sm:text-xs font-semibold mt-0.5" :class="isLight ? 'text-stone-500' : 'text-stone-400'">Parents, partners, and children</p>
              </div>
            </div>

            <!-- Parents Grid -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5 sm:gap-4 mb-3 sm:mb-6">
              <!-- Papa / Father -->
              <div
                class="p-3 sm:p-4 rounded-xl sm:rounded-2xl border-2 flex flex-col justify-between"
                :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/30 text-stone-900' : 'bg-[#1F2128] border-[#C5A059]/30 text-stone-100'"
              >
                <div class="flex items-center justify-between mb-1.5 sm:mb-2">
                  <span class="text-[11px] sm:text-xs font-black uppercase tracking-wider" :class="isLight ? 'text-[#4A3510]' : 'text-[#F3E5AB]'">👨 Papa / Father</span>
                  <span v-if="person.father" class="text-[10px] sm:text-xs font-bold px-2 py-0.5 rounded-full border" :class="isLight ? 'text-[#674B19] bg-[#EFE2C2] border-[#C5A059]/40' : 'text-[#F3E5AB] bg-[#C5A059]/20 border-[#C5A059]/50'">Linked</span>
                </div>

                <div v-if="person.father" class="flex items-center justify-between">
                  <router-link
                    :to="`/people/${person.father.id}`"
                    class="text-sm sm:text-base font-black hover:underline"
                    :class="isLight ? 'text-stone-900 hover:text-[#996515]' : 'text-white hover:text-[#D4AF37]'"
                  >
                    {{ person.father.name }}
                  </router-link>
                  <router-link
                    :to="`/people/${person.father.id}`"
                    class="text-xs font-bold"
                    :class="isLight ? 'text-stone-500 hover:text-stone-800' : 'text-[#C5A059] hover:text-white'"
                  >
                    View →
                  </router-link>
                </div>
                <div v-else class="flex items-center justify-between">
                  <span class="text-xs sm:text-sm text-stone-400 italic">No father recorded</span>
                  <button
                    @click="openAddRelative('father')"
                    class="text-[11px] sm:text-xs font-black text-black bg-gradient-to-r from-[#B8860B] to-[#C5A059] hover:brightness-105 px-2.5 py-1 sm:px-3 sm:py-1.5 rounded-lg sm:rounded-xl transition-all cursor-pointer"
                  >
                    + Add Papa
                  </button>
                </div>
              </div>

              <!-- Mama / Mother -->
              <div
                class="p-3 sm:p-4 rounded-xl sm:rounded-2xl border-2 flex flex-col justify-between"
                :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/30 text-stone-900' : 'bg-[#1F2128] border-[#C5A059]/30 text-stone-100'"
              >
                <div class="flex items-center justify-between mb-1.5 sm:mb-2">
                  <span class="text-[11px] sm:text-xs font-black uppercase tracking-wider" :class="isLight ? 'text-[#4A3510]' : 'text-[#F3E5AB]'">👩 Mama / Mother</span>
                  <span v-if="person.mother" class="text-[10px] sm:text-xs font-bold px-2 py-0.5 rounded-full border" :class="isLight ? 'text-[#674B19] bg-[#EFE2C2] border-[#C5A059]/40' : 'text-[#F3E5AB] bg-[#C5A059]/20 border-[#C5A059]/50'">Linked</span>
                </div>

                <div v-if="person.mother" class="flex items-center justify-between">
                  <router-link
                    :to="`/people/${person.mother.id}`"
                    class="text-sm sm:text-base font-black hover:underline"
                    :class="isLight ? 'text-stone-900 hover:text-[#996515]' : 'text-white hover:text-[#D4AF37]'"
                  >
                    {{ person.mother.name }}
                  </router-link>
                  <router-link
                    :to="`/people/${person.mother.id}`"
                    class="text-xs font-bold"
                    :class="isLight ? 'text-stone-500 hover:text-stone-800' : 'text-[#C5A059] hover:text-white'"
                  >
                    View →
                  </router-link>
                </div>
                <div v-else class="flex items-center justify-between">
                  <span class="text-xs sm:text-sm text-stone-400 italic">No mother recorded</span>
                  <button
                    @click="openAddRelative('mother')"
                    class="text-[11px] sm:text-xs font-black text-black bg-gradient-to-r from-[#B8860B] to-[#C5A059] hover:brightness-105 px-2.5 py-1 sm:px-3 sm:py-1.5 rounded-lg sm:rounded-xl transition-all cursor-pointer"
                  >
                    + Add Mama
                  </button>
                </div>
              </div>
            </div>

            <!-- Partner / Spouse -->
            <div
              class="p-3 sm:p-4 rounded-xl sm:rounded-2xl border-2 mb-3 sm:mb-6"
              :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/30 text-stone-900' : 'bg-[#1F2128] border-[#C5A059]/30 text-stone-100'"
            >
              <div class="flex items-center justify-between mb-1.5 sm:mb-2">
                <span class="text-[11px] sm:text-xs font-black uppercase tracking-wider" :class="isLight ? 'text-[#4A3510]' : 'text-[#F3E5AB]'">💍 Partner / Spouse</span>
                <button
                  v-if="!person.spouse"
                  @click="openAddRelative('spouse')"
                  class="text-[11px] sm:text-xs font-black text-black bg-gradient-to-r from-[#B8860B] to-[#C5A059] hover:brightness-105 px-2.5 py-1 sm:px-3 sm:py-1.5 rounded-lg sm:rounded-xl transition-all cursor-pointer"
                >
                  + Add Partner
                </button>
              </div>

              <div v-if="person.spouse" class="flex items-center justify-between">
                <router-link
                  :to="`/people/${person.spouse.id}`"
                  class="text-sm sm:text-base font-black hover:underline"
                  :class="isLight ? 'text-stone-900 hover:text-[#996515]' : 'text-white hover:text-[#D4AF37]'"
                >
                  {{ person.spouse.name }}
                </router-link>
                <router-link
                  :to="`/people/${person.spouse.id}`"
                  class="text-xs font-bold"
                  :class="isLight ? 'text-stone-500 hover:text-stone-800' : 'text-[#C5A059] hover:text-white'"
                >
                  View →
                </router-link>
              </div>
              <p v-else class="text-xs sm:text-sm text-stone-400 italic">No partner recorded yet</p>
            </div>

            <!-- Siblings (Brothers & Sisters) -->
            <div
              class="p-3 sm:p-4 rounded-xl sm:rounded-2xl border-2 mb-3 sm:mb-6"
              :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/30 text-stone-900' : 'bg-[#1F2128] border-[#C5A059]/30 text-stone-100'"
            >
              <div class="flex items-center justify-between mb-2 sm:mb-3">
                <div>
                  <span class="text-[11px] sm:text-xs font-black uppercase tracking-wider" :class="isLight ? 'text-[#4A3510]' : 'text-[#F3E5AB]'">👥 Siblings</span>
                  <span class="ml-2 text-[10px] sm:text-xs font-black text-black bg-gradient-to-r from-[#B8860B] to-[#C5A059] px-2 py-0.5 rounded-full">
                    {{ person.siblings?.length || 0 }}
                  </span>
                </div>
              </div>

              <div v-if="person.siblings && person.siblings.length > 0" class="space-y-2">
                <div
                  v-for="sibling in person.siblings"
                  :key="sibling.id"
                  class="p-3 rounded-xl border flex items-center justify-between transition-colors"
                  :class="isLight ? 'bg-white border-[#C5A059]/30 hover:bg-[#FAF7F0] text-stone-900' : 'bg-[#16181F] border-[#C5A059]/30 hover:bg-[#20232E] text-stone-100'"
                >
                  <div class="flex items-center gap-3">
                    <span class="text-xl">{{ sibling.gender === 'Female' || sibling.gender === 'F' ? '👧' : '👦' }}</span>
                    <div>
                      <router-link
                        :to="`/people/${sibling.id}`"
                        class="text-sm font-black transition-colors"
                        :class="isLight ? 'text-stone-900 hover:text-[#996515]' : 'text-stone-100 hover:text-[#D4AF37]'"
                      >
                        {{ sibling.name }}
                      </router-link>
                      <span v-if="sibling.traditionalName" class="text-[11px] block font-semibold text-[#C5A059]">
                        👑 {{ sibling.traditionalName }}
                      </span>
                    </div>
                  </div>
                  <router-link
                    :to="`/people/${sibling.id}`"
                    class="text-xs font-bold"
                    :class="isLight ? 'text-stone-500 hover:text-stone-800' : 'text-[#C5A059] hover:text-white'"
                  >
                    View →
                  </router-link>
                </div>
              </div>
              <p v-else class="text-sm text-stone-400 italic">No brothers or sisters recorded</p>
            </div>

            <!-- Children List -->
            <div
              class="p-3 sm:p-4 rounded-xl sm:rounded-2xl border-2"
              :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/30 text-stone-900' : 'bg-[#1F2128] border-[#C5A059]/30 text-stone-100'"
            >
              <div class="flex items-center justify-between mb-2 sm:mb-3">
                <div>
                  <span class="text-[11px] sm:text-xs font-black uppercase tracking-wider" :class="isLight ? 'text-[#4A3510]' : 'text-[#F3E5AB]'">👶 Children</span>
                  <span class="ml-2 text-[10px] sm:text-xs font-black text-black bg-gradient-to-r from-[#B8860B] to-[#C5A059] px-2 py-0.5 rounded-full">
                    {{ person.children?.length || 0 }}
                  </span>
                </div>
                <button
                  @click="openAddRelative('child')"
                  class="text-[11px] sm:text-xs font-black text-black bg-gradient-to-r from-[#B8860B] to-[#C5A059] hover:brightness-105 px-2.5 py-1 sm:px-3 sm:py-1.5 rounded-lg sm:rounded-xl transition-all cursor-pointer"
                >
                  + Add Child
                </button>
              </div>

              <div v-if="person.children && person.children.length > 0" class="space-y-1.5 sm:space-y-2">
                <div
                  v-for="child in person.children"
                  :key="child.id"
                  class="p-2 sm:p-3 rounded-lg sm:rounded-xl border flex items-center justify-between transition-colors"
                  :class="isLight ? 'bg-white border-[#C5A059]/30 hover:bg-[#FAF7F0] text-stone-900' : 'bg-[#16181F] border-[#C5A059]/30 hover:bg-[#20232E] text-stone-100'"
                >
                  <div class="flex items-center gap-2 sm:gap-3">
                    <span class="text-base sm:text-xl">👶</span>
                    <router-link
                      :to="`/people/${child.id}`"
                      class="text-xs sm:text-sm font-black transition-colors"
                      :class="isLight ? 'text-stone-900 hover:text-[#996515]' : 'text-stone-100 hover:text-[#D4AF37]'"
                    >
                      {{ child.name }}
                    </router-link>
                  </div>
                  <router-link
                    :to="`/people/${child.id}`"
                    class="text-xs font-bold"
                    :class="isLight ? 'text-stone-500 hover:text-stone-800' : 'text-[#C5A059] hover:text-white'"
                  >
                    View →
                  </router-link>
                </div>
              </div>
              <p v-else class="text-xs sm:text-sm text-stone-400 italic">No children recorded yet</p>
            </div>
          </div>

          <!-- Oral History & Elder Audio Vault -->
          <div
            class="rounded-2xl sm:rounded-3xl shadow-sm border p-3.5 sm:p-6 transition-colors"
            :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900 shadow-amber-950/5' : 'bg-[#16181F] border-[#C5A059]/40 text-stone-100 shadow-black/80'"
          >
            <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2.5 sm:gap-4 mb-3 sm:mb-4">
              <div>
                <h2
                  class="text-base sm:text-xl font-black flex items-center gap-2 font-serif uppercase tracking-wide"
                  :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'"
                >
                  <span>🎙️</span>
                  <span>Oral History & Voice</span>
                </h2>
                <p class="text-[11px] sm:text-xs font-semibold mt-0.5" :class="isLight ? 'text-stone-500' : 'text-stone-400'">
                  Preserve elders' voices, oral lineage, songs, and historical recollections
                </p>
              </div>

              <button
                @click="showAudioModal = true"
                class="inline-flex items-center justify-center gap-1.5 px-3 py-1.5 sm:px-3.5 sm:py-2 rounded-lg sm:rounded-xl text-xs font-black text-black bg-gradient-to-r from-[#B8860B] to-[#C5A059] hover:brightness-105 shadow-md transition-all cursor-pointer"
              >
                <span>🎙️</span>
                <span>+ Record Voice</span>
              </button>
            </div>

            <!-- Audio List -->
            <div v-if="audioItems.length > 0" class="space-y-3">
              <div
                v-for="audio in audioItems"
                :key="audio.id"
                class="p-4 rounded-2xl border flex flex-col gap-3 transition-colors"
                :class="isLight ? 'bg-[#FDFBF7] border-[#C5A059]/30' : 'bg-[#1F2128] border-[#C5A059]/30'"
              >
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-3">
                    <span class="text-2xl">📻</span>
                    <div>
                      <h4 class="text-sm font-black" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">
                        {{ audio.title }}
                      </h4>
                      <p class="text-xs" :class="isLight ? 'text-stone-500' : 'text-stone-400'">
                        {{ audio.description || 'Oral memory preserved in family vault' }}
                      </p>
                    </div>
                  </div>
                  <span class="text-[10px] font-bold px-2 py-0.5 rounded-full border border-[#C5A059]/40 text-[#C5A059]">
                    Audio
                  </span>
                </div>

                <!-- Sleek Audio Player -->
                <audio
                  v-if="audio.file"
                  controls
                  class="w-full h-10 rounded-xl outline-none"
                  :src="audio.file"
                ></audio>
              </div>
            </div>

            <!-- Empty Audio State with Encouraging Banner -->
            <div
              v-else
              class="p-6 rounded-2xl border-2 border-dashed text-center flex flex-col items-center gap-3"
              :class="isLight ? 'border-[#C5A059]/40 bg-amber-50/40' : 'border-[#C5A059]/30 bg-[#1A1C23]'"
            >
              <div class="w-12 h-12 rounded-full flex items-center justify-center text-2xl" :class="isLight ? 'bg-amber-100' : 'bg-[#252834]'">
                🎙️
              </div>
              <div>
                <h4 class="text-sm font-black" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">
                  No Oral Voice Notes Yet
                </h4>
                <p class="text-xs max-w-md mx-auto mt-1" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
                  Capture the spoken words of {{ person.firstName }}. Click below to record a voice message or upload an audio interview.
                </p>
              </div>
              <button
                @click="showAudioModal = true"
                class="px-4 py-2 rounded-xl text-xs font-black text-black bg-gradient-to-r from-[#B8860B] to-[#C5A059] hover:brightness-105 transition-all cursor-pointer shadow-sm"
              >
                ● Record First Oral History Note
              </button>
            </div>
          </div>

          <!-- Stories / Biography / Notes -->
          <div
            class="rounded-3xl shadow-sm border p-6 transition-colors"
            :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900 shadow-amber-950/5' : 'bg-[#16181F] border-[#C5A059]/40 text-stone-100 shadow-black/80'"
          >
            <h2
              class="text-xl font-black flex items-center gap-2 mb-3 font-serif uppercase tracking-wide"
              :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'"
            >
              <span>📖</span>
              <span>Stories & Written Memory</span>
            </h2>
            <div v-if="person.notes" class="text-sm whitespace-pre-line leading-relaxed" :class="isLight ? 'text-stone-800' : 'text-stone-300'">
              {{ person.notes }}
            </div>
            <p v-else class="text-sm text-stone-400 italic">
              No family stories or notes recorded yet.
            </p>
          </div>
        </div>

        <!-- Sidebar Details -->
        <div class="space-y-6">
          <!-- African Cultural Lineage Card -->
          <div
            class="rounded-3xl shadow-sm border p-6 transition-colors"
            :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900 shadow-amber-950/5' : 'bg-[#16181F] border-[#C5A059]/40 text-stone-100 shadow-black/80'"
          >
            <h3
              class="text-lg font-black mb-4 flex items-center gap-2 font-serif uppercase tracking-wide"
              :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'"
            >
              <span>👑</span>
              <span>Cultural Roots</span>
            </h3>

            <dl class="space-y-3">
              <div class="flex justify-between items-center py-2 border-b" :class="isLight ? 'border-stone-100' : 'border-stone-800'">
                <dt class="text-xs font-bold uppercase" :class="isLight ? 'text-stone-500' : 'text-stone-400'">Titre Coutumier</dt>
                <dd class="text-sm font-black" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">{{ person.traditionalName || 'Not recorded' }}</dd>
              </div>

              <div class="flex justify-between items-center py-2 border-b" :class="isLight ? 'border-stone-100' : 'border-stone-800'">
                <dt class="text-xs font-bold uppercase" :class="isLight ? 'text-stone-500' : 'text-stone-400'">Village / Chefferie</dt>
                <dd class="text-sm font-black" :class="isLight ? 'text-[#674B19]' : 'text-[#D4AF37]'">{{ person.villageOfOrigin || person.village || person.birthPlace || 'Not listed' }}</dd>
              </div>

              <div class="flex justify-between items-center py-2 border-b" :class="isLight ? 'border-stone-100' : 'border-stone-800'">
                <dt class="text-xs font-bold uppercase" :class="isLight ? 'text-stone-500' : 'text-stone-400'">Totem du Clan</dt>
                <dd class="text-sm font-black" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">{{ person.clanTotem || 'Not listed' }}</dd>
              </div>

              <div class="flex justify-between items-center py-2 border-b" :class="isLight ? 'border-stone-100' : 'border-stone-800'">
                <dt class="text-xs font-bold uppercase" :class="isLight ? 'text-stone-500' : 'text-stone-400'">Generation</dt>
                <dd class="text-sm font-black text-[#C5A059]">Tier {{ person.generationTier || 1 }}</dd>
              </div>
            </dl>
          </div>

          <!-- Quick Facts -->
          <div
            class="rounded-3xl shadow-sm border p-6 transition-colors"
            :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900 shadow-amber-950/5' : 'bg-[#16181F] border-[#C5A059]/40 text-stone-100 shadow-black/80'"
          >
            <h3
              class="text-lg font-black mb-4 flex items-center gap-2 font-serif uppercase tracking-wide"
              :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'"
            >
              <span>📋</span>
              <span>Civil Facts</span>
            </h3>

            <dl class="space-y-3">
              <div class="flex justify-between items-center py-2 border-b" :class="isLight ? 'border-stone-100' : 'border-stone-800'">
                <dt class="text-xs font-bold uppercase" :class="isLight ? 'text-stone-500' : 'text-stone-400'">Gender</dt>
                <dd class="text-sm font-black" :class="isLight ? 'text-stone-900' : 'text-stone-100'">{{ person.gender }}</dd>
              </div>

              <div class="flex justify-between items-center py-2 border-b" :class="isLight ? 'border-stone-100' : 'border-stone-800'">
                <dt class="text-xs font-bold uppercase" :class="isLight ? 'text-stone-500' : 'text-stone-400'">Status</dt>
                <dd class="text-sm font-black" :class="person.deathDate ? (isLight ? 'text-stone-600' : 'text-stone-400') : 'text-[#8A6828]'">
                  {{ person.deathDate ? '🕊️ Ancestor' : '🌱 Living' }}
                </dd>
              </div>
            </dl>
          </div>

          <!-- Timeline -->
          <div
            v-if="timelineEvents.length > 0"
            class="rounded-3xl shadow-sm border p-6 transition-colors"
            :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900 shadow-amber-950/5' : 'bg-[#16181F] border-[#C5A059]/40 text-stone-100 shadow-black/80'"
          >
            <h3
              class="text-lg font-black mb-4 flex items-center gap-2 font-serif uppercase tracking-wide"
              :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'"
            >
              <span>⏳</span>
              <span>Milestones</span>
            </h3>

            <ul class="space-y-4">
              <li v-for="event in timelineEvents" :key="event.id" class="flex items-start gap-3">
                <span class="text-lg">📍</span>
                <div>
                  <h4 class="text-sm font-black" :class="isLight ? 'text-stone-800' : 'text-stone-200'">{{ event.title }} ({{ event.date }})</h4>
                  <p class="text-xs" :class="isLight ? 'text-stone-500' : 'text-stone-400'">{{ event.description }}</p>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>

    <!-- Oral History / Voice Recording Modal -->
    <div
      v-if="showAudioModal"
      class="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4"
    >
      <div
        class="rounded-3xl max-w-lg w-full p-6 border-2 border-[#C5A059] shadow-2xl space-y-5"
        :class="isLight ? 'bg-white text-stone-900' : 'bg-[#16181F] text-stone-100'"
      >
        <div class="flex justify-between items-center border-b pb-3" :class="isLight ? 'border-stone-200' : 'border-stone-800'">
          <div class="flex items-center gap-2.5">
            <span class="text-2xl">🎙️</span>
            <h3 class="text-lg font-black font-serif uppercase tracking-wide" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">
              Preserve Oral History Note
            </h3>
          </div>
          <button @click="closeAudioModal" class="text-xl font-black cursor-pointer opacity-70 hover:opacity-100">✕</button>
        </div>

        <div>
          <label class="block text-xs font-black uppercase tracking-wider mb-1" :class="isLight ? 'text-stone-700' : 'text-[#F3E5AB]'">
            Title / Topic *
          </label>
          <input
            type="text"
            v-model="audioForm.title"
            placeholder="e.g. Papa Jean recounting Bandjoun origins, Childhood memories..."
            class="w-full px-4 py-2.5 rounded-xl border text-sm font-semibold focus:outline-none focus:ring-2 focus:ring-[#C5A059]"
            :class="isLight ? 'bg-[#FDFBF7] border-stone-300' : 'bg-[#1F2128] border-stone-700 text-white'"
          />
        </div>

        <div>
          <label class="block text-xs font-black uppercase tracking-wider mb-1" :class="isLight ? 'text-stone-700' : 'text-[#F3E5AB]'">
            Notes & Context
          </label>
          <textarea
            v-model="audioForm.description"
            rows="2"
            placeholder="Details about where or when this story took place..."
            class="w-full px-4 py-2 rounded-xl border text-sm font-medium focus:outline-none focus:ring-2 focus:ring-[#C5A059]"
            :class="isLight ? 'bg-[#FDFBF7] border-stone-300' : 'bg-[#1F2128] border-stone-700 text-white'"
          ></textarea>
        </div>

        <!-- Microphone Recorder / File Upload Selector -->
        <div class="p-4 rounded-2xl border-2 border-dashed flex flex-col items-center gap-3 text-center" :class="isLight ? 'border-[#C5A059]/40 bg-amber-50/50' : 'border-[#C5A059]/40 bg-[#1A1C24]'">
          <div v-if="!recordedBlob && !audioFile">
            <div class="flex items-center justify-center gap-4">
              <button
                type="button"
                @click="toggleRecording"
                class="px-5 py-3 rounded-2xl font-black text-xs flex items-center gap-2 shadow-md transition-all cursor-pointer"
                :class="isRecording ? 'bg-red-600 text-white animate-pulse' : 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black'"
              >
                <span>{{ isRecording ? '⏹ Stop Recording' : '● Record via Mic' }}</span>
              </button>

              <span class="text-xs font-bold opacity-60">or</span>

              <label class="px-4 py-3 rounded-2xl font-black text-xs border border-[#C5A059] cursor-pointer hover:bg-[#C5A059]/20 transition-all flex items-center gap-1.5" :class="isLight ? 'text-[#855B14]' : 'text-[#F3E5AB]'">
                <span>📁 Upload Audio</span>
                <input type="file" accept="audio/*" class="sr-only" @change="onAudioFileSelected" />
              </label>
            </div>
            <p v-if="isRecording" class="text-xs text-red-500 font-bold mt-2">Recording in progress... Speak clearly into microphone.</p>
          </div>

          <div v-else class="w-full space-y-2">
            <div class="flex items-center justify-between text-xs font-bold text-emerald-500">
              <span>✓ Audio ready ({{ audioFile ? audioFile.name : 'Voice recording' }})</span>
              <button @click="clearAudioSelection" class="text-red-400 hover:underline cursor-pointer">Discard</button>
            </div>
            <audio v-if="audioPreviewUrl" controls :src="audioPreviewUrl" class="w-full h-10 rounded-xl outline-none"></audio>
          </div>
        </div>

        <div class="flex items-center justify-end gap-3 pt-2">
          <button
            type="button"
            @click="closeAudioModal"
            class="px-5 py-2.5 rounded-xl text-xs font-bold border cursor-pointer"
            :class="isLight ? 'border-stone-300 text-stone-700' : 'border-stone-700 text-stone-300'"
          >
            Cancel
          </button>
          <button
            type="button"
            @click="submitAudio"
            :disabled="uploadingAudio || (!recordedBlob && !audioFile) || !audioForm.title"
            class="px-6 py-2.5 rounded-xl font-black text-xs bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black disabled:opacity-50 cursor-pointer shadow-md"
          >
            {{ uploadingAudio ? 'Uploading...' : 'Save to Vault' }}
          </button>
        </div>
      </div>
    </div>

    <!-- WhatsApp Share Branch Modal -->
    <div
      v-if="showShareModal"
      class="fixed inset-0 bg-black/70 backdrop-blur-xs flex items-center justify-center z-50 p-4"
    >
      <div
        class="rounded-3xl max-w-md w-full p-6 border-2 border-emerald-500/50 shadow-2xl space-y-5"
        :class="isLight ? 'bg-white text-stone-900' : 'bg-[#16181F] text-stone-100'"
      >
        <div class="flex justify-between items-center border-b pb-3" :class="isLight ? 'border-stone-200' : 'border-stone-800'">
          <div class="flex items-center gap-2.5">
            <span class="text-2xl">📲</span>
            <h3 class="text-lg font-black font-serif uppercase tracking-wide text-emerald-500">
              Share Family Branch
            </h3>
          </div>
          <button @click="showShareModal = false" class="text-xl font-black cursor-pointer opacity-70 hover:opacity-100">✕</button>
        </div>

        <p class="text-xs font-medium leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
          Share the lineage of <strong class="text-[#C5A059]">{{ person.firstName }} {{ person.lastName }}</strong> directly with relatives around the world via WhatsApp.
        </p>

        <!-- Message Preview -->
        <div class="p-4 rounded-2xl border text-xs font-sans space-y-2" :class="isLight ? 'bg-[#FDFBF7] border-emerald-500/30 text-stone-800' : 'bg-[#121316] border-emerald-500/30 text-stone-200'">
          <div class="font-bold text-emerald-500 text-[11px] uppercase tracking-wider">WhatsApp Message Preview:</div>
          <p class="italic">"🌿 Greetings family! Discover our ancestral roots and tree branch for <strong>{{ person.traditionalName || person.firstName }} {{ person.lastName }}</strong> (Village: {{ person.villageOfOrigin || person.village || 'Bandjoun' }}) on Kkevo Family Tree: {{ shareUrl }}"</p>
        </div>

        <div class="flex flex-col gap-2.5 pt-2">
          <a
            :href="whatsAppShareUrl"
            target="_blank"
            rel="noopener noreferrer"
            class="w-full py-3 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white font-black text-xs text-center flex items-center justify-center gap-2 shadow-lg cursor-pointer"
          >
            <span>💬</span>
            <span>Open in WhatsApp</span>
          </a>

          <button
            type="button"
            @click="copyShareLink"
            class="w-full py-2.5 rounded-2xl font-black text-xs border border-[#C5A059] text-center cursor-pointer transition-all hover:bg-[#C5A059]/10"
            :class="isLight ? 'text-[#855B14]' : 'text-[#F3E5AB]'"
          >
            <span>📋 Copy Branch Link</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Quick Add Relative Modal -->
    <QuickAddRelativeModal
      :is-open="showAddModal"
      :target-person="person"
      :initial-relation="initialRelation"
      :tree-id="rawPersonData?.family_tree"
      @close="showAddModal = false"
      @created="onRelativeCreated"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useToast } from 'vue-toastification'
import { usePeopleStore } from '@/stores/people'
import { useMediaStore } from '@/stores/media'
import { useThemeStore } from '@/stores/theme'
import QuickAddRelativeModal from '@/components/QuickAddRelativeModal.vue'

const router = useRouter()
const route = useRoute()
const toast = useToast()
const peopleStore = usePeopleStore()
const mediaStore = useMediaStore()
const themeStore = useThemeStore()
const isLight = computed(() => themeStore.isLight)

// Quick add relative modal state
const showAddModal = ref(false)
const initialRelation = ref('child')
const rawPersonData = ref(null)

// Audio & Share state
const showAudioModal = ref(false)
const showShareModal = ref(false)
const audioItems = ref([])
const audioForm = ref({ title: '', description: '' })
const isRecording = ref(false)
const mediaRecorder = ref(null)
const recordedChunks = ref([])
const recordedBlob = ref(null)
const audioFile = ref(null)
const audioPreviewUrl = ref(null)
const uploadingAudio = ref(false)

const openAddRelative = (rel) => {
  initialRelation.value = rel
  showAddModal.value = true
}

const onRelativeCreated = async () => {
  toast.success('Family member connected!')
  await loadPersonData()
}

const person = ref({
  id: null,
  firstName: '',
  lastName: '',
  traditionalName: '',
  villageOfOrigin: '',
  village: '',
  clanTotem: '',
  generationTier: 1,
  gender: '',
  birthDate: '',
  birthPlace: '',
  deathDate: '',
  father: null,
  mother: null,
  spouse: null,
  children: [],
  notes: '',
  photo: null
})

const timelineEvents = ref([])

const shareUrl = computed(() => {
  return window.location.href
})

const whatsAppShareUrl = computed(() => {
  const text = `🌿 Greetings family! Discover our ancestral roots and tree branch for ${person.value.traditionalName || person.value.firstName} ${person.value.lastName} (Village: ${person.value.villageOfOrigin || person.value.village || 'Bandjoun'}) on Kkevo Family Tree: ${shareUrl.value}`
  return `https://api.whatsapp.com/send?text=${encodeURIComponent(text)}`
})

const copyShareLink = async () => {
  try {
    await navigator.clipboard.writeText(shareUrl.value)
    toast.success('Branch link copied to clipboard!')
  } catch (e) {
    toast.info(`Link: ${shareUrl.value}`)
  }
}

const loadPersonData = async () => {
  try {
    const personId = route.params.id
    const data = await peopleStore.fetchPersonDetails(personId)
    if (data) {
      rawPersonData.value = data
      const parents = data.parents || []
      const father = parents.find(p => p.gender === 'M') || parents[0] || null
      const mother = parents.find(p => p.gender === 'F') || (parents.length > 1 ? parents[1] : null)
      const spouse = (data.spouses && data.spouses[0]) || null

      person.value = {
        id: data.id,
        firstName: data.first_name || data.firstName || '',
        lastName: data.last_name || data.lastName || '',
        traditionalName: data.traditional_name || data.traditionalName || '',
        villageOfOrigin: data.village_of_origin || data.villageOfOrigin || '',
        village: data.village_of_origin || data.villageOfOrigin || data.birth_place || data.birthPlace || '',
        clanTotem: data.clan_totem || data.clanTotem || '',
        generationTier: data.generation_tier || data.generationTier || 1,
        gender: data.gender === 'M' ? 'Male' : (data.gender === 'F' ? 'Female' : 'Other'),
        birthDate: data.date_of_birth || data.birthDate || '',
        birthPlace: data.birth_place || data.birthPlace || '',
        deathDate: data.date_of_death || data.deathDate || '',
        father: father ? { id: father.id, name: father.full_name || `${father.first_name} ${father.last_name}`.trim() } : null,
        mother: mother ? { id: mother.id, name: mother.full_name || `${mother.first_name} ${mother.last_name}`.trim() } : null,
        spouse: spouse ? { id: spouse.id, name: spouse.full_name || `${spouse.first_name} ${spouse.last_name}`.trim() } : null,
        siblings: (data.siblings || []).map(s => ({
          id: s.id,
          name: s.full_name || s.name || `${s.first_name} ${s.last_name}`.trim(),
          gender: s.gender,
          traditionalName: s.traditional_name || s.traditionalName || ''
        })),
        children: (data.children || []).map(c => ({ id: c.id, name: c.full_name || `${c.first_name} ${c.last_name}`.trim() })),
        notes: data.biography || '',
        photo: data.avatar || data.profile_picture || null
      }

      timelineEvents.value = [
        ...(data.date_of_birth ? [{ id: 1, title: 'Birth', date: data.date_of_birth, description: `Born in ${data.birth_place || data.village_of_origin || 'ancestral lands'}` }] : []),
        ...(data.date_of_death ? [{ id: 2, title: 'Passing', date: data.date_of_death, description: '🕊️ Honored Ancestor' }] : [])
      ]

      // Load oral history audio
      loadPersonAudio(personId)
    }
  } catch (error) {
    toast.error('Failed to load person data')
    console.error('Error loading person:', error)
  }
}

const loadPersonAudio = async (personId) => {
  try {
    const items = await mediaStore.fetchPersonMedia(personId, 'AUDIO')
    audioItems.value = items || []
  } catch (e) {
    console.warn('Could not load audio:', e)
  }
}

// Media Recorder Handlers
const toggleRecording = async () => {
  if (isRecording.value) {
    if (mediaRecorder.value && mediaRecorder.value.state !== 'inactive') {
      mediaRecorder.value.stop()
    }
    isRecording.value = false
  } else {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      recordedChunks.value = []
      mediaRecorder.value = new MediaRecorder(stream)

      mediaRecorder.value.ondataavailable = (e) => {
        if (e.data.size > 0) recordedChunks.value.push(e.data)
      }

      mediaRecorder.value.onstop = () => {
        recordedBlob.value = new Blob(recordedChunks.value, { type: 'audio/webm' })
        audioPreviewUrl.value = URL.createObjectURL(recordedBlob.value)
        stream.getTracks().forEach(track => track.stop())
      }

      mediaRecorder.value.start()
      isRecording.value = true
    } catch (err) {
      toast.error('Microphone access denied or not supported in this environment.')
      console.error(err)
    }
  }
}

const onAudioFileSelected = (event) => {
  const file = event.target.files[0]
  if (file) {
    audioFile.value = file
    audioPreviewUrl.value = URL.createObjectURL(file)
  }
}

const clearAudioSelection = () => {
  recordedBlob.value = null
  audioFile.value = null
  if (audioPreviewUrl.value) {
    URL.revokeObjectURL(audioPreviewUrl.value)
    audioPreviewUrl.value = null
  }
}

const closeAudioModal = () => {
  if (isRecording.value) toggleRecording()
  clearAudioSelection()
  audioForm.value = { title: '', description: '' }
  showAudioModal.value = false
}

const submitAudio = async () => {
  if (!audioForm.value.title) {
    toast.warning('Please enter an audio title')
    return
  }
  const fileToUpload = audioFile.value || (recordedBlob.value ? new File([recordedBlob.value], `${audioForm.value.title}.webm`, { type: 'audio/webm' }) : null)
  if (!fileToUpload) {
    toast.warning('Please record or choose an audio file')
    return
  }

  uploadingAudio.value = true
  try {
    const payload = {
      title: audioForm.value.title,
      description: audioForm.value.description,
      media_type: 'AUDIO',
      file: fileToUpload,
      people: [person.value.id]
    }
    await mediaStore.uploadMedia(payload)
    toast.success('Oral history voice note preserved in vault!')
    closeAudioModal()
    await loadPersonAudio(person.value.id)
  } catch (err) {
    toast.error('Failed to upload audio recording')
    console.error(err)
  } finally {
    uploadingAudio.value = false
  }
}

onMounted(() => {
  loadPersonData()
})

const editPerson = () => {
  router.push(`/people/${route.params.id}/edit`)
}
</script>