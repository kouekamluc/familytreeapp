<template>
  <div
    class="min-h-screen flex flex-col font-sans transition-colors duration-300 selection:bg-[#C5A059] selection:text-black"
    :class="isLight ? 'bg-[#FAF8F5] text-stone-900' : 'bg-[#0E0F12] text-stone-100'"
  >
    <!-- ========================================================= -->
    <!-- 1. HERO SECTION: Royal Authority & Value Proposition     -->
    <!-- ========================================================= -->
    <section
      class="relative overflow-hidden border-b transition-colors duration-300 pt-10 pb-16 lg:pt-16 lg:pb-24"
      :class="[
        isLight
          ? 'bg-gradient-to-b from-[#FFFDF8] via-[#FAF6ED] to-[#F5EFE1] border-[#C5A059]/30'
          : 'bg-gradient-to-b from-[#14161F] via-[#101116] to-[#0E0F12] border-[#C5A059]/30'
      ]"
    >
      <!-- Subtle Golden Ambient Glow -->
      <div
        class="absolute -top-32 left-1/2 -translate-x-1/2 w-[850px] h-[550px] blur-3xl pointer-events-none rounded-full"
        :class="isLight ? 'bg-[#D4AF37]/15' : 'bg-[#D4AF37]/10'"
      ></div>

      <div class="container mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <!-- Header Text -->
        <div class="text-center max-w-4xl mx-auto">
          <!-- Prestigious Pill Badge -->
          <div
            class="inline-flex items-center gap-2.5 px-4 py-2 rounded-full border shadow-md mb-6 transition-all"
            :class="isLight ? 'bg-white border-[#C5A059] text-[#7A520C]' : 'bg-[#181A22] border-[#C5A059]/70 text-[#F3E5AB] shadow-black/50'"
          >
            <span class="text-base">👑</span>
            <span class="text-xs font-serif font-black tracking-widest uppercase">
              Kkevo Royal Heritage & Living Lineage
            </span>
          </div>

          <!-- Main Title -->
          <h1 class="text-4xl sm:text-6xl lg:text-7xl font-serif font-black tracking-tight leading-tight sm:leading-none">
            <span class="block" :class="isLight ? 'text-stone-900' : 'text-stone-100'">
              Honor Your Ancestors.
            </span>
            <span class="block mt-2 text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] drop-shadow-sm">
              Unite Every Generation.
            </span>
          </h1>

          <!-- Subtitle -->
          <p
            class="mt-6 text-base sm:text-lg lg:text-xl max-w-2xl mx-auto font-normal leading-relaxed"
            :class="isLight ? 'text-stone-700' : 'text-stone-300'"
          >
            The digital sanctuary for the <span class="font-bold text-[#B8860B]">Kkevo Family</span>. Explore your ancestral tree with museum-grade precision, calculate kinship ties across generations, preserve oral lore, and pass down your royal bloodline.
          </p>

          <!-- CTAs -->
          <div class="mt-8 flex flex-col sm:flex-row items-center justify-center gap-4">
            <router-link
              to="/tree"
              class="w-full sm:w-auto px-8 py-4 rounded-2xl text-sm font-black tracking-wide text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-110 shadow-xl shadow-[#C5A059]/25 transition-all flex items-center justify-center gap-2.5 active:scale-95 cursor-pointer"
            >
              <span class="text-xl">🌳</span>
              <span>Explore Interactive Tree</span>
            </router-link>

            <router-link
              to="/people"
              class="w-full sm:w-auto px-7 py-4 rounded-2xl text-sm font-bold tracking-wide transition-all flex items-center justify-center gap-2.5 active:scale-95 shadow-md border-2"
              :class="isLight ? 'bg-white hover:bg-stone-50 border-[#C5A059] text-[#634208]' : 'bg-[#181A22] hover:bg-[#20222C] border-[#C5A059]/60 text-[#F3E5AB]'"
            >
              <span class="text-xl">👥</span>
              <span>Browse Family Members</span>
            </router-link>

            <router-link
              to="/relationships"
              class="w-full sm:w-auto px-6 py-4 rounded-2xl text-sm font-bold transition-all flex items-center justify-center gap-2"
              :class="isLight ? 'text-stone-700 hover:text-black' : 'text-stone-300 hover:text-white'"
            >
              <span>🔗 Kinship Calculator</span>
              <span>&rarr;</span>
            </router-link>
          </div>

          <!-- Trust & Value Bullets -->
          <div class="mt-8 flex flex-wrap items-center justify-center gap-4 sm:gap-8 text-xs font-bold" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
            <div class="flex items-center gap-1.5">
              <span class="text-emerald-500">✓</span>
              <span>End-to-End Privacy</span>
            </div>
            <div class="flex items-center gap-1.5">
              <span class="text-emerald-500">✓</span>
              <span>African Royal Titles & Totems</span>
            </div>
            <div class="flex items-center gap-1.5">
              <span class="text-emerald-500">✓</span>
              <span>Oral Audio Memories</span>
            </div>
            <div class="flex items-center gap-1.5">
              <span class="text-emerald-500">✓</span>
              <span>Printable Heirloom Posters</span>
            </div>
          </div>
        </div>

        <!-- ========================================================= -->
        <!-- 2. INTERACTIVE LIVE DYNASTY SHOWCASE                      -->
        <!-- ========================================================= -->
        <div class="mt-14 max-w-5xl mx-auto">
          <div
            class="rounded-3xl border-2 shadow-2xl p-6 sm:p-8 transition-colors"
            :class="isLight ? 'bg-white border-[#C5A059] shadow-amber-950/15' : 'bg-[#15171F] border-[#C5A059] shadow-black/90'"
          >
            <!-- Showcase Top Header -->
            <div class="flex flex-col sm:flex-row sm:items-center justify-between pb-6 border-b gap-4" :class="isLight ? 'border-[#C5A059]/30' : 'border-[#C5A059]/30'">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl overflow-hidden border-2 border-[#C5A059] p-0.5 bg-black flex items-center justify-center">
                  <img src="/logo.png" alt="Crest" class="w-full h-full object-contain" />
                </div>
                <div>
                  <h3 class="font-serif font-black text-base sm:text-lg uppercase tracking-wider text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059]">
                    Kkevo Dynasty • Living Lineage Explorer
                  </h3>
                  <p class="text-xs font-semibold" :class="isLight ? 'text-stone-500' : 'text-stone-400'">
                    Preview live generations from founding ancestors to living youth
                  </p>
                </div>
              </div>

              <!-- Generation Tab Switcher -->
              <div
                class="flex items-center gap-1 p-1 rounded-2xl border overflow-x-auto"
                :class="isLight ? 'bg-stone-100 border-stone-200' : 'bg-[#1C1E26] border-[#C5A059]/30'"
              >
                <button
                  v-for="(tab, idx) in generationTabs"
                  :key="tab.id"
                  @click="activeGenTab = idx"
                  class="px-3 py-1.5 rounded-xl text-xs font-black transition-all cursor-pointer whitespace-nowrap"
                  :class="activeGenTab === idx
                    ? (isLight ? 'bg-[#855B14] text-white shadow-sm' : 'bg-gradient-to-r from-[#B8860B] to-[#C5A059] text-black shadow-sm font-black')
                    : (isLight ? 'text-stone-600 hover:text-stone-900' : 'text-stone-400 hover:text-stone-200')"
                >
                  {{ tab.badge }} {{ tab.title }}
                </button>
              </div>
            </div>

            <!-- Active Generation Cards Grid -->
            <div class="py-6">
              <div class="flex items-center justify-between mb-4">
                <div>
                  <h4 class="text-lg font-black font-serif uppercase tracking-wide" :class="isLight ? 'text-stone-900' : 'text-[#F3E5AB]'">
                    {{ generationTabs[activeGenTab].heading }}
                  </h4>
                  <p class="text-xs" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
                    {{ generationTabs[activeGenTab].description }}
                  </p>
                </div>
                <span class="text-xs font-bold px-3 py-1 rounded-full border"
                  :class="isLight ? 'bg-amber-50 text-[#855B14] border-[#C5A059]/40' : 'bg-[#1E2028] text-[#F3E5AB] border-[#C5A059]/40'">
                  Gen Tier {{ generationTabs[activeGenTab].tier }}
                </span>
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                <div
                  v-for="person in generationTabs[activeGenTab].people"
                  :key="person.name"
                  class="p-4 rounded-2xl border transition-all hover:scale-102 flex flex-col justify-between"
                  :class="isLight ? 'bg-stone-50 hover:bg-amber-50/50 border-[#C5A059]/40 text-stone-900' : 'bg-[#1B1D26] hover:bg-[#222530] border-[#C5A059]/40 text-stone-100'"
                >
                  <div>
                    <div class="flex items-center justify-between mb-2">
                      <div class="w-9 h-9 rounded-xl flex items-center justify-center font-serif font-black text-xs border border-[#C5A059] shadow-sm"
                        :class="isLight ? 'bg-amber-100 text-[#734E0C]' : 'bg-[#0E0F12] text-[#F3E5AB]'">
                        {{ person.monogram }}
                      </div>
                      <span class="text-[10px] font-black px-2 py-0.5 rounded-full border"
                        :class="person.status === 'Ancestor'
                          ? (isLight ? 'bg-stone-200 text-stone-800 border-stone-300' : 'bg-stone-800 text-stone-300 border-stone-700')
                          : 'bg-[#C5A059]/20 text-[#D4AF37] border-[#C5A059]/40'">
                        {{ person.status === 'Ancestor' ? '🕊️ Ancestor' : '🌱 Living' }}
                      </span>
                    </div>

                    <h5 class="text-sm font-black truncate" :class="isLight ? 'text-stone-900' : 'text-stone-100'">
                      {{ person.name }}
                    </h5>
                    <p v-if="person.title" class="text-[11px] font-bold text-[#C5A059] mt-0.5">
                      👑 {{ person.title }}
                    </p>
                    <p class="text-[11px] opacity-70 mt-1">
                      Born {{ person.born }} {{ person.village ? `• ${person.village}` : '' }}
                    </p>
                  </div>

                  <div class="mt-3 pt-2.5 border-t flex items-center justify-between text-[11px] font-bold"
                    :class="isLight ? 'border-stone-200 text-[#855B14]' : 'border-stone-800 text-[#C5A059]'">
                    <span>{{ person.role }}</span>
                    <span>Totem: {{ person.totem }}</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Showcase Bottom Action Strip -->
            <div class="pt-5 border-t flex flex-col sm:flex-row sm:items-center justify-between gap-4" :class="isLight ? 'border-[#C5A059]/30' : 'border-[#C5A059]/30'">
              <div class="flex items-center gap-2 text-xs font-semibold" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
                <span>💡</span>
                <span>Zoom, pan, switch to Left-Right pedigree, or export printable posters in the full tree.</span>
              </div>

              <router-link
                to="/tree"
                class="px-5 py-2.5 rounded-xl font-black text-xs text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-105 shadow-md flex items-center justify-center gap-2 transition-all cursor-pointer whitespace-nowrap"
              >
                <span>Launch Full Tree Experience</span>
                <span>&rarr;</span>
              </router-link>
            </div>
          </div>
        </div>

        <!-- Quick Numerical Heritage Counters -->
        <div
          class="mt-14 grid grid-cols-2 sm:grid-cols-4 gap-4 max-w-4xl mx-auto border-t pt-8 text-center"
          :class="isLight ? 'border-[#C5A059]/30' : 'border-[#C5A059]/20'"
        >
          <div class="p-3">
            <div class="text-3xl sm:text-4xl font-black font-serif text-[#D4AF37]">4+</div>
            <div class="text-xs uppercase tracking-wider font-bold mt-1" :class="isLight ? 'text-stone-600' : 'text-stone-400'">Generations Charted</div>
          </div>
          <div class="p-3">
            <div class="text-3xl sm:text-4xl font-black font-serif text-[#D4AF37]">16+</div>
            <div class="text-xs uppercase tracking-wider font-bold mt-1" :class="isLight ? 'text-stone-600' : 'text-stone-400'">Verified Kinship Links</div>
          </div>
          <div class="p-3">
            <div class="text-3xl sm:text-4xl font-black font-serif text-[#D4AF37]">1-Click</div>
            <div class="text-xs uppercase tracking-wider font-bold mt-1" :class="isLight ? 'text-stone-600' : 'text-stone-400'">Relative Addition</div>
          </div>
          <div class="p-3">
            <div class="text-3xl sm:text-4xl font-black font-serif text-[#D4AF37]">Global</div>
            <div class="text-xs uppercase tracking-wider font-bold mt-1" :class="isLight ? 'text-stone-600' : 'text-stone-400'">Diaspora Connected</div>
          </div>
        </div>
      </div>
    </section>

    <!-- ========================================================= -->
    <!-- 3. HOW IT WORKS: 3-STEP CLEAR PATHWAY                     -->
    <!-- ========================================================= -->
    <section
      class="py-20 border-b transition-colors duration-300"
      :class="isLight ? 'bg-[#FAF7F0] border-[#C5A059]/30' : 'bg-[#101217] border-[#C5A059]/20'"
    >
      <div class="container mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center max-w-2xl mx-auto mb-16">
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-black uppercase tracking-wider border mb-3"
            :class="isLight ? 'bg-amber-100 text-[#67440B] border-[#C5A059]/40' : 'bg-[#1E2028] text-[#F3E5AB] border-[#C5A059]/40'">
            Simplicity For Elders • Intuitive For Youth
          </div>
          <h2 class="text-3xl sm:text-4xl font-serif font-black" :class="isLight ? 'text-stone-900' : 'text-stone-100'">
            How Kkevo Family Platform Works
          </h2>
          <p class="mt-3 text-sm sm:text-base leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-400'">
            Building your family archive requires no technical expertise. Follow our simple, respectful 3-step pathway.
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-5xl mx-auto">
          <!-- Step 1 -->
          <div
            class="p-8 rounded-3xl border-2 transition-all shadow-lg flex flex-col justify-between"
            :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900 shadow-amber-950/5' : 'bg-[#15171F] border-[#C5A059]/40 text-stone-100'"
          >
            <div>
              <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#B8860B] to-[#C5A059] text-black font-black text-lg flex items-center justify-center mb-6 shadow-md">
                1
              </div>
              <h3 class="text-xl font-serif font-black mb-2 text-[#B8860B]">
                Anchor Patriarch Roots
              </h3>
              <p class="text-xs sm:text-sm leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-300'">
                Start with your earliest known elders. Enter honorary titles (e.g. <em>Tadji, Fo, Ma</em>), clan totems, and ancestral villages to ground your lineage.
              </p>
            </div>
            <div class="mt-6 pt-4 border-t text-xs font-bold text-[#C5A059]" :class="isLight ? 'border-stone-200' : 'border-stone-800'">
              👑 Traditional Title Preservation
            </div>
          </div>

          <!-- Step 2 -->
          <div
            class="p-8 rounded-3xl border-2 transition-all shadow-lg flex flex-col justify-between"
            :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900 shadow-amber-950/5' : 'bg-[#15171F] border-[#C5A059]/40 text-stone-100'"
          >
            <div>
              <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#B8860B] to-[#C5A059] text-black font-black text-lg flex items-center justify-center mb-6 shadow-md">
                2
              </div>
              <h3 class="text-xl font-serif font-black mb-2 text-[#B8860B]">
                Branch Living Kinship
              </h3>
              <p class="text-xs sm:text-sm leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-300'">
                Tap any relative's card to instantly add spouses, brothers, sisters, and children. The Kinship Engine automatically calculates degrees and updates the tree.
              </p>
            </div>
            <div class="mt-6 pt-4 border-t text-xs font-bold text-[#C5A059]" :class="isLight ? 'border-stone-200' : 'border-stone-800'">
              ⚡ 1-Click Fast Connect
            </div>
          </div>

          <!-- Step 3 -->
          <div
            class="p-8 rounded-3xl border-2 transition-all shadow-lg flex flex-col justify-between"
            :class="isLight ? 'bg-white border-[#C5A059]/40 text-stone-900 shadow-amber-950/5' : 'bg-[#15171F] border-[#C5A059]/40 text-stone-100'"
          >
            <div>
              <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#B8860B] to-[#C5A059] text-black font-black text-lg flex items-center justify-center mb-6 shadow-md">
                3
              </div>
              <h3 class="text-xl font-serif font-black mb-2 text-[#B8860B]">
                Immortalize Voice & Lore
              </h3>
              <p class="text-xs sm:text-sm leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-300'">
                Record audio memories of your grandparents' voices, tag historical celebration photos, and generate high-resolution royal posters for your home.
              </p>
            </div>
            <div class="mt-6 pt-4 border-t text-xs font-bold text-[#C5A059]" :class="isLight ? 'border-stone-200' : 'border-stone-800'">
              🎙️ Spoken Oral Vault & Posters
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ========================================================= -->
    <!-- 4. CORE HERITAGE PILLARS                                  -->
    <!-- ========================================================= -->
    <section
      class="py-20 border-b transition-colors duration-300"
      :class="isLight ? 'bg-white border-[#C5A059]/30' : 'bg-[#0C0E12] border-[#C5A059]/20'"
    >
      <div class="container mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center max-w-2xl mx-auto mb-16">
          <h2 class="text-xs uppercase tracking-widest text-[#B8860B] font-black">Built For Royal Lineages</h2>
          <p class="mt-2 text-3xl sm:text-4xl font-serif font-black" :class="isLight ? 'text-stone-900' : 'text-stone-100'">
            Four Pillars of Ancestral Preservation
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 max-w-6xl mx-auto">
          <!-- Pillar 1 -->
          <div
            class="p-6 rounded-3xl border transition-all hover:-translate-y-1 shadow-md flex flex-col justify-between"
            :class="isLight ? 'bg-stone-50 border-[#C5A059]/40' : 'bg-[#15171F] border-[#C5A059]/30'"
          >
            <div>
              <div class="text-3xl mb-4">🌳</div>
              <h4 class="font-serif font-black text-lg mb-2 text-[#B8860B]">Dual-Engine Tree</h4>
              <p class="text-xs leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-300'">
                Toggle instantly between the regal Top-Down dynasty layout and the pedigree Left-Right chart with smooth vector curves.
              </p>
            </div>
            <router-link to="/tree" class="mt-4 text-xs font-black text-[#D4AF37] hover:underline flex items-center gap-1">
              <span>Open Tree</span> &rarr;
            </router-link>
          </div>

          <!-- Pillar 2 -->
          <div
            class="p-6 rounded-3xl border transition-all hover:-translate-y-1 shadow-md flex flex-col justify-between"
            :class="isLight ? 'bg-stone-50 border-[#C5A059]/40' : 'bg-[#15171F] border-[#C5A059]/30'"
          >
            <div>
              <div class="text-3xl mb-4">🔗</div>
              <h4 class="font-serif font-black text-lg mb-2 text-[#B8860B]">Kinship Calculator</h4>
              <p class="text-xs leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-300'">
                Select any two family members to calculate their exact relationship, common ancestor, and bloodline step path.
              </p>
            </div>
            <router-link to="/relationships" class="mt-4 text-xs font-black text-[#D4AF37] hover:underline flex items-center gap-1">
              <span>Calculate Kinship</span> &rarr;
            </router-link>
          </div>

          <!-- Pillar 3 -->
          <div
            class="p-6 rounded-3xl border transition-all hover:-translate-y-1 shadow-md flex flex-col justify-between"
            :class="isLight ? 'bg-stone-50 border-[#C5A059]/40' : 'bg-[#15171F] border-[#C5A059]/30'"
          >
            <div>
              <div class="text-3xl mb-4">🎙️</div>
              <h4 class="font-serif font-black text-lg mb-2 text-[#B8860B]">Voice & Oral Vault</h4>
              <p class="text-xs leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-300'">
                Preserve spoken Bamiléké dialects, oral proverbs, songs, and historical recollections directly attached to each ancestor's profile.
              </p>
            </div>
            <router-link to="/media" class="mt-4 text-xs font-black text-[#D4AF37] hover:underline flex items-center gap-1">
              <span>Explore Vault</span> &rarr;
            </router-link>
          </div>

          <!-- Pillar 4 -->
          <div
            class="p-6 rounded-3xl border transition-all hover:-translate-y-1 shadow-md flex flex-col justify-between"
            :class="isLight ? 'bg-stone-50 border-[#C5A059]/40' : 'bg-[#15171F] border-[#C5A059]/30'"
          >
            <div>
              <div class="text-3xl mb-4">📜</div>
              <h4 class="font-serif font-black text-lg mb-2 text-[#B8860B]">Poster & WhatsApp Share</h4>
              <p class="text-xs leading-relaxed" :class="isLight ? 'text-stone-600' : 'text-stone-300'">
                Export museum-quality high-resolution PNG tree posters with gold frames, or share branch previews directly with diaspora kin via WhatsApp.
              </p>
            </div>
            <router-link to="/tree" class="mt-4 text-xs font-black text-[#D4AF37] hover:underline flex items-center gap-1">
              <span>Export Posters</span> &rarr;
            </router-link>
          </div>
        </div>
      </div>
    </section>

    <!-- ========================================================= -->
    <!-- 5. ANCESTRAL CREED & PROVERB                              -->
    <!-- ========================================================= -->
    <section
      class="py-16 border-b text-center relative overflow-hidden transition-colors duration-300"
      :class="isLight ? 'bg-[#FAF6ED] border-[#C5A059]/30' : 'bg-[#13151C] border-[#C5A059]/30'"
    >
      <div class="container mx-auto px-4 max-w-3xl relative z-10">
        <span class="text-5xl text-[#C5A059]/60 font-serif block mb-2">“</span>
        <blockquote
          class="text-xl sm:text-2xl font-serif italic leading-snug"
          :class="isLight ? 'text-stone-800' : 'text-stone-200'"
        >
          A person who does not know their lineage is like a mighty tree without deep roots — it cannot withstand the storms of time.
        </blockquote>
        <p class="mt-4 text-xs font-black uppercase tracking-widest text-[#D4AF37]">
          — African Proverb • The Kkevo Family Creed
        </p>
      </div>
    </section>

    <!-- ========================================================= -->
    <!-- 6. FINAL CALL TO ACTION                                   -->
    <!-- ========================================================= -->
    <section
      class="py-20 text-center transition-colors duration-300"
      :class="[
        isLight
          ? 'bg-gradient-to-r from-[#FAF6ED] via-[#F4EDE0] to-[#FAF6ED]'
          : 'bg-gradient-to-r from-[#14161F] via-[#181A24] to-[#14161F]'
      ]"
    >
      <div class="container mx-auto px-4 max-w-2xl">
        <div
          class="w-16 h-16 mx-auto mb-6 rounded-2xl border-2 border-[#C5A059] p-2 flex items-center justify-center shadow-xl"
          :class="isLight ? 'bg-white shadow-amber-900/10' : 'bg-[#0E0F12] shadow-black/70'"
        >
          <img src="/logo.png" alt="Kkevo Crest" class="w-full h-full object-contain" />
        </div>
        <h2 class="text-3xl sm:text-4xl font-serif font-black text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059]">
          Ready to Chart Your Royal Heritage?
        </h2>
        <p class="mt-3 text-sm sm:text-base leading-relaxed" :class="isLight ? 'text-stone-700' : 'text-stone-300'">
          Begin by exploring the living tree, searching family directory profiles, or connecting relatives in 1 click.
        </p>
        <div class="mt-8 flex flex-wrap justify-center gap-4">
          <router-link
            to="/tree"
            class="px-8 py-4 rounded-2xl font-black text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-110 shadow-xl shadow-[#C5A059]/30 transition-all text-sm uppercase tracking-wide cursor-pointer active:scale-95"
          >
            Launch Interactive Tree
          </router-link>
          <router-link
            to="/relationships"
            class="px-8 py-4 rounded-2xl font-bold border-2 transition-all text-sm tracking-wide cursor-pointer active:scale-95"
            :class="isLight ? 'bg-white hover:bg-stone-50 border-[#C5A059] text-stone-800' : 'bg-[#15171F] hover:bg-[#1E202B] border-[#C5A059]/60 text-[#F3E5AB]'"
          >
            Kinship Calculator
          </router-link>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useThemeStore } from '@/stores/theme'

const authStore = useAuthStore()
const themeStore = useThemeStore()

const isAuthenticated = computed(() => authStore.isAuthenticated)
const isLight = computed(() => themeStore.isLight)

// Live Dynasty Tabbed Showcase
const activeGenTab = ref(0)

const generationTabs = [
  {
    id: 'gen1',
    tier: 1,
    badge: '👑',
    title: 'Founding Ancestors',
    heading: 'Generation 1 • Ancestral Roots & Elders',
    description: 'The venerated roots of the dynasty, honoring our great-grandparents and historical founders.',
    people: [
      {
        name: 'Kamgou Kkevo',
        title: 'Chef Kamgou',
        monogram: 'CK',
        born: '1889',
        village: 'Bafoussam',
        totem: 'Elephant',
        role: 'Dynastic Founder',
        status: 'Ancestor'
      }
    ]
  },
  {
    id: 'gen2',
    tier: 2,
    badge: '🏛️',
    title: 'Founding Patriarchs',
    heading: 'Generation 2 • Patriarchs & Matriarchs',
    description: 'Founding parents who united family branches through sacred matrimony in Bandjoun.',
    people: [
      {
        name: 'Jean Kkevo',
        title: 'Tadji Jean',
        monogram: 'TJ',
        born: '1930',
        village: 'Bafoussam',
        totem: 'Leopard',
        role: 'Grandfather / Patriarch',
        status: 'Ancestor'
      },
      {
        name: 'Amina Kkevo',
        title: 'Ma Amina',
        monogram: 'MA',
        born: '1935',
        village: 'Bandjoun',
        totem: 'Leopard',
        role: 'Grandmother / Matriarch',
        status: 'Ancestor'
      }
    ]
  },
  {
    id: 'gen3',
    tier: 3,
    badge: '🌿',
    title: 'Parents & Siblings',
    heading: 'Generation 3 • Living Parents & Spouses',
    description: 'The core family pillars guiding living descendants and maintaining oral customs.',
    people: [
      {
        name: 'Arthur Kkevo',
        title: 'Nji Arthur',
        monogram: 'NA',
        born: '1960',
        village: 'Bandjoun',
        totem: 'Leopard',
        role: 'Father / Elder Son',
        status: 'Living'
      },
      {
        name: 'Eleanor Kkevo',
        title: 'Meme Eleanor',
        monogram: 'ME',
        born: '1964',
        village: 'Douala',
        totem: 'Elephant',
        role: 'Mother / Spouse',
        status: 'Living'
      },
      {
        name: 'Chloe Kkevo',
        title: 'Magne Chloe',
        monogram: 'MC',
        born: '1962',
        village: 'Bandjoun',
        totem: 'Leopard',
        role: 'Mother / Daughter',
        status: 'Living'
      },
      {
        name: 'Robert Kkevo',
        title: 'Fo Robert',
        monogram: 'FR',
        born: '1958',
        village: 'Dschang',
        totem: 'Lion',
        role: 'Father / In-Law',
        status: 'Living'
      }
    ]
  },
  {
    id: 'gen4',
    tier: 4,
    badge: '🌱',
    title: 'Youth & Grandchildren',
    heading: 'Generation 4 • Descendants & Tomorrow',
    description: 'The growing generation carrying our traditions forward across the global diaspora.',
    people: [
      {
        name: 'Liam Kkevo',
        title: 'Kem Liam',
        monogram: 'KL',
        born: '1992',
        village: 'Douala',
        totem: 'Leopard',
        role: 'Grandson',
        status: 'Living'
      },
      {
        name: 'Grace Kkevo',
        title: 'Ngouh Grace',
        monogram: 'NG',
        born: '1996',
        village: 'Douala',
        totem: 'Leopard',
        role: 'Granddaughter',
        status: 'Living'
      },
      {
        name: 'Lucas Kkevo',
        title: 'Tchio Lucas',
        monogram: 'TL',
        born: '1990',
        village: 'Yaoundé',
        totem: 'Lion',
        role: 'Grandson',
        status: 'Living'
      },
      {
        name: 'Marie Kkevo',
        title: 'Magne Marie',
        monogram: 'MM',
        born: '1994',
        village: 'Yaoundé',
        totem: 'Lion',
        role: 'Granddaughter',
        status: 'Living'
      }
    ]
  }
]
</script>