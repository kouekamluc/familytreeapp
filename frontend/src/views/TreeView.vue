<template>
  <div class="min-h-screen flex flex-col font-sans transition-colors duration-300" :class="isLight ? 'bg-[#FAF7F0]' : 'bg-[#0E0F12]'">
    <!-- Header / Toolbar -->
    <header
      class="border-b shadow-md sticky top-0 z-20 transition-colors duration-300"
      :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900' : 'bg-[#141519] border-[#C5A059]/40 text-white'"
    >
      <!-- Desktop & Tablet Header (md and up) -->
      <div class="hidden md:block w-full px-4 sm:px-6 lg:px-8 py-2.5">
        <div class="flex justify-between items-center gap-3">
          <div class="flex items-center space-x-3">
            <div
              class="w-10 h-10 rounded-xl border border-[#C5A059] flex items-center justify-center p-1 shadow-md"
              :class="isLight ? 'bg-amber-50 shadow-amber-900/10' : 'bg-[#0C0D0F] shadow-black/40'"
            >
              <span class="text-xl">🌳</span>
            </div>
            <div>
              <h1 class="text-lg sm:text-xl font-black text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] leading-tight font-serif uppercase tracking-wide">
                Kkevo Family Roots
              </h1>
              <p
                class="text-xs font-semibold"
                :class="isLight ? 'text-[#855B14]' : 'text-[#C5A059]/80'"
              >
                {{ people.length }} family members connected • Tap any card to connect family
              </p>
            </div>
          </div>

          <!-- Bottom Nav Controls pushed to right side -->
          <div class="flex items-center flex-wrap gap-2 ml-auto justify-end">
            <!-- Root Person Selector -->
            <div
              class="flex items-center space-x-1.5 border rounded-xl px-2.5 py-1.5 shadow-inner"
              :class="isLight ? 'bg-amber-50/70 border-[#C5A059]' : 'bg-[#1C1E24] border-[#C5A059]/60'"
            >
              <span class="text-xs font-bold" :class="isLight ? 'text-[#855B14]' : 'text-[#C5A059]'">Root:</span>
              <select
                v-model="rootPersonId"
                @change="renderPedigreeTree"
                class="bg-transparent text-xs font-black focus:outline-none cursor-pointer max-w-[140px] truncate"
                :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'"
              >
                <option v-for="p in people" :key="p.id" :value="p.id" class="bg-white text-black dark:bg-[#1C1E24] dark:text-white">
                  {{ p.first_name || p.firstName }} {{ p.last_name || p.lastName }}
                </option>
              </select>
            </div>

            <!-- View Mode Switcher -->
            <div
              class="inline-flex rounded-xl border p-0.5 text-xs font-bold shadow-sm"
              :class="isLight ? 'bg-stone-100 border-[#C5A059]/50' : 'bg-[#121316] border-[#C5A059]/60'"
            >
              <button
                @click="setViewMode('clan')"
                class="px-2 py-1 rounded-lg transition-all cursor-pointer"
                :class="viewMode === 'clan' ? 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black font-black shadow' : isLight ? 'text-stone-600 hover:text-black' : 'text-[#C5A059] hover:text-white'"
                title="View full family clan tree"
              >
                🌳 Clan
              </button>
              <button
                @click="setViewMode('descendants')"
                class="px-2 py-1 rounded-lg transition-all cursor-pointer"
                :class="viewMode === 'descendants' ? 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black font-black shadow' : isLight ? 'text-stone-600 hover:text-black' : 'text-[#C5A059] hover:text-white'"
                title="View descendants"
              >
                🌱 Descendants
              </button>
              <button
                @click="setViewMode('pedigree')"
                class="px-2 py-1 rounded-lg transition-all cursor-pointer"
                :class="viewMode === 'pedigree' ? 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black font-black shadow' : isLight ? 'text-stone-600 hover:text-black' : 'text-[#C5A059] hover:text-white'"
                title="Trace ancestors"
              >
                📜 Ancestors
              </button>
            </div>

            <!-- Orientation Switcher -->
            <div
              class="inline-flex rounded-xl border p-0.5 text-xs font-bold shadow-sm"
              :class="isLight ? 'bg-stone-100 border-[#C5A059]/50' : 'bg-[#121316] border-[#C5A059]/60'"
            >
              <button
                @click="setLayoutOrientation('vertical')"
                class="px-2 py-1 rounded-lg transition-all cursor-pointer"
                :class="layoutOrientation === 'vertical' ? 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black font-black shadow' : isLight ? 'text-stone-600 hover:text-black' : 'text-[#C5A059] hover:text-white'"
                title="Top-to-Bottom Dynasty Tree"
              >
                ↕️ Top
              </button>
              <button
                @click="setLayoutOrientation('horizontal')"
                class="px-2 py-1 rounded-lg transition-all cursor-pointer"
                :class="layoutOrientation === 'horizontal' ? 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black font-black shadow' : isLight ? 'text-stone-600 hover:text-black' : 'text-[#C5A059] hover:text-white'"
                title="Left-to-Right Pedigree Chart"
              >
                ↔️ Side
              </button>
            </div>

            <!-- Generation Depth Filter -->
            <div
              class="flex items-center space-x-1 border rounded-xl px-2 py-1 shadow-inner"
              :class="isLight ? 'bg-amber-50/70 border-[#C5A059]' : 'bg-[#1C1E24] border-[#C5A059]/60'"
            >
              <span class="text-[11px] font-bold" :class="isLight ? 'text-[#855B14]' : 'text-[#C5A059]'">Gen:</span>
              <select
                v-model="generationFilter"
                @change="renderPedigreeTree"
                class="bg-transparent text-xs font-black focus:outline-none cursor-pointer"
                :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'"
              >
                <option value="all" class="bg-white text-black dark:bg-[#1C1E24] dark:text-white">All Clan</option>
                <option value="3" class="bg-white text-black dark:bg-[#1C1E24] dark:text-white">3 Gens</option>
                <option value="2" class="bg-white text-black dark:bg-[#1C1E24] dark:text-white">2 Gens</option>
              </select>
            </div>

            <!-- Branch Labels Clean / Off Toggle -->
            <button
              @click="toggleBranchLabels"
              class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-xl text-xs font-black border transition-all cursor-pointer shadow-sm"
              :class="isLight ? 'bg-white hover:bg-stone-50 text-stone-900 border-[#C5A059]' : 'bg-[#1A1C22] hover:bg-[#252832] text-[#F3E5AB] border-[#C5A059]'"
              title="Toggle branch labels"
            >
              <span>🏷️</span>
              <span>{{ branchLabelMode === 'clean' ? 'Labels On' : 'Labels Off' }}</span>
            </button>

            <!-- Export Poster -->
            <button
              @click="exportLineagePoster"
              class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-xl text-xs font-black border transition-all cursor-pointer shadow-sm"
              :class="isLight ? 'bg-white hover:bg-stone-50 text-stone-900 border-[#C5A059]' : 'bg-[#1A1C22] hover:bg-[#252832] text-[#F3E5AB] border-[#C5A059]'"
              title="Export lineage poster"
            >
              <span>📷</span>
              <span>Poster</span>
            </button>

            <!-- WhatsApp Share -->
            <button
              @click="showTreeShareModal = true"
              class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-xl text-xs font-black text-white bg-emerald-600 hover:bg-emerald-700 shadow-md transition-all cursor-pointer"
              title="Share tree branch via WhatsApp"
            >
              <span>📲</span>
              <span>Share</span>
            </button>

            <!-- Global Add Person Button -->
            <button
              @click="openGlobalAddPerson"
              class="inline-flex items-center px-3 py-1.5 rounded-xl text-xs font-black text-black bg-gradient-to-r from-[#F3E5AB] via-[#D4AF37] to-[#C5A059] hover:brightness-105 shadow-md transition-all cursor-pointer"
            >
              <span class="text-sm mr-1 leading-none">✨</span>
              <span>+ Relative</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Mobile Compact Header (< md screens) -->
      <div class="md:hidden px-2.5 py-1.5 space-y-1.5">
        <!-- Top row: Root Selector + Quick Add + Expand Controls -->
        <div class="flex items-center justify-between gap-1.5">
          <!-- Root Selector -->
          <div
            class="flex items-center space-x-1 border rounded-lg px-2 py-1 shadow-inner flex-1 min-w-0"
            :class="isLight ? 'bg-amber-50/70 border-[#C5A059]/60' : 'bg-[#1C1E24] border-[#C5A059]/50'"
          >
            <span class="text-[10px] font-bold shrink-0" :class="isLight ? 'text-[#855B14]' : 'text-[#C5A059]'">Root:</span>
            <select
              v-model="rootPersonId"
              @change="renderPedigreeTree"
              class="bg-transparent text-[11px] font-black focus:outline-none cursor-pointer w-full truncate"
              :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'"
            >
              <option v-for="p in people" :key="p.id" :value="p.id" class="bg-white text-black dark:bg-[#1C1E24] dark:text-white">
                {{ p.first_name || p.firstName }} {{ p.last_name || p.lastName }}
              </option>
            </select>
          </div>

          <!-- Add Relative Button -->
          <button
            @click="openGlobalAddPerson"
            class="inline-flex items-center px-2.5 py-1 rounded-lg text-[11px] font-black text-black bg-gradient-to-r from-[#F3E5AB] via-[#D4AF37] to-[#C5A059] shadow-sm shrink-0 active:scale-95"
          >
            <span>+ Relative</span>
          </button>

          <!-- Toggle Extra Controls Panel -->
          <button
            @click="showMobileControls = !showMobileControls"
            class="w-7 h-7 rounded-lg border flex items-center justify-center text-xs shrink-0 transition-all"
            :class="[
              showMobileControls
                ? 'bg-[#C5A059] text-black border-[#C5A059]'
                : isLight
                  ? 'bg-stone-50 border-[#C5A059]/50 text-stone-700'
                  : 'bg-[#1C1E24] border-[#C5A059]/40 text-[#F3E5AB]'
            ]"
            title="Tree Controls"
          >
            ⚙️
          </button>
        </div>

        <!-- Horizontal Scrollable Quick Chips (Always visible or toggled) -->
        <div class="flex items-center gap-1 overflow-x-auto pb-0.5 no-scrollbar text-[11px]">
          <!-- View Modes -->
          <button
            @click="setViewMode('clan')"
            class="px-2 py-0.5 rounded-md font-bold whitespace-nowrap shrink-0 transition-all"
            :class="viewMode === 'clan' ? 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black font-black' : isLight ? 'bg-stone-100 text-stone-700' : 'bg-[#1A1C22] text-[#C5A059] border border-[#C5A059]/30'"
          >
            🌳 Clan
          </button>
          <button
            @click="setViewMode('descendants')"
            class="px-2 py-0.5 rounded-md font-bold whitespace-nowrap shrink-0 transition-all"
            :class="viewMode === 'descendants' ? 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black font-black' : isLight ? 'bg-stone-100 text-stone-700' : 'bg-[#1A1C22] text-[#C5A059] border border-[#C5A059]/30'"
          >
            🌱 Desc
          </button>
          <button
            @click="setViewMode('pedigree')"
            class="px-2 py-0.5 rounded-md font-bold whitespace-nowrap shrink-0 transition-all"
            :class="viewMode === 'pedigree' ? 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black font-black' : isLight ? 'bg-stone-100 text-stone-700' : 'bg-[#1A1C22] text-[#C5A059] border border-[#C5A059]/30'"
          >
            📜 Anc
          </button>

          <!-- Orientation -->
          <button
            @click="setLayoutOrientation(layoutOrientation === 'vertical' ? 'horizontal' : 'vertical')"
            class="px-2 py-0.5 rounded-md font-bold whitespace-nowrap shrink-0 border"
            :class="isLight ? 'bg-white border-stone-200 text-stone-700' : 'bg-[#1A1C22] border-[#C5A059]/30 text-[#F3E5AB]'"
          >
            {{ layoutOrientation === 'vertical' ? '↕ Top' : '↔ Side' }}
          </button>

          <!-- Poster -->
          <button
            @click="exportLineagePoster"
            class="px-2 py-0.5 rounded-md font-bold whitespace-nowrap shrink-0 border"
            :class="isLight ? 'bg-white border-stone-200 text-stone-700' : 'bg-[#1A1C22] border-[#C5A059]/30 text-[#F3E5AB]'"
            title="Lineage Poster"
          >
            📷 Poster
          </button>

          <!-- Share -->
          <button
            @click="showTreeShareModal = true"
            class="px-2 py-0.5 rounded-md font-bold whitespace-nowrap shrink-0 bg-emerald-600 text-white"
          >
            📲 Share
          </button>
        </div>

        <!-- Collapsible Mobile Advanced Controls Panel -->
        <div
          v-if="showMobileControls"
          class="pt-1.5 border-t flex items-center justify-between gap-1 text-[10px]"
          :class="isLight ? 'border-[#C5A059]/20' : 'border-[#C5A059]/20'"
        >
          <!-- Gen Depth -->
          <div class="flex items-center gap-1">
            <span class="font-bold text-[#C5A059]">Gens:</span>
            <button
              v-for="g in ['all', '3', '2']"
              :key="g"
              @click="generationFilter = g; renderPedigreeTree()"
              class="px-1.5 py-0.5 rounded font-bold"
              :class="generationFilter === g ? 'bg-[#C5A059] text-black font-black' : isLight ? 'bg-stone-100 text-stone-600' : 'bg-[#1C1E25] text-stone-300'"
            >
              {{ g === 'all' ? 'All' : `${g}G` }}
            </button>
          </div>

          <!-- Labels -->
          <button
            @click="toggleBranchLabels"
            class="px-2 py-0.5 rounded font-bold border"
            :class="isLight ? 'bg-stone-50 border-stone-200 text-stone-700' : 'bg-[#1C1E25] border-[#C5A059]/30 text-[#F3E5AB]'"
          >
            🏷️ {{ branchLabelMode === 'clean' ? 'Labels: On' : 'Labels: Off' }}
          </button>
        </div>
      </div>
    </header>

    <!-- Main Tree Container -->
    <main class="flex-1 relative overflow-hidden transition-colors duration-300" :class="isLight ? 'bg-[#FAF7F0]' : 'bg-[#0B0C0E]'">
      <div v-if="loading" class="absolute inset-0 flex items-center justify-center bg-[#121316]/60 backdrop-blur-xs z-10">
        <div class="flex flex-col items-center bg-[#141519] border border-[#C5A059] p-5 rounded-2xl shadow-2xl">
          <div class="w-8 h-8 border-3 border-[#C5A059] border-t-transparent rounded-full animate-spin"></div>
          <span class="mt-2 text-xs font-black text-[#F3E5AB]">Tracing Kkevo Family Roots...</span>
        </div>
      </div>

      <div v-if="!loading && people.length === 0" class="flex flex-col items-center justify-center h-[calc(100vh-10rem)] p-6 text-center">
        <div class="w-20 h-20 rounded-3xl bg-[#141519] border-2 border-[#C5A059] flex items-center justify-center p-2 mb-3 shadow-xl">
          <img src="/logo.png" alt="Kkevo Crest" class="w-full h-full object-contain" />
        </div>
        <h3 class="text-xl font-black" :class="isLight ? 'text-[#121316]' : 'text-stone-100'">Kkevo Family Tree is Ready to Grow</h3>
        <p class="text-xs mt-1.5 max-w-sm font-medium" :class="isLight ? 'text-stone-600' : 'text-stone-400'">Add yourself, your parents, or your elders to begin charting your heritage.</p>
        <button @click="openGlobalAddPerson" class="mt-4 px-5 py-2.5 bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] text-black text-xs font-black rounded-xl shadow-lg shadow-[#C5A059]/30">
          ✨ Add First Family Member
        </button>
      </div>

      <!-- Floating Elder-Friendly Zoom Controls -->
      <div
        class="absolute bottom-16 sm:bottom-6 left-3 sm:left-6 z-20 flex flex-col gap-1.5 p-1.5 sm:p-2 rounded-xl sm:rounded-2xl shadow-2xl border transition-colors"
        :class="isLight ? 'bg-white/95 border-[#C5A059]/60 shadow-amber-950/10' : 'bg-[#141519]/95 border-[#C5A059]/60 shadow-black/80'"
      >
        <button
          @click="zoomIn"
          title="Zoom In (Larger)"
          class="w-8 h-8 sm:w-11 sm:h-11 flex items-center justify-center rounded-lg sm:rounded-xl text-lg sm:text-2xl font-black transition-colors border cursor-pointer"
          :class="isLight ? 'bg-amber-50 hover:bg-amber-100 text-[#634208] border-[#C5A059]/40' : 'bg-[#20232B] hover:bg-[#2A2E38] text-[#F3E5AB] border-[#C5A059]/30'"
        >
          +
        </button>
        <button
          @click="resetZoom"
          title="Reset View"
          class="w-8 h-8 sm:w-11 sm:h-11 flex items-center justify-center rounded-lg sm:rounded-xl text-sm sm:text-xl transition-colors border cursor-pointer"
          :class="isLight ? 'bg-amber-50 hover:bg-amber-100 text-[#634208] border-[#C5A059]/40' : 'bg-[#20232B] hover:bg-[#2A2E38] text-[#D4AF37] border-[#C5A059]/30'"
        >
          🏠
        </button>
        <button
          @click="zoomOut"
          title="Zoom Out (Smaller)"
          class="w-8 h-8 sm:w-11 sm:h-11 flex items-center justify-center rounded-lg sm:rounded-xl text-lg sm:text-2xl font-black transition-colors border cursor-pointer"
          :class="isLight ? 'bg-amber-50 hover:bg-amber-100 text-[#634208] border-[#C5A059]/40' : 'bg-[#20232B] hover:bg-[#2A2E38] text-[#F3E5AB] border-[#C5A059]/30'"
        >
          −
        </button>
      </div>

      <!-- D3 Interactive Tree Container -->
      <div ref="treeContainer" class="w-full h-[calc(100vh-6.5rem)] sm:h-[calc(100vh-8rem)] select-none"></div>
    </main>

    <!-- Node Action Bottom Sheet / Card (Kkevo Royal Adaptive Theme) -->
    <div
      v-if="selectedNode"
      class="fixed bottom-14 sm:bottom-6 left-0 right-0 sm:left-auto sm:right-6 z-40 rounded-t-3xl sm:rounded-3xl shadow-2xl border-t-2 sm:border-2 p-3 sm:p-5 max-w-full sm:max-w-md max-h-[72vh] sm:max-h-[80vh] overflow-y-auto animate-in fade-in slide-in-from-bottom duration-200"
      :class="isLight ? 'bg-white border-[#C5A059] text-stone-900 shadow-amber-950/20' : 'bg-[#14161C] border-[#C5A059] text-white shadow-black/90'"
    >
      <!-- Mobile Drag Indicator -->
      <div class="w-10 h-1 rounded-full mx-auto mb-2 bg-stone-300 dark:bg-stone-600 sm:hidden"></div>

      <div class="flex justify-between items-start pb-2.5 border-b" :class="isLight ? 'border-[#C5A059]/30' : 'border-[#C5A059]/30'">
        <div class="flex items-center space-x-2.5">
          <div
            class="w-10 h-10 sm:w-12 sm:h-12 rounded-xl sm:rounded-2xl flex items-center justify-center text-lg sm:text-xl font-black overflow-hidden border-2 border-[#C5A059] shadow-inner shrink-0"
            :class="isLight ? 'bg-amber-50 text-[#855B14]' : 'bg-[#0D0E11] text-[#D4AF37]'"
          >
            <img v-if="selectedNode.avatar || selectedNode.profile_picture" :src="selectedNode.avatar || selectedNode.profile_picture" class="w-full h-full object-cover" />
            <span v-else>{{ selectedNode.gender === 'F' ? '👩' : '👨' }}</span>
          </div>
          <div class="min-w-0">
            <h4 class="text-base sm:text-lg font-black leading-tight truncate" :class="isLight ? 'text-stone-900' : 'text-transparent bg-clip-text bg-gradient-to-r from-[#F3E5AB] to-[#D4AF37]'">
              {{ selectedNode.first_name || selectedNode.firstName }} {{ selectedNode.last_name || selectedNode.lastName }}
            </h4>
            <p class="text-[11px] sm:text-xs font-semibold mt-0.5 truncate" :class="isLight ? 'text-[#855B14]' : 'text-[#C5A059]'">
              {{ formatBirth(selectedNode) }}
            </p>
            <div v-if="selectedNode.traditional_name || selectedNode.clan_totem || selectedNode.village_of_origin" class="flex flex-wrap gap-1 mt-1">
              <span v-if="selectedNode.traditional_name" class="px-1.5 py-0.5 rounded text-[9px] sm:text-[10px] font-black border" :class="isLight ? 'bg-amber-100 text-[#5B3D0B] border-[#C5A059]/40' : 'bg-[#252834] text-[#F3E5AB] border-[#C5A059]/40'">
                👑 {{ selectedNode.traditional_name }}
              </span>
              <span v-if="selectedNode.clan_totem" class="px-1.5 py-0.5 rounded text-[9px] sm:text-[10px] font-bold border" :class="isLight ? 'bg-amber-50 text-[#674B19] border-[#C5A059]/40' : 'bg-[#1C1E25] text-[#F3E5AB] border-[#C5A059]/40'">
                {{ selectedNode.clan_totem }}
              </span>
              <span v-if="selectedNode.village_of_origin" class="px-1.5 py-0.5 rounded text-[9px] sm:text-[10px] font-bold border" :class="isLight ? 'bg-amber-50 text-[#674B19] border-[#C5A059]/40' : 'bg-[#1C1E25] text-[#F3E5AB] border-[#C5A059]/40'">
                📍 {{ selectedNode.village_of_origin }}
              </span>
            </div>
          </div>
        </div>
        <button
          @click="selectedNode = null"
          class="w-7 h-7 sm:w-8 sm:h-8 rounded-full flex items-center justify-center font-bold transition-colors cursor-pointer shrink-0 text-xs sm:text-sm"
          :class="isLight ? 'bg-stone-100 hover:bg-stone-200 text-stone-700' : 'bg-white/10 hover:bg-white/20 text-[#C5A059]'"
        >
          ✕
        </button>
      </div>

      <!-- Immediate Kinship Circle (Parents, Spouses, Siblings, Children) -->
      <div class="py-2 sm:py-3 border-b space-y-1.5 sm:space-y-2" :class="isLight ? 'border-[#C5A059]/20' : 'border-[#C5A059]/20'">
        <div class="text-[10px] sm:text-[11px] font-black uppercase tracking-wider flex items-center justify-between" :class="isLight ? 'text-[#855B14]' : 'text-[#C5A059]'">
          <span>Family Circle</span>
          <span class="text-[9px] sm:text-[10px] lowercase font-normal opacity-80">tap kin to inspect</span>
        </div>

        <div class="grid grid-cols-2 gap-1.5 sm:gap-2 text-xs">
          <!-- Parents -->
          <div class="p-1.5 sm:p-2 rounded-xl border" :class="isLight ? 'bg-amber-50/50 border-[#C5A059]/30' : 'bg-[#181A22] border-[#C5A059]/30'">
            <div class="text-[9px] sm:text-[10px] font-bold uppercase tracking-wider mb-0.5" :class="isLight ? 'text-stone-500' : 'text-stone-400'">
              👑 Parents ({{ selectedNodeFamily.parents.length }})
            </div>
            <div v-if="selectedNodeFamily.parents.length > 0" class="flex flex-wrap gap-1">
              <button
                v-for="p in selectedNodeFamily.parents"
                :key="p.id"
                @click="selectedNode = p"
                class="px-1.5 py-0.5 rounded-md font-bold text-[11px] sm:text-xs truncate max-w-full hover:scale-105 transition-transform cursor-pointer"
                :class="isLight ? 'bg-amber-100 text-[#634208]' : 'bg-[#252834] text-[#F3E5AB]'"
                :title="p.first_name + ' ' + p.last_name"
              >
                {{ p.first_name }}
              </button>
            </div>
            <div v-else class="text-[9px] sm:text-[10px] italic text-stone-400">None recorded</div>
          </div>

          <!-- Partners / Spouses -->
          <div class="p-1.5 sm:p-2 rounded-xl border" :class="isLight ? 'bg-amber-50/50 border-[#C5A059]/30' : 'bg-[#181A22] border-[#C5A059]/30'">
            <div class="text-[9px] sm:text-[10px] font-bold uppercase tracking-wider mb-0.5" :class="isLight ? 'text-stone-500' : 'text-stone-400'">
              💍 Partner ({{ selectedNodeFamily.spouses.length }})
            </div>
            <div v-if="selectedNodeFamily.spouses.length > 0" class="flex flex-wrap gap-1">
              <button
                v-for="sp in selectedNodeFamily.spouses"
                :key="sp.id"
                @click="selectedNode = sp"
                class="px-1.5 py-0.5 rounded-md font-bold text-[11px] sm:text-xs truncate max-w-full hover:scale-105 transition-transform cursor-pointer"
                :class="isLight ? 'bg-amber-100 text-[#634208]' : 'bg-[#252834] text-[#F3E5AB]'"
                :title="sp.first_name + ' ' + sp.last_name"
              >
                {{ sp.first_name }}
              </button>
            </div>
            <div v-else class="text-[9px] sm:text-[10px] italic text-stone-400">None recorded</div>
          </div>

          <!-- Siblings -->
          <div class="p-1.5 sm:p-2 rounded-xl border" :class="isLight ? 'bg-amber-50/50 border-[#C5A059]/30' : 'bg-[#181A22] border-[#C5A059]/30'">
            <div class="text-[9px] sm:text-[10px] font-bold uppercase tracking-wider mb-0.5" :class="isLight ? 'text-stone-500' : 'text-stone-400'">
              👥 Siblings ({{ selectedNodeFamily.siblings.length }})
            </div>
            <div v-if="selectedNodeFamily.siblings.length > 0" class="flex flex-wrap gap-1">
              <button
                v-for="s in selectedNodeFamily.siblings"
                :key="s.id"
                @click="selectedNode = s"
                class="px-1.5 py-0.5 rounded-md font-bold text-[11px] sm:text-xs truncate max-w-full hover:scale-105 transition-transform cursor-pointer"
                :class="isLight ? 'bg-amber-100 text-[#634208]' : 'bg-[#252834] text-[#F3E5AB]'"
                :title="s.first_name + ' ' + s.last_name"
              >
                {{ s.first_name }}
              </button>
            </div>
            <div v-else class="text-[9px] sm:text-[10px] italic text-stone-400">None recorded</div>
          </div>

          <!-- Children -->
          <div class="p-1.5 sm:p-2 rounded-xl border" :class="isLight ? 'bg-amber-50/50 border-[#C5A059]/30' : 'bg-[#181A22] border-[#C5A059]/30'">
            <div class="text-[9px] sm:text-[10px] font-bold uppercase tracking-wider mb-0.5" :class="isLight ? 'text-stone-500' : 'text-stone-400'">
              👶 Children ({{ selectedNodeFamily.children.length }})
            </div>
            <div v-if="selectedNodeFamily.children.length > 0" class="flex flex-wrap gap-1">
              <button
                v-for="c in selectedNodeFamily.children"
                :key="c.id"
                @click="selectedNode = c"
                class="px-1.5 py-0.5 rounded-md font-bold text-[11px] sm:text-xs truncate max-w-full hover:scale-105 transition-transform cursor-pointer"
                :class="isLight ? 'bg-amber-100 text-[#634208]' : 'bg-[#252834] text-[#F3E5AB]'"
                :title="c.first_name + ' ' + c.last_name"
              >
                {{ c.first_name }}
              </button>
            </div>
            <div v-else class="text-[9px] sm:text-[10px] italic text-stone-400">None recorded</div>
          </div>
        </div>
      </div>

      <!-- Compact 1-Click Relative Addition Tiles -->
      <div class="py-2 sm:py-3">
        <span
          class="text-[10px] sm:text-xs font-black uppercase tracking-wider block mb-1.5"
          :class="isLight ? 'text-[#855B14]' : 'text-[#C5A059]'"
        >
          Connect a relative:
        </span>
        <div class="grid grid-cols-4 gap-1.5 sm:gap-2">
          <button
            @click="openAddRelative(selectedNode, 'father')"
            class="min-h-[38px] sm:min-h-[48px] p-1.5 sm:p-2.5 text-[10px] sm:text-xs font-black rounded-xl border text-center transition-all flex flex-col items-center justify-center gap-0.5 shadow-sm cursor-pointer hover:scale-102 active:scale-95"
            :class="isLight ? 'bg-stone-50 hover:bg-amber-50/60 border-[#C5A059]/40 text-stone-900' : 'bg-[#1F222A] hover:bg-[#282C36] border-[#C5A059]/50 text-[#F3E5AB]'"
          >
            <span class="text-base sm:text-xl leading-none">👨</span>
            <span>+ Papa</span>
          </button>
          <button
            @click="openAddRelative(selectedNode, 'mother')"
            class="min-h-[38px] sm:min-h-[48px] p-1.5 sm:p-2.5 text-[10px] sm:text-xs font-black rounded-xl border text-center transition-all flex flex-col items-center justify-center gap-0.5 shadow-sm cursor-pointer hover:scale-102 active:scale-95"
            :class="isLight ? 'bg-stone-50 hover:bg-amber-50/60 border-[#C5A059]/40 text-stone-900' : 'bg-[#1F222A] hover:bg-[#282C36] border-[#C5A059]/50 text-[#F3E5AB]'"
          >
            <span class="text-base sm:text-xl leading-none">👩</span>
            <span>+ Mama</span>
          </button>
          <button
            @click="openAddRelative(selectedNode, 'spouse')"
            class="min-h-[38px] sm:min-h-[48px] p-1.5 sm:p-2.5 text-[10px] sm:text-xs font-black rounded-xl border text-center transition-all flex flex-col items-center justify-center gap-0.5 shadow-sm cursor-pointer hover:scale-102 active:scale-95"
            :class="isLight ? 'bg-stone-50 hover:bg-amber-50/60 border-[#C5A059]/40 text-stone-900' : 'bg-[#1F222A] hover:bg-[#282C36] border-[#C5A059]/50 text-[#F3E5AB]'"
          >
            <span class="text-base sm:text-xl leading-none">💍</span>
            <span>+ Spouse</span>
          </button>
          <button
            @click="openAddRelative(selectedNode, 'child')"
            class="min-h-[38px] sm:min-h-[48px] p-1.5 sm:p-2.5 text-[10px] sm:text-xs font-black rounded-xl border text-center transition-all flex flex-col items-center justify-center gap-0.5 shadow-sm cursor-pointer hover:scale-102 active:scale-95"
            :class="isLight ? 'bg-stone-50 hover:bg-amber-50/60 border-[#C5A059]/40 text-stone-900' : 'bg-[#1F222A] hover:bg-[#282C36] border-[#C5A059]/50 text-[#F3E5AB]'"
          >
            <span class="text-base sm:text-xl leading-none">👶</span>
            <span>+ Child</span>
          </button>
        </div>
      </div>

      <div class="pt-2 border-t flex items-center justify-between" :class="isLight ? 'border-[#C5A059]/30' : 'border-[#C5A059]/30'">
        <button
          @click="setRootPerson(selectedNode.id)"
          class="text-[11px] sm:text-xs font-bold flex items-center gap-1 transition-colors cursor-pointer"
          :class="isLight ? 'text-[#855B14] hover:text-black' : 'text-[#C5A059] hover:text-[#F3E5AB]'"
        >
          <span>🎯</span> Focus Root
        </button>
        <router-link
          :to="`/people/${selectedNode.id}`"
          class="text-[11px] sm:text-xs bg-gradient-to-r from-[#B8860B] to-[#C5A059] hover:brightness-105 text-black px-3 py-1 sm:px-3.5 sm:py-1.5 rounded-lg sm:rounded-xl font-black transition-all flex items-center gap-1.5"
        >
          <span>🎙️</span>
          <span>Story Vault →</span>
        </router-link>
      </div>
    </div>

    <!-- WhatsApp Share Tree Modal -->
    <div
      v-if="showTreeShareModal"
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
              Share Family Tree
            </h3>
          </div>
          <button @click="showTreeShareModal = false" class="text-xl font-black cursor-pointer opacity-70 hover:opacity-100">✕</button>
        </div>

        <p class="text-xs font-medium leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
          Invite relatives, diaspora family members, and siblings to view the <strong class="text-[#C5A059]">Kkevo Royal Lineage Tree</strong>.
        </p>

        <!-- Message Preview -->
        <div class="p-4 rounded-2xl border text-xs font-sans space-y-2" :class="isLight ? 'bg-[#FDFBF7] border-emerald-500/30 text-stone-800' : 'bg-[#121316] border-emerald-500/30 text-stone-200'">
          <div class="font-bold text-emerald-500 text-[11px] uppercase tracking-wider">WhatsApp Message Preview:</div>
          <p class="italic">"👑 Greetings family! Explore our interconnected ancestral roots and clan lineage on Kkevo Family Tree: {{ currentTreeShareUrl }}"</p>
        </div>

        <div class="flex flex-col gap-2.5 pt-2">
          <a
            :href="whatsAppTreeUrl"
            target="_blank"
            rel="noopener noreferrer"
            class="w-full py-3 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white font-black text-xs text-center flex items-center justify-center gap-2 shadow-lg cursor-pointer"
          >
            <span>💬</span>
            <span>Open in WhatsApp</span>
          </a>

          <button
            type="button"
            @click="copyTreeLink"
            class="w-full py-2.5 rounded-2xl font-black text-xs border border-[#C5A059] text-center cursor-pointer transition-all hover:bg-[#C5A059]/10"
            :class="isLight ? 'text-[#855B14]' : 'text-[#F3E5AB]'"
          >
            <span>📋 Copy Tree Link</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Quick Add Relative Modal -->
    <QuickAddRelativeModal
      :is-open="showAddModal"
      :target-person="modalTargetPerson"
      :initial-relation="modalInitialRelation"
      @close="showAddModal = false"
      @created="onRelativeCreated"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useToast } from 'vue-toastification'
