<template>
  <div class="app-page-shell py-8 px-4 sm:px-6 lg:px-8 font-sans transition-colors duration-300">
    <div class="max-w-4xl mx-auto">
      <!-- Royal Header -->
      <div class="mb-8 text-center">
        <div class="w-14 h-14 mx-auto mb-3 rounded-2xl border-2 border-[#C5A059] p-1 flex items-center justify-center shadow-lg bg-amber-50/20">
          <img src="/logo.png" alt="Kkevo Crest" class="w-full h-full object-contain" />
        </div>
        <h1 class="text-3xl font-serif font-black tracking-wider uppercase text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059]">
          Terms of Service & Family Covenant
        </h1>
        <p class="text-xs opacity-70 mt-1">
          Last updated: January 2026 • Governed by Kkevo Family Heritage Trust
        </p>
      </div>

      <!-- Main Document Card -->
      <div class="app-card-panel rounded-3xl border-2 border-[#C5A059] p-6 sm:p-10 shadow-2xl space-y-8 text-sm leading-relaxed">
        <section>
          <h2 class="text-lg font-serif font-bold text-[#B8860B] mb-2">1. Sacred Preservation of Lineage</h2>
          <p class="opacity-80">
            The Kkevo Family application is created to honor ancestors, preserve royal lineage, and unite descendants. All information recorded within this platform must be contributed in good faith, respecting family members living and deceased.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-serif font-bold text-[#B8860B] mb-2">2. Account Responsibility & Integrity</h2>
          <p class="opacity-80">
            Users agree to provide accurate kinship connections when adding parents, partners, or children. Elders and administrators reserve the prerogative to verify and clarify historical dates and genealogical claims.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-serif font-bold text-[#B8860B] mb-2">3. Cultural Media & Sacred Content</h2>
          <p class="opacity-80">
            Photographs, audio recordings of oral histories, and ceremony transcripts uploaded to the Photos & Stories Vault remain the communal heritage of the Kkevo family branches. They shall not be used for malicious purposes or distributed without consent.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-serif font-bold text-[#B8860B] mb-2">4. Mutual Respect & Peace</h2>
          <p class="opacity-80">
            The application serves as a bridge of unity across the diaspora. Content promoting disputes, division, or defamation will be moderated by the clan lineage council.
          </p>
        </section>

        <div class="pt-6 border-t border-[#C5A059]/20 flex items-center justify-between">
          <router-link to="/register" class="text-xs font-bold text-[#D4AF37] hover:underline">
            &larr; Return to Registration
          </router-link>
          <router-link to="/tree" class="px-5 py-2.5 rounded-xl font-bold text-xs text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] shadow-md">
            Explore Family Tree
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
</script>