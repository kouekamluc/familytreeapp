<template>
  <div class="app-page-shell py-8 px-4 sm:px-6 lg:px-8 font-sans transition-colors duration-300">
    <div class="max-w-4xl mx-auto">
      <!-- Royal Header -->
      <div class="mb-8 text-center">
        <div class="w-14 h-14 mx-auto mb-3 rounded-2xl border-2 border-[#C5A059] p-1 flex items-center justify-center shadow-lg bg-amber-50/20">
          <img src="/logo.png" alt="Kkevo Crest" class="w-full h-full object-contain" />
        </div>
        <h1 class="text-3xl font-serif font-black tracking-wider uppercase text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059]">
          Privacy Policy & Lineage Protection
        </h1>
        <p class="text-xs opacity-70 mt-1">
          Safeguarding Family Data Across Generations
        </p>
      </div>

      <!-- Main Document Card -->
      <div class="app-card-panel rounded-3xl border-2 border-[#C5A059] p-6 sm:p-10 shadow-2xl space-y-8 text-sm leading-relaxed">
        <section>
          <h2 class="text-lg font-serif font-bold text-[#B8860B] mb-2">1. Dedicated Family Data Sovereignty</h2>
          <p class="opacity-80">
            Your family genealogical information, birth records, village connections, and oral testimonies belong exclusively to the Kkevo family network. We do NOT sell, monetize, or transfer your lineage data to third-party advertisers or data brokers.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-serif font-bold text-[#B8860B] mb-2">2. Visibility Options & Controls</h2>
          <p class="opacity-80">
            Every family member can configure their profile visibility inside the Settings tab. You may choose between Verified Family Members Only, Private, or Public Heritage Archive.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-serif font-bold text-[#B8860B] mb-2">3. Living Persons vs Ancestral Figures</h2>
          <p class="opacity-80">
            To protect living relatives, detailed contact information (emails, phones) is kept private to immediate kin, while ancestral historical dates remain accessible to all descendants to maintain tree integrity.
          </p>
        </section>

        <section>
          <h2 class="text-lg font-serif font-bold text-[#B8860B] mb-2">4. Data Security</h2>
          <p class="opacity-80">
            All network communication is encrypted, and user passwords are protected with secure cryptographic hashing.
          </p>
        </section>

        <div class="pt-6 border-t border-[#C5A059]/20 flex items-center justify-between">
          <router-link to="/register" class="text-xs font-bold text-[#D4AF37] hover:underline">
            &larr; Return to Registration
          </router-link>
          <router-link to="/settings" class="px-5 py-2.5 rounded-xl font-bold text-xs text-[#F3E5AB] bg-[#1F2128] border border-[#C5A059]/50 hover:bg-[#282B33]">
            Manage Privacy in Settings
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
</script>