import { usePeopleStore } from '@/stores/people'
import { useRelationshipsStore } from '@/stores/relationships'
import { useThemeStore } from '@/stores/theme'
import QuickAddRelativeModal from '@/components/QuickAddRelativeModal.vue'
import * as d3 from 'd3'

const route = useRoute()
const toast = useToast()
const peopleStore = usePeopleStore()
const relationshipsStore = useRelationshipsStore()
const themeStore = useThemeStore()

const isLight = computed(() => themeStore.isLight)

// State
const loading = ref(true)
const people = ref([])
const relationships = ref([])
const rootPersonId = ref(null)
const viewMode = ref('clan') // 'clan' | 'descendants' | 'pedigree'
const generationFilter = ref('all') // 'all' | '3' | '2'
const branchLabelMode = ref('clean') // 'clean' | 'off'
const layoutOrientation = ref('vertical') // 'vertical' | 'horizontal'
const showTreeShareModal = ref(false)
const showMobileControls = ref(false)
const treeContainer = ref(null)
const selectedNode = ref(null)

const toggleBranchLabels = () => {
  branchLabelMode.value = branchLabelMode.value === 'clean' ? 'off' : 'clean'
  renderPedigreeTree()
}

const setLayoutOrientation = (orient) => {
  layoutOrientation.value = orient
  renderPedigreeTree()
}

