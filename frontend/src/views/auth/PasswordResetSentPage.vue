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
          Check your email
        </h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          We've sent you an email with instructions to reset your password.
          Please check your inbox and follow the link to continue.
        </p>
      </div>

      <div class="text-center">
        <router-link
          to="/login"
          class="font-medium text-indigo-600 hover:text-indigo-500"
        >
          Return to login
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
// No additional logic needed for this confirmation page
</script> 