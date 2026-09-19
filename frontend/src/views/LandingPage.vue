<template>
  <div class="min-h-screen bg-gradient-to-b from-primary-50 to-white">
    <header class="container mx-auto px-4 py-6">
      <nav class="flex justify-between items-center">
        <div class="text-2xl font-bold text-primary-600">Family Tree</div>
        <div class="space-x-4">
          <router-link to="/login" class="btn btn-secondary">Login</router-link>
          <router-link to="/register" class="btn btn-primary">Register</router-link>
        </div>
      </nav>
    </header>

    <main class="container mx-auto px-4 py-12">
      <div class="max-w-4xl mx-auto text-center">
        <h1 class="text-5xl font-bold text-gray-900 mb-6">
          Preserve Your Family History
        </h1>
        <p class="text-xl text-gray-600 mb-8">
          Create, manage, and share your family tree with ease. Connect generations and preserve memories for years to come.
        </p>
        <div class="space-x-4">
          <router-link to="/register" class="btn btn-primary text-lg px-8 py-3">
            Get Started
          </router-link>
          <a href="#features" class="btn btn-secondary text-lg px-8 py-3">
            Learn More
          </a>
        </div>
      </div>

      <div id="features" class="mt-24 grid md:grid-cols-3 gap-8">
        <div class="card">
          <div class="text-primary-600 mb-4">
            <svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
          </div>
          <h3 class="text-xl font-semibold mb-2">Family Connections</h3>
          <p class="text-gray-600">
            Easily add and manage family members, relationships, and connections in your family tree.
          </p>
        </div>

        <div class="card">
          <div class="text-primary-600 mb-4">
            <svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </div>
          <h3 class="text-xl font-semibold mb-2">Media Gallery</h3>
          <p class="text-gray-600">
            Upload and organize photos, documents, and other media to preserve family memories.
          </p>
        </div>

        <div class="card">
          <div class="text-primary-600 mb-4">
            <svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </div>
          <h3 class="text-xl font-semibold mb-2">Timeline Events</h3>
          <p class="text-gray-600">
            Record and share important family events, milestones, and stories through time.
          </p>
        </div>
      </div>
    </main>

    <footer class="bg-gray-50 mt-24 py-12">
      <div class="container mx-auto px-4">
        <div class="grid md:grid-cols-4 gap-8">
          <div>
            <h4 class="text-lg font-semibold mb-4">Family Tree</h4>
            <p class="text-gray-600">
              Preserve your family history and create lasting connections.
            </p>
          </div>
          <div>
            <h4 class="text-lg font-semibold mb-4">Features</h4>
            <ul class="space-y-2 text-gray-600">
              <li>Family Tree Builder</li>
              <li>Media Gallery</li>
              <li>Timeline Events</li>
              <li>Family Stories</li>
            </ul>
          </div>
          <div>
            <h4 class="text-lg font-semibold mb-4">Resources</h4>
            <ul class="space-y-2 text-gray-600">
              <li>Help Center</li>
              <li>Privacy Policy</li>
              <li>Terms of Service</li>
              <li>Contact Us</li>
            </ul>
          </div>
          <div>
            <h4 class="text-lg font-semibold mb-4">Connect</h4>
            <div class="flex space-x-4">
              <a href="#" class="text-gray-600 hover:text-primary-600">
                <span class="sr-only">Facebook</span>
                <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.988C18.343 21.128 22 16.991 22 12z" />
                </svg>
              </a>
              <a href="#" class="text-gray-600 hover:text-primary-600">
                <span class="sr-only">Twitter</span>
                <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84" />
                </svg>
              </a>
            </div>
          </div>
        </div>
        <div class="mt-8 pt-8 border-t border-gray-200 text-center text-gray-600">
          <p>&copy; 2024 Family Tree. All rights reserved.</p>
        </div>
      </div>
    </footer>
  </div>
</template>

<script setup>
// No additional setup needed for landing page
</script> 