// Modal state
const showAddModal = ref(false)
const modalTargetPerson = ref(null)
const modalInitialRelation = ref('child')

// WhatsApp and tree link sharing
const currentTreeShareUrl = computed(() => {
  return window.location.href
})

const whatsAppTreeUrl = computed(() => {
  const text = `👑 Greetings family! Explore our interconnected ancestral roots and clan lineage on Kkevo Family Tree: ${currentTreeShareUrl.value}`
  return `https://api.whatsapp.com/send?text=${encodeURIComponent(text)}`
})

const copyTreeLink = async () => {
  try {
    await navigator.clipboard.writeText(currentTreeShareUrl.value)
    toast.success('Tree link copied to clipboard!')
  } catch (e) {
    toast.info(`Link: ${currentTreeShareUrl.value}`)
  }
}

// D3 variables
const svg = ref(null)
const g = ref(null)
const zoom = ref(null)
const zoomPercentage = ref(100)
const initialTransformRef = ref(null)

// Card dimensions matching reference image with elder readability
const CARD_WIDTH = 246
const CARD_HEIGHT = 88
const LEVEL_GAP_X = 140
const NODE_GAP_Y = 32

const formatBirth = (person) => {
  if (!person) return ''
  const bDate = person.birthDate || person.date_of_birth
  const bPlace = person.birthPlace || person.birth_place || person.village
  let s = 'Born: '
  if (bDate) {
    s += bDate.slice(0, 4)
  } else {
    s += '—'
  }
  if (bPlace) s += ` (${bPlace})`
  return s
}

