<template>
  <div class="min-h-screen bg-[#0E0F12] text-stone-100 flex flex-col justify-center py-12 px-4 sm:px-6 lg:px-8 font-sans selection:bg-[#C5A059] selection:text-black">
    <div class="sm:mx-auto sm:w-full sm:max-w-md text-center">
      <div class="relative w-20 h-20 mx-auto mb-4 rounded-2xl overflow-hidden border-2 border-[#C5A059] shadow-2xl shadow-black/80 bg-[#0B0C0E] flex items-center justify-center p-1">
        <img
          src="/logo.png"
          alt="KKEVO FAMILY Crest"
          class="w-full h-full object-contain"
        />
      </div>

      <div class="bg-[#16181F] py-8 px-6 sm:px-10 rounded-2xl border border-[#C5A059]/40 shadow-2xl shadow-black/80">
        <div class="w-14 h-14 mx-auto rounded-full bg-[#D4AF37]/20 border border-[#D4AF37] flex items-center justify-center text-2xl mb-4">
          ✉️
        </div>

        <h2 class="text-2xl font-serif font-black tracking-wider uppercase text-transparent bg-clip-text bg-gradient-to-r from-[#F3E5AB] via-[#D4AF37] to-[#C5A059]">
          Check Your Inbox
        </h2>
        <p class="mt-3 text-sm text-stone-300 leading-relaxed">
          We have dispatched an email containing instructions and a secure link to reset your family password.
        </p>

        <div class="mt-8">
          <router-link
            to="/login"
            class="w-full inline-flex justify-center items-center py-3 px-4 rounded-xl shadow-md font-bold text-sm text-[#F3E5AB] bg-[#1F2128] hover:bg-[#282B33] border border-[#C5A059]/50 transition-all"
          >
            Return to Family Sign In
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
</script>