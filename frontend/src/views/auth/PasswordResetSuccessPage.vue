<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <div>
        <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-green-100">
          <svg
            class="h-6 w-6 text-green-600"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M5 13l4 4L19 7"
            />
          </svg>
        </div>
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Password reset successful
        </h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          Your password has been successfully reset. You can now log in with your new password.
        </p>
      </div>

      <div class="text-center">
        <router-link
          to="/login"
          class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          Go to login
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
// No additional logic needed for this confirmation page
</script> 