const formatOther = (person) => {
  if (!person) return ''
  if (!person.is_living && (person.deathDate || person.date_of_death)) {
    return `🕊️ Passed ${(person.deathDate || person.date_of_death).slice(0, 4)}`
  }
  if (person.village) return `📍 ${person.village}`
  if (person.is_living !== false) return '🌱 Living'
  return '🕊️ Ancestor'
}

// Compute immediate family circle for the selected person
const selectedNodeFamily = computed(() => {
  if (!selectedNode.value) return { parents: [], spouses: [], children: [], siblings: [] }
  const id = selectedNode.value.id
  const peopleMap = new Map(people.value.map(p => [p.id, p]))

  const parentIds = []
  const childIds = []
  const spouseIds = []

  relationships.value.forEach(r => {
    const p1 = r.person1_id || r.person1 || r.source
    const p2 = r.person2_id || r.person2 || r.target
    const type = (r.relationship_type || r.type || '').toUpperCase()

    if (type === 'PARENT') {
      // p1 is parent, p2 is child
      if (p2 === id && !parentIds.includes(p1)) parentIds.push(p1)
      if (p1 === id && !childIds.includes(p2)) childIds.push(p2)
    } else if (type === 'SPOUSE') {
      if (p1 === id && !spouseIds.includes(p2)) spouseIds.push(p2)
      if (p2 === id && !spouseIds.includes(p1)) spouseIds.push(p1)
    }
  })

  // Siblings: children who share at least one parent (excluding self)
  const siblingIds = []
  if (parentIds.length > 0) {
    relationships.value.forEach(r => {
      const p1 = r.person1_id || r.person1 || r.source
      const p2 = r.person2_id || r.person2 || r.target
      const type = (r.relationship_type || r.type || '').toUpperCase()
      if (type === 'PARENT' && parentIds.includes(p1) && p2 !== id && !siblingIds.includes(p2)) {
        siblingIds.push(p2)
      }
    })
  }

  return {
    parents: parentIds.map(pid => peopleMap.get(pid)).filter(Boolean),
    spouses: spouseIds.map(sid => peopleMap.get(sid)).filter(Boolean),
    children: childIds.map(cid => peopleMap.get(cid)).filter(Boolean),
    siblings: siblingIds.map(sbid => peopleMap.get(sbid)).filter(Boolean)
  }
})

const loadData = async () => {
  loading.value = true
  try {
    const treeId = route.params.id || route.query.tree_id || null
    await Promise.all([
      peopleStore.fetchPeople(treeId),
      relationshipsStore.fetchRelationships(treeId)
    ])
    people.value = Array.isArray(peopleStore.people) ? peopleStore.people : (peopleStore.people?.results || [])
    relationships.value = Array.isArray(relationshipsStore.relationships) ? relationshipsStore.relationships : (relationshipsStore.relationships?.results || [])

    if (route.query.root) {
      const qId = parseInt(route.query.root)
      const found = people.value.find(p => p.id === qId)
      if (found) {
        rootPersonId.value = qId
        selectedNode.value = found
      }
    }
    if (people.value.length > 0 && !rootPersonId.value) {
      // Find top elder (no parents in tree, has children) so Jean/Amina are root elders
      const parentMap = new Map()
      const childrenMap = new Map()
      relationships.value.forEach(r => {
        const p1 = r.person1_id || r.person1 || r.source
        const p2 = r.person2_id || r.person2 || r.target
        const type = (r.relationship_type || r.type || '').toUpperCase()
        if (type === 'PARENT') {
          if (!parentMap.has(p2)) parentMap.set(p2, [])
          parentMap.get(p2).push(p1)
          if (!childrenMap.has(p1)) childrenMap.set(p1, [])
          childrenMap.get(p1).push(p2)
        }
      })
      const elders = people.value.filter(p => (parentMap.get(p.id) || []).length === 0 && (childrenMap.get(p.id) || []).length > 0)
      if (elders.length > 0) {
        rootPersonId.value = elders[0].id
      } else {
        rootPersonId.value = people.value[0].id
      }
    }
    await nextTick()
    renderPedigreeTree()
  } catch (err) {
    console.error('Error loading tree data:', err)
  } finally {
    loading.value = false
  }
}

const setViewMode = (mode) => {
  viewMode.value = mode
  renderPedigreeTree()
}

const setRootPerson = (id) => {
  rootPersonId.value = id
  renderPedigreeTree()
}

// -------------------------------------------------------------
// Kinship Role Resolver (Patriarch, Matriarch, Son, Daughter, Grandchild)
// -------------------------------------------------------------
const getKinshipRole = (person, parentMap, childrenMap) => {
  if (!person) return 'Family Member'
  const pid = person.id
  const parents = parentMap.get(pid) || []
  const children = childrenMap.get(pid) || []
  const isFather = person.gender === 'M'

  // Grandparent / Founding Elder (Generation 1)
  const hasGrandchildren = children.some(cid => (childrenMap.get(cid) || []).length > 0)
  if (hasGrandchildren) {
    return isFather ? '👑 1st Gen • Patriarch' : '👑 1st Gen • Matriarch'
  }

  // Parent in Generation 2
  if (children.length > 0 && parents.length > 0) {
    return isFather ? '👨 2nd Gen • Son & Father' : '👩 2nd Gen • Daughter & Mother'
  }

  // Spouse in Generation 2 (Eleanor or Robert)
  if (children.length > 0) {
    return isFather ? '👨 2nd Gen • Father' : '👩 2nd Gen • Mother'
  }

  // Grandchild in Generation 3
  const hasGrandparents = parents.some(prid => (parentMap.get(prid) || []).length > 0)
  if (hasGrandparents) {
    return isFather ? '🌱 3rd Gen • Grandson' : '🌱 3rd Gen • Granddaughter'
  }

  if (parents.length > 0) {
    return isFather ? '🌱 Son • Brother' : '🌱 Daughter • Sister'
  }

  return isFather ? '👨 Elder • Father' : '👩 Elder • Mother'
}

// -------------------------------------------------------------
// Helper: Get Monogram Initials for Royal Card Medallion
// -------------------------------------------------------------
const getInitials = (person) => {
  if (!person) return 'KF'
  const trad = person.traditional_name || person.traditionalName
  if (trad) {
    const parts = trad.trim().split(/\s+/)
    if (parts.length >= 2) return `${parts[0][0]}${parts[1][0]}`.toUpperCase()
    if (parts.length === 1 && parts[0].length >= 2) return parts[0].slice(0, 2).toUpperCase()
  }
  const f = (person.first_name || person.firstName || '').trim()
  const l = (person.last_name || person.lastName || '').trim()
  if (f && l) return `${f[0]}${l[0]}`.toUpperCase()
  if (f && f.length >= 2) return f.slice(0, 2).toUpperCase()
  return 'KF'
}

// -------------------------------------------------------------
// Helper: Smooth Filleted Orthogonal Path (Horizontal: Left-to-Right)
// -------------------------------------------------------------
const roundedOrthogonalPath = (x1, y1, x2, y2, r = 12) => {
  if (Math.abs(y1 - y2) < 2) {
    return `M ${x1} ${y1} H ${x2}`
  }
  const xMid = x1 + (x2 - x1) * 0.5
  const dirY = y2 > y1 ? 1 : -1
  const radius = Math.min(r, Math.abs(xMid - x1) * 0.8, Math.abs(y2 - y1) / 2)
  return `M ${x1} ${y1} ` +
         `H ${xMid - radius} ` +
         `Q ${xMid} ${y1}, ${xMid} ${y1 + dirY * radius} ` +
         `V ${y2 - dirY * radius} ` +
         `Q ${xMid} ${y2}, ${xMid + radius} ${y2} ` +
         `H ${x2}`
}

// -------------------------------------------------------------
// Helper: Smooth Filleted Orthogonal Path (Vertical: Top-to-Bottom)
// -------------------------------------------------------------
const verticalOrthogonalPath = (x1, y1, x2, y2, r = 12) => {
  if (Math.abs(x1 - x2) < 2) {
    return `M ${x1} ${y1} V ${y2}`
  }
  const yMid = y1 + (y2 - y1) * 0.5
  const dirX = x2 > x1 ? 1 : -1
  const radius = Math.min(r, Math.abs(x2 - x1) / 2, Math.abs(yMid - y1) * 0.8)
  return `M ${x1} ${y1} ` +
         `V ${yMid - radius} ` +
         `Q ${x1} ${yMid}, ${x1 + dirX * radius} ${yMid} ` +
         `H ${x2 - dirX * radius} ` +
         `Q ${x2} ${yMid}, ${x2} ${yMid + radius} ` +
         `V ${y2}`
}

