<template>
  <div class="app-page-shell py-8 px-4 sm:px-6 lg:px-8 font-sans transition-colors duration-300">
    <div class="max-w-3xl mx-auto">
      <!-- Header -->
      <div class="mb-8 text-center">
        <div class="w-14 h-14 mx-auto mb-3 rounded-2xl border-2 border-[#C5A059] p-1 flex items-center justify-center shadow-lg bg-amber-50/20">
          <img src="/logo.png" alt="Kkevo Crest" class="w-full h-full object-contain" />
        </div>
        <h1 class="text-3xl font-serif font-black tracking-wider uppercase text-transparent bg-clip-text bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059]">
          Contact Family Council
        </h1>
        <p class="text-xs opacity-70 mt-1">
          Have an inquiry, ancestral lineage dispute, or need help mapping your branch?
        </p>
      </div>

      <!-- Main Form -->
      <div class="app-card-panel rounded-3xl border-2 border-[#C5A059] p-6 sm:p-8 shadow-2xl space-y-6">
        <form @submit.prevent="handleSubmit" class="space-y-5">
          <div>
            <label class="block text-xs font-bold uppercase tracking-wider text-[#C5A059] mb-1.5">
              Subject of Inquiry
            </label>
            <select
              v-model="form.subject"
              required
              class="w-full px-4 py-3 app-input-theme border rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-[#D4AF37]"
            >
              <option value="">Select an inquiry topic</option>
              <option value="lineage">Historical Lineage or Ancestor Record Correction</option>
              <option value="branch">Adding a New Major Clan Branch</option>
              <option value="media">Archiving Rare Photos or Oral Tapes</option>
              <option value="access">Account or Login Verification</option>
              <option value="other">General Family Inquiries</option>
            </select>
          </div>

          <div>
            <label class="block text-xs font-bold uppercase tracking-wider text-[#C5A059] mb-1.5">
              Your Name & Branch / Village
            </label>
            <input
              v-model="form.name"
              type="text"
              placeholder="e.g. Luc Kouekam (Bafoussam branch)"
              required
              class="w-full px-4 py-3 app-input-theme border rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-[#D4AF37]"
            />
          </div>

          <div>
            <label class="block text-xs font-bold uppercase tracking-wider text-[#C5A059] mb-1.5">
              Email or WhatsApp Contact
            </label>
            <input
              v-model="form.contact"
              type="text"
              placeholder="you@email.com or +237..."
              required
              class="w-full px-4 py-3 app-input-theme border rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-[#D4AF37]"
            />
          </div>

          <div>
            <label class="block text-xs font-bold uppercase tracking-wider text-[#C5A059] mb-1.5">
              Message or Historical Details
            </label>
            <textarea
              v-model="form.message"
              rows="4"
              required
              placeholder="Describe your inquiry, relationship to elders, or details needed..."
              class="w-full px-4 py-3 app-input-theme border rounded-xl text-sm focus:outline-none focus:ring-1 focus:ring-[#D4AF37]"
            ></textarea>
          </div>

          <div class="flex items-center justify-between pt-2">
            <router-link to="/help" class="text-xs font-bold text-stone-400 hover:text-stone-200">
              &larr; Back to Help Center
            </router-link>

            <button
              type="submit"
              :disabled="submitted"
              class="px-8 py-3.5 rounded-xl font-black text-xs uppercase tracking-wider text-black bg-gradient-to-r from-[#B8860B] via-[#D4AF37] to-[#C5A059] hover:brightness-110 shadow-lg shadow-[#C5A059]/30 transition-all"
            >
              {{ submitted ? 'Message Sent!' : 'Submit to Council' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const submitted = ref(false)

const form = ref({
  subject: '',
  name: '',
  contact: '',
  message: ''
})

const handleSubmit = () => {
  submitted.value = true
  alert('Thank you! Your message has been received by the Kkevo Family Lineage Council.')
  setTimeout(() => {
    router.push('/help')
  }, 1200)
}
</script>