// -------------------------------------------------------------
// Generational Lineage Graph Engine (Supports Vertical Dynasty & Horizontal Chart)
// -------------------------------------------------------------
const buildClanGraph = (rootId) => {
  const peopleList = people.value
  const relsList = relationships.value
  const peopleMap = new Map(peopleList.map(p => [p.id, p]))

  const parentMap = new Map() // childId -> [parentIds]
  const childrenMap = new Map() // parentId -> [childIds]
  const spouseMap = new Map() // personId -> [spouseIds]

  relsList.forEach(r => {
    const p1 = r.person1_id || r.person1 || r.source
    const p2 = r.person2_id || r.person2 || r.target
    const type = (r.relationship_type || r.type || '').toUpperCase()

    if (type === 'PARENT') {
      if (!parentMap.has(p2)) parentMap.set(p2, [])
      if (!parentMap.get(p2).includes(p1)) parentMap.get(p2).push(p1)

      if (!childrenMap.has(p1)) childrenMap.set(p1, [])
      if (!childrenMap.get(p1).includes(p2)) childrenMap.get(p1).push(p2)
    } else if (type === 'SPOUSE') {
      if (!spouseMap.has(p1)) spouseMap.set(p1, [])
      if (!spouseMap.get(p1).includes(p2)) spouseMap.get(p1).push(p2)

      if (!spouseMap.has(p2)) spouseMap.set(p2, [])
      if (!spouseMap.get(p2).includes(p1)) spouseMap.get(p2).push(p1)
    }
  })

  // Sibling lookup: children who share at least one parent
  const siblingsMap = new Map()
  peopleList.forEach(p => {
    const parents = parentMap.get(p.id) || []
    const sibSet = new Set()
    parents.forEach(pid => {
      (childrenMap.get(pid) || []).forEach(cid => {
        if (cid !== p.id) sibSet.add(cid)
      })
    })
    siblingsMap.set(p.id, Array.from(sibSet))
  })

  // Determine generational levels
  const levelMap = new Map()
  const activeMode = viewMode.value

  if (activeMode === 'clan') {
    // True Roots: elders with 0 parents who are NOT married to someone with parents
    const trueRoots = peopleList.filter(p => {
      const hasParents = (parentMap.get(p.id) || []).length > 0
      if (hasParents) return false
      const spouses = spouseMap.get(p.id) || []
      const spouseHasParents = spouses.some(sid => (parentMap.get(sid) || []).length > 0)
      return !spouseHasParents
    })

    const initialRoots = trueRoots.length > 0 ? trueRoots.map(p => p.id) : (peopleList[0] ? [peopleList[0].id] : [])

    initialRoots.forEach(id => {
      levelMap.set(id, 0)
      const spouses = spouseMap.get(id) || []
      spouses.forEach(sId => levelMap.set(sId, 0))
    })

    // Propagate level down
    let changed = true
    while (changed) {
      changed = false
      peopleList.forEach(p => {
        const parents = parentMap.get(p.id) || []
        if (parents.length > 0) {
          const parentLevels = parents.map(pid => levelMap.get(pid)).filter(l => l !== undefined)
          if (parentLevels.length > 0) {
            const myLevel = Math.max(...parentLevels) + 1
            if (levelMap.get(p.id) !== myLevel) {
              levelMap.set(p.id, myLevel)
              changed = true
            }
          }
        }
        const myLevel = levelMap.get(p.id)
        if (myLevel !== undefined) {
          const spouses = spouseMap.get(p.id) || []
          spouses.forEach(sId => {
            if (levelMap.get(sId) !== myLevel) {
              levelMap.set(sId, myLevel)
              changed = true
            }
          })
        }
      })
    }
  } else if (activeMode === 'pedigree') {
    // Ancestors mode: If current root has no parents, automatically pick the deepest descendant in their bloodline
    let targetId = rootId
    if ((parentMap.get(targetId) || []).length === 0) {
      const descendants = []
      const dQueue = [targetId]
      const dVisited = new Set([targetId])
      while (dQueue.length > 0) {
        const curr = dQueue.shift()
        const children = childrenMap.get(curr) || []
        children.forEach(cid => {
          if (!dVisited.has(cid)) {
            dVisited.add(cid)
            descendants.push(cid)
            dQueue.push(cid)
          }
        })
      }
      if (descendants.length > 0) {
        targetId = descendants[descendants.length - 1]
      }
    }

    // Traverse upwards from targetId to all ancestors
    const distMap = new Map()
    distMap.set(targetId, 0)
    const queue = [targetId]
    const visited = new Set([targetId])

    while (queue.length > 0) {
      const currId = queue.shift()
      const currDist = distMap.get(currId)
      const parents = parentMap.get(currId) || []
      parents.forEach(pid => {
        const newDist = currDist + 1
        if (!distMap.has(pid) || distMap.get(pid) < newDist) {
          distMap.set(pid, newDist)
        }
        // Also pair spouse of this ancestor
        const spouses = spouseMap.get(pid) || []
        spouses.forEach(sid => {
          if (!distMap.has(sid)) {
            distMap.set(sid, newDist)
          }
        })
        if (!visited.has(pid)) {
          visited.add(pid)
          queue.push(pid)
        }
      })
    }

    const maxDist = Math.max(...distMap.values(), 0)

    // In vertical Top-Down: Oldest ancestor at top (level 0), targetId at bottom (level maxDist)
    // In horizontal Left-Right: targetId on left (level 0), oldest ancestor on right (level maxDist)
    distMap.forEach((dist, pid) => {
      if (layoutOrientation.value === 'horizontal') {
        levelMap.set(pid, dist)
      } else {
        levelMap.set(pid, maxDist - dist)
      }
    })
  } else {
    // Descendants mode
    levelMap.set(rootId, 0)
    const spouses = spouseMap.get(rootId) || []
    spouses.forEach(sId => levelMap.set(sId, 0))
    const queue = [{ id: rootId, lvl: 0 }]
    const visited = new Set([rootId])
    while (queue.length > 0) {
      const { id, lvl } = queue.shift()
      const children = childrenMap.get(id) || []
      children.forEach(cid => {
        if (!visited.has(cid)) {
          visited.add(cid)
          levelMap.set(cid, lvl + 1)
          const cSpouses = spouseMap.get(cid) || []
          cSpouses.forEach(sId => levelMap.set(sId, lvl + 1))
          queue.push({ id: cid, lvl: lvl + 1 })
        }
      })
    }
  }

  // Filter based on generation depth
  const maxLvl = generationFilter.value === '2' ? 1 : (generationFilter.value === '3' ? 2 : Infinity)
  const visiblePeople = peopleList.filter(p => {
    const lvl = levelMap.get(p.id)
    return lvl !== undefined && lvl <= maxLvl
  })

  // Group by level
  const levels = new Map()
  visiblePeople.forEach(p => {
    const lvl = levelMap.get(p.id)
    if (!levels.has(lvl)) levels.set(lvl, [])
    levels.get(lvl).push(p)
  })

  const sortedLevels = Array.from(levels.keys()).sort((a, b) => a - b)
  const highestLvl = sortedLevels.length > 0 ? sortedLevels[sortedLevels.length - 1] : 0

  const positionedNodes = new Map()
  const links = []
  const generationBanners = []

  // Helper to identify family couples on any level
  const getLevelCouples = (lvl) => {
    const peopleOnLvl = levels.get(lvl) || []
    const couples = []
    const handled = new Set()

    peopleOnLvl.forEach(p => {
      if (handled.has(p.id)) return
      handled.add(p.id)
      const sIds = (spouseMap.get(p.id) || []).filter(sid => peopleOnLvl.some(gp => gp.id === sid))
      const spouse = sIds.length > 0 ? peopleMap.get(sIds[0]) : null
      if (spouse) handled.add(spouse.id)

      const isDirect = (parentMap.get(p.id) || []).length > 0
      const primary = isDirect ? p : (spouse || p)
      const secondary = primary.id === p.id ? spouse : p
      const myChildren = (childrenMap.get(p.id) || []).concat(spouse ? (childrenMap.get(spouse.id) || []) : [])
      const uniqueChildren = Array.from(new Set(myChildren)).filter(cid => visiblePeople.some(vp => vp.id === cid))

      couples.push({
        primary,
        secondary,
        childrenIds: uniqueChildren
      })
    })

    couples.sort((a, b) => {
      const nameA = a.primary?.first_name || ''
      const nameB = b.primary?.first_name || ''
      return nameA.localeCompare(nameB)
    })
    return couples
  }

  // =========================================================================
  // MODE A: VERTICAL (TOP-TO-BOTTOM) DYNASTY TREE (REGAL & BALANCED)
  // =========================================================================
  if (layoutOrientation.value === 'vertical') {
    const CARD_WIDTH = 220
    const CARD_HEIGHT = 84
    const COUPLE_GAP = 52
    const SIBLING_GAP = 28
    const FAMILY_CLUSTER_GAP = 76
    const GEN_GAP_Y = 145

    const getY = (lvl) => 70 + lvl * (CARD_HEIGHT + GEN_GAP_Y)

    // Determine the parents level (level immediately above the leaf generation)
    const leafLevel = highestLvl
    const parentOfLeavesLvl = highestLvl >= 1 ? highestLvl - 1 : 0
    const parentCouples = getLevelCouples(parentOfLeavesLvl)

    let currentX = 80
    const clusterMidpoints = []

    // 1. Position Parent of Leaves and the Leaves (Children)
    parentCouples.forEach(couple => {
      const childNodes = []
      const cIds = couple.childrenIds
      const clusterStartX = currentX

      // Layout children side-by-side on leafLevel
      let childX = clusterStartX + 4
      cIds.forEach(cid => {
        const child = peopleMap.get(cid)
        if (!child) return
        const nodeObj = {
          id: child.id,
          person: child,
          x: childX,
          y: getY(leafLevel),
          level: leafLevel,
          spouses: (spouseMap.get(child.id) || []).map(sid => peopleMap.get(sid)).filter(Boolean),
          kinshipRole: getKinshipRole(child, parentMap, childrenMap)
        }
        positionedNodes.set(child.id, nodeObj)
        childNodes.push(nodeObj)
        childX += CARD_WIDTH + SIBLING_GAP
      })

      // Layout parents side-by-side on parentOfLeavesLvl
      const p1 = couple.primary
      const p2 = couple.secondary
      const p1X = clusterStartX
      const p2X = clusterStartX + CARD_WIDTH + COUPLE_GAP
      const clusterWidth = p2 ? (CARD_WIDTH * 2 + COUPLE_GAP) : CARD_WIDTH
      const clusterCenter = clusterStartX + clusterWidth / 2

      clusterMidpoints.push({
        center: clusterCenter,
        primaryNodeId: p1.id,
        secondaryNodeId: p2 ? p2.id : null,
        childrenIds: cIds,
        p1X,
        p2X
      })

      positionedNodes.set(p1.id, {
        id: p1.id,
        person: p1,
        x: p1X,
        y: getY(parentOfLeavesLvl),
        level: parentOfLeavesLvl,
        spouses: p2 ? [p2] : [],
        kinshipRole: getKinshipRole(p1, parentMap, childrenMap)
      })

      if (p2) {
        positionedNodes.set(p2.id, {
          id: p2.id,
          person: p2,
          x: p2X,
          y: getY(parentOfLeavesLvl),
          level: parentOfLeavesLvl,
          spouses: [p1],
          kinshipRole: getKinshipRole(p2, parentMap, childrenMap)
        })

        // Spousal Marriage Link
        links.push({
          id: `spouse-parent-${p1.id}-${p2.id}`,
          type: 'spouse',
          sourceId: p1.id,
          targetId: p2.id,
          badgeText: '💍',
          badgeX: (p1X + CARD_WIDTH + p2X) / 2,
          badgeY: getY(parentOfLeavesLvl) + CARD_HEIGHT / 2,
          path: `M ${p1X + CARD_WIDTH} ${getY(parentOfLeavesLvl) + CARD_HEIGHT / 2} H ${p2X}`,
          badgeWidth: 28
        })

        // Departure Stem & Distribution Bus to Children
        if (childNodes.length > 0) {
          const yBus = getY(parentOfLeavesLvl) + CARD_HEIGHT + 55
          const stemBadgeText = `👨‍👩‍👧 Family: ${p1.first_name} & ${p2.first_name}`

          // Vertical Departure Stem
          links.push({
            id: `stem-parents-${p1.id}-${p2.id}`,
            type: 'parents-stem',
            sourceId: p1.id,
            secondarySourceId: p2.id,
            targetId: null,
            badgeText: stemBadgeText,
            badgeX: clusterCenter,
            badgeY: getY(parentOfLeavesLvl) + CARD_HEIGHT + 22,
            path: `M ${clusterCenter} ${getY(parentOfLeavesLvl) + CARD_HEIGHT} V ${yBus}`,
            badgeWidth: Math.max(120, stemBadgeText.length * 6.2 + 18)
          })

          // Sibling Bus Bar
          const minChildX = childNodes[0].x + CARD_WIDTH / 2
          const maxChildX = childNodes[childNodes.length - 1].x + CARD_WIDTH / 2
          links.push({
            id: `bus-siblings-${p1.id}`,
            type: 'sibling-bus',
            sourceId: p1.id,
            secondarySourceId: p2.id,
            targetId: null,
            badgeText: '👥 Siblings',
            badgeX: clusterCenter,
            badgeY: yBus,
            path: `M ${minChildX} ${yBus} H ${maxChildX}`,
            badgeWidth: 64
          })

          // Drops into each child
          childNodes.forEach(cNode => {
            const cX = cNode.x + CARD_WIDTH / 2
            const isSon = cNode.person.gender === 'M'
            const isGrand = leafLevel >= 3
            const roleBadge = `${isGrand ? (isSon ? '👦 Grandson' : '👧 Granddaughter') : (isSon ? '👦 Son' : '👧 Daughter')}: ${cNode.person.first_name}`

            links.push({
              id: `branch-child-${cNode.id}`,
              type: 'child-branch',
              sourceId: p1.id,
              secondarySourceId: p2.id,
              targetId: cNode.id,
              badgeText: roleBadge,
              badgeX: cX,
              badgeY: getY(leafLevel) - 16,
              path: `M ${cX} ${yBus} V ${getY(leafLevel)}`,
              badgeWidth: Math.max(90, roleBadge.length * 6.2 + 16)
            })
          })
        }
      }

      currentX += clusterWidth + FAMILY_CLUSTER_GAP
    })

    // Overall horizontal clan center across all clusters
    let clanCenter = 550
    if (clusterMidpoints.length > 0) {
      const minCenter = clusterMidpoints[0].center
      const maxCenter = clusterMidpoints[clusterMidpoints.length - 1].center
      clanCenter = (minCenter + maxCenter) / 2
    }

    // 2. Position Generation 1 (Founding Grandparents: Jean & Amina if 4 levels, or top elders if 3 levels)
    if (parentOfLeavesLvl >= 1) {
      const g1Couples = getLevelCouples(parentOfLeavesLvl - 1)
      g1Couples.forEach(c => {
        const father = c.primary.gender === 'M' ? c.primary : c.secondary
        const mother = c.primary.gender === 'M' ? c.secondary : c.primary

        if (father && mother) {
          const fX = clanCenter - CARD_WIDTH - COUPLE_GAP / 2
          const mX = clanCenter + COUPLE_GAP / 2
          const yG1 = getY(parentOfLeavesLvl - 1)

          positionedNodes.set(father.id, {
            id: father.id,
            person: father,
            x: fX,
            y: yG1,
            level: parentOfLeavesLvl - 1,
            spouses: [mother],
            kinshipRole: getKinshipRole(father, parentMap, childrenMap)
          })

          positionedNodes.set(mother.id, {
            id: mother.id,
            person: mother,
            x: mX,
            y: yG1,
            level: parentOfLeavesLvl - 1,
            spouses: [father],
            kinshipRole: getKinshipRole(mother, parentMap, childrenMap)
          })

          // Marriage link
          links.push({
            id: `spouse-g1-${father.id}-${mother.id}`,
            type: 'spouse',
            sourceId: father.id,
            targetId: mother.id,
            badgeText: '💍',
            badgeX: clanCenter,
            badgeY: yG1 + CARD_HEIGHT / 2,
            path: `M ${fX + CARD_WIDTH} ${yG1 + CARD_HEIGHT / 2} H ${mX}`,
            badgeWidth: 28
          })

          // Stem and bus down to children (Arthur & Chloe)
          if (clusterMidpoints.length > 0) {
            const yBusG1 = yG1 + CARD_HEIGHT + 55
            const eldersBadge = `👑 Elders: ${father.first_name} & ${mother.first_name}`

            links.push({
              id: `stem-g1-elders`,
              type: 'parents-stem',
              sourceId: father.id,
              secondarySourceId: mother.id,
              targetId: null,
              badgeText: eldersBadge,
              badgeX: clanCenter,
              badgeY: yG1 + CARD_HEIGHT + 22,
              path: `M ${clanCenter} ${yG1 + CARD_HEIGHT} V ${yBusG1}`,
              badgeWidth: Math.max(130, eldersBadge.length * 6.2 + 18)
            })

            const firstX = clusterMidpoints[0].p1X + CARD_WIDTH / 2
            const lastX = clusterMidpoints[clusterMidpoints.length - 1].p1X + CARD_WIDTH / 2

            links.push({
              id: `bus-g1-siblings`,
              type: 'sibling-bus',
              sourceId: father.id,
              secondarySourceId: mother.id,
              targetId: null,
              badgeText: '👥 Siblings (Brother & Sister)',
              badgeX: clanCenter,
              badgeY: yBusG1,
              path: `M ${firstX} ${yBusG1} H ${lastX}`,
              badgeWidth: 140
            })

            clusterMidpoints.forEach(cm => {
              const childNode = positionedNodes.get(cm.primaryNodeId)
              if (!childNode) return
              const cX = childNode.x + CARD_WIDTH / 2
              const isSon = childNode.person.gender === 'M'
              const roleBadge = `${isSon ? '👦 Son' : '👧 Daughter'}: ${childNode.person.first_name}`

              links.push({
                id: `branch-g1-${childNode.id}`,
                type: 'child-branch',
                sourceId: father.id,
                secondarySourceId: mother.id,
                targetId: childNode.id,
                badgeText: roleBadge,
                badgeX: cX,
                badgeY: getY(parentOfLeavesLvl) - 16,
                path: `M ${cX} ${yBusG1} V ${getY(parentOfLeavesLvl)}`,
                badgeWidth: Math.max(90, roleBadge.length * 6.2 + 16)
              })
            })
          }
        }
      })
    }

    // 3. Position Generation 0 Ancestral Elders (e.g. Kamgou if 4 levels)
    if (parentOfLeavesLvl >= 2) {
      const g0People = levels.get(0) || []
      g0People.forEach(p => {
        // Center directly over Jean or clanCenter
        const jeanNode = positionedNodes.get(11)
        const elderX = jeanNode ? jeanNode.x : clanCenter - CARD_WIDTH / 2
        const elderY = getY(0)

        positionedNodes.set(p.id, {
          id: p.id,
          person: p,
          x: elderX,
          y: elderY,
          level: 0,
          spouses: [],
          kinshipRole: getKinshipRole(p, parentMap, childrenMap)
        })

        // Direct single-parent drop to child (Jean)
        const myChildren = childrenMap.get(p.id) || []
        myChildren.forEach(cid => {
          const cNode = positionedNodes.get(cid)
          if (!cNode) return
          const startX = elderX + CARD_WIDTH / 2
          const startY = elderY + CARD_HEIGHT
          const targetX = cNode.x + CARD_WIDTH / 2
          const targetY = cNode.y

          links.push({
            id: `stem-g0-child-${p.id}-${cid}`,
            type: 'child-branch',
            sourceId: p.id,
            targetId: cNode.id,
            badgeText: `👑 Father: ${p.first_name}`,
            badgeX: (startX + targetX) / 2,
            badgeY: startY + 26,
            path: verticalOrthogonalPath(startX, startY, targetX, targetY, 12),
            badgeWidth: 95
          })
        })
      })
    }

    // 4. Generation Banners across the canvas
    sortedLevels.forEach(lvl => {
      let title = `Generation ${lvl + 1}`
      if (highestLvl >= 3) {
        if (lvl === 0) title = '👑 Generation 1 • Ancestral Elder'
        else if (lvl === 1) title = '👑 Generation 2 • Founding Patriarchs & Matriarchs'
        else if (lvl === 2) title = '👨‍👩‍👧‍👦 Generation 3 • Parents & Siblings'
        else if (lvl === 3) title = '🌱 Generation 4 • Children & Grandchildren'
      } else {
        if (lvl === 0) title = '👑 Generation 1 • Founding Elders'
        else if (lvl === 1) title = '👨‍👩‍👧‍👦 Generation 2 • Parents & Siblings'
        else if (lvl === 2) title = '🌱 Generation 3 • Children & Descendants'
      }

      generationBanners.push({
        level: lvl,
        title,
        x: clanCenter,
        y: getY(lvl) - 44,
        width: Math.max(240, title.length * 7.0 + 26)
      })
    })
  }

  // =========================================================================
  // MODE B: HORIZONTAL (LEFT-TO-RIGHT) PEDIGREE CHART
  // =========================================================================
  else {
    const CARD_WIDTH = 230
    const CARD_HEIGHT = 82
    const LEVEL_GAP_X = 200
    const COUPLE_GAP = 14
    const SIBLING_GAP = 18
    const FAMILY_CLUSTER_GAP = 60

    let currentY = 70
    const parentOfLeavesLvl = highestLvl >= 1 ? highestLvl - 1 : 0
    const parentCouples = getLevelCouples(parentOfLeavesLvl)

    parentCouples.forEach(couple => {
      const childNodes = []
      const cIds = couple.childrenIds

      cIds.forEach(cid => {
        const child = peopleMap.get(cid)
        if (!child) return
        const x = parentOfLeavesLvl === 2 ? 3 * (CARD_WIDTH + LEVEL_GAP_X) + 80 : 2 * (CARD_WIDTH + LEVEL_GAP_X) + 80
        const y = currentY
        const nodeObj = {
          id: child.id,
          person: child,
          x,
          y,
          level: highestLvl,
          spouses: (spouseMap.get(child.id) || []).map(sid => peopleMap.get(sid)).filter(Boolean),
          kinshipRole: getKinshipRole(child, parentMap, childrenMap)
        }
        positionedNodes.set(child.id, nodeObj)
        childNodes.push(nodeObj)
        currentY += CARD_HEIGHT + SIBLING_GAP
      })

      let coupleCenterY
      if (childNodes.length > 0) {
        const minY = childNodes[0].y
        const maxY = childNodes[childNodes.length - 1].y + CARD_HEIGHT
        coupleCenterY = (minY + maxY) / 2
      } else {
        coupleCenterY = currentY + CARD_HEIGHT
        currentY += (CARD_HEIGHT * 2 + COUPLE_GAP + SIBLING_GAP)
      }

      const genPX = parentOfLeavesLvl === 2 ? 2 * (CARD_WIDTH + LEVEL_GAP_X) + 80 : 1 * (CARD_WIDTH + LEVEL_GAP_X) + 80
      const p1 = couple.primary
      const p2 = couple.secondary

      if (p1 && p2) {
        const p1Y = coupleCenterY - CARD_HEIGHT - COUPLE_GAP / 2
        const p2Y = coupleCenterY + COUPLE_GAP / 2

        positionedNodes.set(p1.id, {
          id: p1.id,
          person: p1,
          x: genPX,
          y: p1Y,
          level: parentOfLeavesLvl,
          spouses: [p2],
          kinshipRole: getKinshipRole(p1, parentMap, childrenMap)
        })

        positionedNodes.set(p2.id, {
          id: p2.id,
          person: p2,
          x: genPX,
          y: p2Y,
          level: parentOfLeavesLvl,
          spouses: [p1],
          kinshipRole: getKinshipRole(p2, parentMap, childrenMap)
        })

        links.push({
          id: `h-spouse-${p1.id}-${p2.id}`,
          type: 'spouse',
          sourceId: p1.id,
          targetId: p2.id,
          badgeText: '💍',
          badgeX: genPX + CARD_WIDTH / 2,
          badgeY: (p1Y + CARD_HEIGHT + p2Y) / 2,
          path: `M ${genPX + CARD_WIDTH / 2} ${p1Y + CARD_HEIGHT} V ${p2Y}`,
          badgeWidth: 26
        })

        const startX = genPX + CARD_WIDTH
        const startY = coupleCenterY
        const xMid = startX + LEVEL_GAP_X * 0.42
        const parentsBadgeText = `👨‍👩‍👧 Family: ${p1.first_name} & ${p2.first_name}`

        links.push({
          id: `h-stem-${p1.id}-${p2.id}`,
          type: 'parents-stem',
          sourceId: p1.id,
          secondarySourceId: p2.id,
          targetId: null,
          badgeText: parentsBadgeText,
          badgeX: startX + 42,
          badgeY: startY,
          path: `M ${startX} ${startY} H ${xMid}`,
          badgeWidth: Math.max(120, parentsBadgeText.length * 6.2 + 18)
        })

        childNodes.forEach(cNode => {
          const isSon = cNode.person.gender === 'M'
          const roleBadge = `${isSon ? '👦 Grandson' : '👧 Granddaughter'}: ${cNode.person.first_name}`
          links.push({
            id: `h-branch-${cNode.id}`,
            type: 'child-branch',
            sourceId: p1.id,
            secondarySourceId: p2.id,
            targetId: cNode.id,
            badgeText: roleBadge,
            badgeX: cNode.x - 65,
            badgeY: cNode.y + CARD_HEIGHT / 2,
            path: roundedOrthogonalPath(xMid, startY, cNode.x, cNode.y + CARD_HEIGHT / 2, 12),
            badgeWidth: Math.max(90, roleBadge.length * 6.2 + 16)
          })
        })
      }

      currentY += FAMILY_CLUSTER_GAP
    })

    // Grandparents Level (Jean & Amina)
    if (parentOfLeavesLvl >= 1) {
      const g1Couples = getLevelCouples(parentOfLeavesLvl - 1)
      const genG1X = parentOfLeavesLvl === 2 ? 1 * (CARD_WIDTH + LEVEL_GAP_X) + 80 : 80
      const placedParents = Array.from(positionedNodes.values()).filter(n => n.level === parentOfLeavesLvl)
      let g1CenterY = 320
      if (placedParents.length > 0) {
        const minY = Math.min(...placedParents.map(n => n.y))
        const maxY = Math.max(...placedParents.map(n => n.y + CARD_HEIGHT))
        g1CenterY = (minY + maxY) / 2
      }

      g1Couples.forEach(c => {
        const father = c.primary.gender === 'M' ? c.primary : c.secondary
        const mother = c.primary.gender === 'M' ? c.secondary : c.primary
        if (father && mother) {
          const fY = g1CenterY - CARD_HEIGHT - COUPLE_GAP / 2
          const mY = g1CenterY + COUPLE_GAP / 2

          positionedNodes.set(father.id, {
            id: father.id,
            person: father,
            x: genG1X,
            y: fY,
            level: parentOfLeavesLvl - 1,
            spouses: [mother],
            kinshipRole: getKinshipRole(father, parentMap, childrenMap)
          })

          positionedNodes.set(mother.id, {
            id: mother.id,
            person: mother,
            x: genG1X,
            y: mY,
            level: parentOfLeavesLvl - 1,
            spouses: [father],
            kinshipRole: getKinshipRole(mother, parentMap, childrenMap)
          })

          links.push({
            id: `h-spouse-g1`,
            type: 'spouse',
            sourceId: father.id,
            targetId: mother.id,
            badgeText: '💍',
            badgeX: genG1X + CARD_WIDTH / 2,
            badgeY: g1CenterY,
            path: `M ${genG1X + CARD_WIDTH / 2} ${fY + CARD_HEIGHT} V ${mY}`,
            badgeWidth: 26
          })

          const startX = genG1X + CARD_WIDTH
          const startY = g1CenterY
          const xMid = startX + LEVEL_GAP_X * 0.42
          const eldersBadgeText = `👑 Elders: ${father.first_name} & ${mother.first_name}`

          links.push({
            id: `h-stem-g1`,
            type: 'parents-stem',
            sourceId: father.id,
            secondarySourceId: mother.id,
            targetId: null,
            badgeText: eldersBadgeText,
            badgeX: startX + 42,
            badgeY: startY,
            path: `M ${startX} ${startY} H ${xMid}`,
            badgeWidth: Math.max(120, eldersBadgeText.length * 6.2 + 18)
          })

          parentCouples.forEach(c => {
            const childNode = positionedNodes.get(c.primary.id)
            if (!childNode) return
            const isSon = childNode.person.gender === 'M'
            const roleBadge = `${isSon ? '👦 Son' : '👧 Daughter'}: ${childNode.person.first_name}`
            links.push({
              id: `h-branch-g1-${childNode.id}`,
              type: 'child-branch',
              sourceId: father.id,
              secondarySourceId: mother.id,
              targetId: childNode.id,
              badgeText: roleBadge,
              badgeX: childNode.x - 65,
              badgeY: childNode.y + CARD_HEIGHT / 2,
              path: roundedOrthogonalPath(xMid, startY, childNode.x, childNode.y + CARD_HEIGHT / 2, 12),
              badgeWidth: Math.max(90, roleBadge.length * 6.2 + 16)
            })
          })
        }
      })
    }

    // Top Ancestral Elder (Kamgou if 4 levels)
    if (parentOfLeavesLvl >= 2) {
      const g0People = levels.get(0) || []
      g0People.forEach(p => {
        const jeanNode = positionedNodes.get(11)
        const g0Y = jeanNode ? jeanNode.y : 200
        const g0X = 80

        positionedNodes.set(p.id, {
          id: p.id,
          person: p,
          x: g0X,
          y: g0Y,
          level: 0,
          spouses: [],
          kinshipRole: getKinshipRole(p, parentMap, childrenMap)
        })

        if (jeanNode) {
          links.push({
            id: `h-branch-g0-jean`,
            type: 'child-branch',
            sourceId: p.id,
            targetId: jeanNode.id,
            badgeText: `👑 Father: ${p.first_name}`,
            badgeX: (g0X + CARD_WIDTH + jeanNode.x) / 2,
            badgeY: g0Y + CARD_HEIGHT / 2,
            path: `M ${g0X + CARD_WIDTH} ${g0Y + CARD_HEIGHT / 2} H ${jeanNode.x}`,
            badgeWidth: 95
          })
        }
      })
    }

    // Column Banners for Horizontal View
    sortedLevels.forEach(lvl => {
      const x = lvl * (CARD_WIDTH + LEVEL_GAP_X) + 80
      let title = `Generation ${lvl + 1}`
      if (highestLvl >= 3) {
        if (lvl === 0) title = '👑 Generation 1 • Ancestral Elder'
        else if (lvl === 1) title = '👑 Generation 2 • Founding Elders'
        else if (lvl === 2) title = '👨‍👩‍👧‍👦 Generation 3 • Parents & Siblings'
        else if (lvl === 3) title = '🌱 Generation 4 • Children & Grandchildren'
      } else {
        if (lvl === 0) title = '👑 Generation 1 • Founding Elders'
        else if (lvl === 1) title = '👨‍👩‍👧‍👦 Generation 2 • Parents & Siblings'
        else if (lvl === 2) title = '🌱 Generation 3 • Children & Descendants'
      }

      generationBanners.push({
        level: lvl,
        title,
        x: x + CARD_WIDTH / 2,
        y: 24,
        width: Math.max(220, title.length * 6.8 + 24)
      })
    })
  }

  return {
    nodes: Array.from(positionedNodes.values()),
    links,
    generationBanners
  }
}

// -------------------------------------------------------------
// D3 SVG Tree Renderer with Museum-Grade Luxury Royal Cards
// -------------------------------------------------------------
const renderPedigreeTree = () => {
  if (!treeContainer.value || people.value.length === 0) return

  d3.select(treeContainer.value).selectAll('*').remove()

  const { nodes: graphNodes, links: graphLinks, generationBanners } = buildClanGraph(rootPersonId.value)
  if (graphNodes.length === 0) return

  const containerWidth = treeContainer.value.clientWidth || 1000
  const containerHeight = treeContainer.value.clientHeight || 700

  // Setup SVG
  svg.value = d3.select(treeContainer.value)
    .append('svg')
    .attr('width', '100%')
    .attr('height', '100%')
    .attr('class', 'cursor-grab active:cursor-grabbing select-none')

  // Gradients and Patterns in SVG defs
  const defs = svg.value.append('defs')

  // Dot grid pattern
  const pattern = defs.append('pattern')
    .attr('id', 'tree-dot-grid')
    .attr('width', 32)
    .attr('height', 32)
    .attr('patternUnits', 'userSpaceOnUse')

  pattern.append('circle')
    .attr('cx', 16)
    .attr('cy', 16)
    .attr('r', 1.1)
    .attr('fill', isLight.value ? 'rgba(184, 134, 11, 0.12)' : 'rgba(197, 160, 89, 0.12)')

  // Card Background Gradient (Obsidian Luxury)
  const cardBgGrad = defs.append('linearGradient')
    .attr('id', 'card-bg-gradient')
    .attr('x1', '0%').attr('y1', '0%')
    .attr('x2', '100%').attr('y2', '100%')

  cardBgGrad.append('stop').attr('offset', '0%').attr('stop-color', isLight.value ? '#FFFFFF' : '#181A24')
  cardBgGrad.append('stop').attr('offset', '100%').attr('stop-color', isLight.value ? '#FBF9F4' : '#101117')

  // Medallion Inner Gradient
  const medallionGrad = defs.append('radialGradient')
    .attr('id', 'medallion-gradient')
    .attr('cx', '50%').attr('cy', '45%').attr('r', '60%')

  medallionGrad.append('stop').attr('offset', '0%').attr('stop-color', isLight.value ? '#FFFDF8' : '#222533')
  medallionGrad.append('stop').attr('offset', '100%').attr('stop-color', isLight.value ? '#EFE7D6' : '#111218')

  // Main group
  g.value = svg.value.append('g')

  // Background rect with subtle dot grid
  g.value.append('rect')
    .attr('x', -3000)
    .attr('y', -3000)
    .attr('width', 8000)
    .attr('height', 8000)
    .attr('fill', 'url(#tree-dot-grid)')
    .style('pointer-events', 'none')

  // Zoom behavior
  zoom.value = d3.zoom()
    .scaleExtent([0.25, 2.8])
    .on('zoom', (event) => {
      g.value.attr('transform', event.transform)
      zoomPercentage.value = Math.round(event.transform.k * 100)
    })

  svg.value.call(zoom.value)

  // Calculate bounding box of entire graph
  let minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity
  graphNodes.forEach(d => {
    if (d.x < minX) minX = d.x
    if (d.x + 220 > maxX) maxX = d.x + 220
    if (d.y < minY) minY = d.y
    if (d.y + 84 > maxY) maxY = d.y + 84
  })
  generationBanners.forEach(b => {
    if (b.y < minY) minY = b.y - 12
  })

  const treeWidth = maxX - minX
  const treeHeight = maxY - minY

  const scale = Math.min(1.05, Math.max(0.68, Math.min(
    (containerWidth - 100) / (treeWidth || 1),
    (containerHeight - 100) / (treeHeight || 1)
  )))
  const translateX = (containerWidth - treeWidth * scale) / 2 - minX * scale
  const translateY = (containerHeight - treeHeight * scale) / 2 - minY * scale

  const initialTransform = d3.zoomIdentity
    .translate(translateX, translateY)
    .scale(scale)

  initialTransformRef.value = initialTransform
  svg.value.call(zoom.value.transform, initialTransform)

  // 1. Draw Filleted Connector Lines
  const linksGroup = g.value.append('g').attr('class', 'links')

  const linkPaths = linksGroup.selectAll('path')
    .data(graphLinks)
    .enter()
    .append('path')
    .attr('id', d => d.id)
    .attr('d', d => d.path)
    .attr('fill', 'none')
    .attr('stroke', d => {
      if (d.type === 'spouse') return '#C5A059'
      if (d.type === 'parents-stem') return isLight.value ? '#B8860B' : '#D4AF37'
      if (d.type === 'sibling-bus') return isLight.value ? '#B8860B' : '#C5A059'
      return isLight.value ? '#B8860B' : '#C5A059'
    })
    .attr('stroke-width', d => {
      if (d.type === 'spouse') return 1.8
      if (d.type === 'parents-stem') return 2.4
      return 2.0
    })
    .attr('stroke-dasharray', d => d.type === 'spouse' ? '5 4' : 'none')
    .attr('stroke-linecap', 'round')
    .attr('stroke-linejoin', 'round')
    .attr('opacity', 0.88)

  // 2. Generation Banners across Canvas (solid background to mask behind lines)
  const bannersGroup = g.value.append('g').attr('class', 'generation-banners')
  generationBanners.forEach(b => {
    const bg = bannersGroup.append('g')
      .attr('transform', `translate(${b.x}, ${b.y})`)

    bg.append('rect')
      .attr('x', -b.width / 2)
      .attr('y', -13)
      .attr('width', b.width)
      .attr('height', 26)
      .attr('rx', 13)
      .attr('fill', isLight.value ? '#FFFFFF' : '#14161F')
      .attr('stroke', '#C5A059')
      .attr('stroke-width', 1.2)
      .attr('filter', isLight.value ? 'drop-shadow(0 2px 4px rgba(184, 134, 11, 0.12))' : 'drop-shadow(0 2px 6px rgba(0,0,0,0.5))')

    bg.append('text')
      .attr('text-anchor', 'middle')
      .attr('y', 4.5)
      .attr('font-size', 11)
      .attr('font-weight', '800')
      .attr('letter-spacing', '0.4px')
      .attr('fill', isLight.value ? '#674B19' : '#F3E5AB')
      .text(b.title)
  })

  // 3. Draw Refined Branch Relation Badges
  let branchBadges = null
  if (branchLabelMode.value === 'clean') {
    branchBadges = g.value.append('g').attr('class', 'branch-badges')
      .selectAll('g')
      .data(graphLinks)
      .enter()
      .append('g')
      .attr('transform', d => `translate(${d.badgeX}, ${d.badgeY})`)

    branchBadges.append('rect')
      .attr('x', d => -d.badgeWidth / 2)
      .attr('y', d => d.type === 'spouse' ? -12 : -10)
      .attr('width', d => d.badgeWidth)
      .attr('height', d => d.type === 'spouse' ? 24 : 20)
      .attr('rx', d => d.type === 'spouse' ? 12 : 10)
      .attr('fill', isLight.value ? '#FFFFFF' : '#14161F')
      .attr('stroke', '#C5A059')
      .attr('stroke-width', 1.1)
      .attr('filter', isLight.value ? 'drop-shadow(0 2px 4px rgba(184, 134, 11, 0.12))' : 'drop-shadow(0 2px 5px rgba(0,0,0,0.75))')

    branchBadges.append('text')
      .attr('text-anchor', 'middle')
      .attr('y', d => d.type === 'spouse' ? 4 : 3.5)
      .attr('font-size', d => d.type === 'spouse' ? 12 : 9.5)
      .attr('font-weight', '700')
      .attr('fill', isLight.value ? '#5B3D0B' : '#F3E5AB')
      .text(d => d.badgeText)
  }

  // 4. Draw Museum-Grade Luxury Node Cards
  const nodes = g.value.append('g')
    .attr('class', 'nodes')
    .selectAll('g')
    .data(graphNodes)
    .enter()
    .append('g')
    .attr('transform', d => `translate(${d.x}, ${d.y})`)
    .style('cursor', 'pointer')
    .on('click', (event, d) => {
      event.stopPropagation()
      selectedNode.value = d.person
    })
    // Interactive Line Highlighting on hover
    .on('mouseenter', (event, d) => {
      const pid = d.person.id
      linkPaths
        .transition().duration(150)
        .attr('opacity', l => (l.sourceId === pid || l.targetId === pid || l.secondarySourceId === pid) ? 1.0 : 0.2)
        .attr('stroke', l => (l.sourceId === pid || l.targetId === pid || l.secondarySourceId === pid) ? '#F3E5AB' : (isLight.value ? '#B8860B' : '#C5A059'))
        .attr('stroke-width', l => (l.sourceId === pid || l.targetId === pid || l.secondarySourceId === pid) ? 3.0 : 1.4)

      if (branchBadges) {
        branchBadges.transition().duration(150)
          .attr('opacity', l => (l.sourceId === pid || l.targetId === pid || l.secondarySourceId === pid) ? 1.0 : 0.25)
      }
    })
    .on('mouseleave', () => {
      linkPaths
        .transition().duration(200)
        .attr('opacity', 0.88)
        .attr('stroke', l => {
          if (l.type === 'spouse') return '#C5A059'
          if (l.type === 'parents-stem') return isLight.value ? '#B8860B' : '#D4AF37'
          return isLight.value ? '#B8860B' : '#C5A059'
        })
        .attr('stroke-width', l => {
          if (l.type === 'spouse') return 1.8
          if (l.type === 'parents-stem') return 2.4
          return 2.0
        })

      if (branchBadges) {
        branchBadges.transition().duration(200).attr('opacity', 1.0)
      }
    })

  // Card background rectangle (luxury border & gradient)
  nodes.append('rect')
    .attr('width', 220)
    .attr('height', 84)
    .attr('rx', 14)
    .attr('ry', 14)
    .attr('fill', 'url(#card-bg-gradient)')
    .attr('stroke', d => d.person.id === rootPersonId.value ? '#D4AF37' : (isLight.value ? '#C5A059' : '#8A6828'))
    .attr('stroke-width', d => d.person.id === rootPersonId.value ? 2.0 : 1.2)
    .attr('filter', isLight.value ? 'drop-shadow(0 3px 8px rgba(184, 134, 11, 0.10))' : 'drop-shadow(0 4px 12px rgba(0,0,0,0.65))')

  // Clip path for photo avatars if present
  graphNodes.forEach(d => {
    if (d.person.avatar || d.person.profile_picture) {
      defs.append('clipPath')
        .attr('id', `avatar-clip-${d.id}`)
        .append('circle')
        .attr('cx', 28)
        .attr('cy', 42)
        .attr('r', 18)
    }
  })

  // Royal Monogram / Portrait Medallion
  // Outer fine gold ring
  nodes.append('circle')
    .attr('cx', 28)
    .attr('cy', 42)
    .attr('r', 19.5)
    .attr('fill', 'url(#medallion-gradient)')
    .attr('stroke', '#C5A059')
    .attr('stroke-width', 1.4)

  // Render Image if available, otherwise Dignified Royal Monogram Initials
  nodes.each(function(d) {
    const el = d3.select(this)
    const imgUrl = d.person.avatar || d.person.profile_picture

    if (imgUrl) {
      el.append('image')
        .attr('href', imgUrl)
        .attr('x', 9)
        .attr('y', 23)
        .attr('width', 38)
        .attr('height', 38)
        .attr('clip-path', `url(#avatar-clip-${d.id})`)
        .attr('preserveAspectRatio', 'xMidYMid slice')
    } else {
      // Dignified Classical Monogram
      el.append('text')
        .attr('x', 28)
        .attr('y', 47)
        .attr('text-anchor', 'middle')
        .attr('font-family', 'Cinzel, Georgia, serif')
        .attr('font-size', 13.5)
        .attr('font-weight', '800')
        .attr('fill', isLight.value ? '#7D5814' : '#F3E5AB')
        .text(getInitials(d.person))

      // Micro Insignia above initials (Crown for Elders, Fleur-de-lis for Gen 2, Sprout for Gen 3)
      const insignia = d.level === 0 ? '👑' : (d.level === 1 ? '⚜️' : '🌱')
      el.append('text')
        .attr('x', 28)
        .attr('y', 29)
        .attr('text-anchor', 'middle')
        .attr('font-size', 8)
        .text(insignia)
    }

    // Discrete Gender Gem (Soft Ruby for Female, Soft Sapphire for Male)
    el.append('circle')
      .attr('cx', 40)
      .attr('cy', 28)
      .attr('r', 3.8)
      .attr('fill', d.person.gender === 'F' ? '#F43F5E' : '#38BDF8')
      .attr('stroke', isLight.value ? '#FFFFFF' : '#14161F')
      .attr('stroke-width', 1.0)
  })

  // Name text (displays traditional title if present)
  nodes.append('text')
    .attr('x', 56)
    .attr('y', 23)
    .attr('font-size', 13)
    .attr('font-weight', '900')
    .attr('fill', isLight.value ? '#121316' : '#FAF9F6')
    .text(d => {
      const p = d.person
      const name = p.traditional_name || p.traditionalName || `${p.first_name || p.firstName || ''} ${p.last_name || p.lastName || ''}`.trim()
      return name.length > 18 ? name.slice(0, 16) + '...' : (name || 'Family Member')
    })

  // Kinship Role Tag Pill (Patriarch / Matriarch / Son / Daughter / Grandchild)
  const roleGroup = nodes.append('g')
    .attr('transform', 'translate(56, 29)')

  roleGroup.append('rect')
    .attr('width', d => Math.min(145, d.kinshipRole.length * 6.0 + 10))
    .attr('height', 15)
    .attr('rx', 4.5)
    .attr('fill', isLight.value ? '#F6EEDB' : 'rgba(197, 160, 89, 0.15)')
    .attr('stroke', '#C5A059')
    .attr('stroke-width', 0.8)

  roleGroup.append('text')
    .attr('x', 5)
    .attr('y', 11)
    .attr('font-size', 9)
    .attr('font-weight', 'bold')
    .attr('letter-spacing', '0.2px')
    .attr('fill', isLight.value ? '#634208' : '#F3E5AB')
    .text(d => d.kinshipRole)

  // Birth & Origin metadata
  nodes.append('text')
    .attr('x', 56)
    .attr('y', 57)
    .attr('font-size', 10)
    .attr('font-weight', '600')
    .attr('fill', isLight.value ? '#6B4F18' : '#D4AF37')
    .text(d => formatBirth(d.person))

  // Cultural Totem / Clan
  nodes.append('text')
    .attr('x', 56)
    .attr('y', 70)
    .attr('font-size', 9.5)
    .attr('font-weight', '600')
    .attr('fill', isLight.value ? '#8A6828' : '#A8A29E')
    .text(d => {
      const p = d.person
      const totem = p.clan_totem || p.clanTotem
      const village = p.village_of_origin || p.villageOfOrigin || p.village
      if (totem) {
        return `${totem}${village ? ' • ' + village : ''}`
      }
      if (d.spouses && d.spouses.length > 0) {
        const spouseNames = d.spouses.map(s => s.first_name || s.firstName).join(', ')
        return `💍 ${spouseNames}`
      }
      return formatOther(d.person)
    })

  // Quick Action Button on right side of card (+ Relative)
  const actionGroup = nodes.append('g')
    .attr('transform', 'translate(198, 8)')
    .style('cursor', 'pointer')

  actionGroup.append('circle')
    .attr('cx', 9)
    .attr('cy', 9)
    .attr('r', 9.5)
    .attr('fill', isLight.value ? '#F6EEDB' : 'rgba(197, 160, 89, 0.15)')
    .attr('stroke', '#C5A059')
    .attr('stroke-width', 0.9)

  actionGroup.append('text')
    .attr('x', 9)
    .attr('y', 12.5)
    .attr('text-anchor', 'middle')
    .attr('font-size', 12)
    .attr('font-weight', 'bold')
    .attr('fill', isLight.value ? '#674B19' : '#F3E5AB')
    .text('+')

  actionGroup.on('click', (event, d) => {
    event.stopPropagation()
    selectedNode.value = d.person
    openAddRelative(d.person, 'child')
  })
}

// Watch theme changes to re-render tree colors seamlessly
watch(isLight, () => {
  renderPedigreeTree()
})

// Watch root route query change to seamlessly switch focus when navigating back from profile
watch(() => route.query.root, (newRoot) => {
  if (newRoot) {
    const qId = parseInt(newRoot)
    const found = people.value.find(p => p.id === qId)
    if (found) {
      rootPersonId.value = qId
      selectedNode.value = found
      renderPedigreeTree()
    }
  }
})

// -------------------------------------------------------------
// High-Resolution Lineage Poster Export (Canvas -> PNG)
// -------------------------------------------------------------
const exportLineagePoster = () => {
  if (!svg.value) return
  const svgEl = svg.value.node()
  if (!svgEl) return

  try {
    const serializer = new XMLSerializer()
    let svgString = serializer.serializeToString(svgEl)
    if (!svgString.match(/^<svg[^>]+xmlns="http\:\/\/www\.w3\.org\/2000\/svg"/)) {
      svgString = svgString.replace(/^<svg/, '<svg xmlns="http://www.w3.org/2000/svg"')
    }

    const svgBlob = new Blob([svgString], { type: 'image/svg+xml;charset=utf-8' })
    const url = URL.createObjectURL(svgBlob)
    const img = new Image()

    img.onload = () => {
      const bbox = svgEl.getBBox ? svgEl.getBBox() : { width: 1200, height: 800 }
      const width = Math.max(1600, Math.round((bbox.width || 1200) * 1.5))
      const height = Math.max(1100, Math.round((bbox.height || 800) * 1.5))

      const canvas = document.createElement('canvas')
      canvas.width = width
      canvas.height = height
      const ctx = canvas.getContext('2d')

      // Fill royal canvas background
      ctx.fillStyle = isLight.value ? '#FAF7F0' : '#0B0C0E'
      ctx.fillRect(0, 0, width, height)

      // Header Banner
      ctx.fillStyle = isLight.value ? '#121316' : '#F3E5AB'
      ctx.font = 'bold 36px serif'
      ctx.textAlign = 'center'
      ctx.fillText('KKEVO ROYAL LINEAGE & CLAN TREE', width / 2, 70)

      ctx.fillStyle = isLight.value ? '#855B14' : '#C5A059'
      ctx.font = 'bold 17px sans-serif'
      ctx.fillText(`Ancestral Lineage • Generated on ${new Date().toLocaleDateString()} • Traditional Heritage Archive`, width / 2, 105)

      // Outer gold border on canvas poster
      ctx.strokeStyle = '#C5A059'
      ctx.lineWidth = 5
      ctx.strokeRect(20, 20, width - 40, height - 40)

      // Inner thin gold accent border
      ctx.lineWidth = 1.5
      ctx.strokeRect(28, 28, width - 56, height - 56)

      // Draw SVG Tree
      ctx.drawImage(img, 40, 140, width - 80, height - 200)

      // Bottom footer watermark
      ctx.fillStyle = isLight.value ? '#855B14' : '#C5A059'
      ctx.font = '14px sans-serif'
      ctx.textAlign = 'center'
      ctx.fillText('👑 Kkevo Family Tree • Preserving African Roots & Lineage Across Generations', width / 2, height - 35)

      // Trigger download
      const pngUrl = canvas.toDataURL('image/png')
      const link = document.createElement('a')
      link.download = `kkevo-family-lineage-poster-${new Date().toISOString().slice(0, 10)}.png`
      link.href = pngUrl
      link.click()

      URL.revokeObjectURL(url)
      toast.success('High-resolution Lineage Poster exported!')
    }

    img.onerror = () => {
      const link = document.createElement('a')
      link.download = `kkevo-family-tree-${new Date().toISOString().slice(0, 10)}.svg`
      link.href = url
      link.click()
      toast.success('Lineage SVG tree exported!')
    }

    img.src = url
  } catch (err) {
    console.error('Export failed:', err)
    toast.error('Failed to export poster')
  }
}

// -------------------------------------------------------------
// Zoom Controls
// -------------------------------------------------------------
const zoomIn = () => {
  if (zoom.value && svg.value) {
    zoom.value.scaleBy(svg.value.transition().duration(250), 1.25)
  }
}

const zoomOut = () => {
  if (zoom.value && svg.value) {
    zoom.value.scaleBy(svg.value.transition().duration(250), 0.8)
  }
}

const resetZoom = () => {
  if (zoom.value && svg.value && initialTransformRef.value) {
    svg.value.transition().duration(400).call(zoom.value.transform, initialTransformRef.value)
  } else if (zoom.value && svg.value && treeContainer.value) {
    const containerHeight = treeContainer.value.clientHeight || 700
    const initialTransform = d3.zoomIdentity
      .translate(80, containerHeight / 2)
      .scale(0.85)
    svg.value.transition().duration(400).call(zoom.value.transform, initialTransform)
  }
}

// -------------------------------------------------------------
// Relative Modal Interactions
// -------------------------------------------------------------
const openAddRelative = (targetPerson, role) => {
  modalTargetPerson.value = targetPerson
  modalInitialRelation.value = role
  showAddModal.value = true
}

const openGlobalAddPerson = () => {
  modalTargetPerson.value = people.value[0] || null
  modalInitialRelation.value = 'child'
  showAddModal.value = true
}

const onRelativeCreated = async () => {
  await loadData()
}

onMounted(() => {
  loadData()
  window.addEventListener('resize', renderPedigreeTree)
})

onUnmounted(() => {
  window.removeEventListener('resize', renderPedigreeTree)
})
</script>

<style scoped>
/* Ultra-smooth vector line rendering */
svg path {
  shape-rendering: geometricPrecision;
}
</style>