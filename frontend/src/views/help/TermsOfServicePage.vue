<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          Terms of Service
        </h1>
        <p class="mt-4 text-lg text-gray-500">
          Last updated: {{ lastUpdated }}
        </p>
      </div>

      <!-- Table of Contents -->
      <div class="bg-white rounded-lg shadow-lg p-6 mb-8">
        <h2 class="text-xl font-bold text-gray-900 mb-4">Table of Contents</h2>
        <nav class="space-y-2">
          <a
            v-for="section in sections"
            :key="section.id"
            :href="`#${section.id}`"
            class="block text-indigo-600 hover:text-indigo-800"
          >
            {{ section.title }}
          </a>
        </nav>
      </div>

      <!-- Terms Content -->
      <div class="bg-white rounded-lg shadow-lg p-6 space-y-8">
        <!-- Introduction -->
        <section :id="sections[0].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[0].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              Welcome to FamilyTree. By accessing or using our service, you agree to be bound by these Terms of Service
              and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited
              from using or accessing this site.
            </p>
          </div>
        </section>

        <!-- Account Terms -->
        <section :id="sections[1].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[1].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              To use our service, you must:
            </p>
            <ul>
              <li>Be at least 13 years old</li>
              <li>Register with accurate and complete information</li>
              <li>Maintain the security of your account credentials</li>
              <li>Notify us immediately of any unauthorized access</li>
            </ul>
            <p>
              We reserve the right to suspend or terminate accounts that violate these terms or engage in fraudulent
              activity.
            </p>
          </div>
        </section>

        <!-- User Content -->
        <section :id="sections[2].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[2].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              You retain ownership of the content you upload to FamilyTree. However, by uploading content, you grant us
              a worldwide, non-exclusive license to:
            </p>
            <ul>
              <li>Store and display your content on our platform</li>
              <li>Use your content to provide and improve our services</li>
              <li>Share your content with other users according to your privacy settings</li>
            </ul>
            <p>
              You are responsible for ensuring you have the right to share any content you upload.
            </p>
          </div>
        </section>

        <!-- Privacy -->
        <section :id="sections[3].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[3].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              We take your privacy seriously. Our Privacy Policy explains how we collect, use, and protect your personal
              information. By using our service, you agree to our data practices as described in the Privacy Policy.
            </p>
          </div>
        </section>

        <!-- Prohibited Activities -->
        <section :id="sections[4].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[4].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              You agree not to:
            </p>
            <ul>
              <li>Upload content that violates any laws or third-party rights</li>
              <li>Use our service for any illegal or unauthorized purpose</li>
              <li>Attempt to gain unauthorized access to our systems</li>
              <li>Interfere with the proper functioning of our service</li>
              <li>Harass, abuse, or harm others</li>
              <li>Share false or misleading information</li>
            </ul>
          </div>
        </section>

        <!-- Intellectual Property -->
        <section :id="sections[5].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[5].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              Our service and its original content, features, and functionality are owned by FamilyTree and are
              protected by international copyright, trademark, and other intellectual property laws.
            </p>
          </div>
        </section>

        <!-- Limitation of Liability -->
        <section :id="sections[6].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[6].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              FamilyTree shall not be liable for any indirect, incidental, special, consequential, or punitive damages
              resulting from your use of or inability to use the service.
            </p>
          </div>
        </section>

        <!-- Changes to Terms -->
        <section :id="sections[7].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[7].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              We reserve the right to modify these terms at any time. We will notify users of any material changes via
              email or through our service. Your continued use of the service after such modifications constitutes your
              acceptance of the new terms.
            </p>
          </div>
        </section>

        <!-- Contact Information -->
        <section :id="sections[8].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[8].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              If you have any questions about these Terms of Service, please contact us at:
            </p>
            <p>
              Email: legal@familytree.com<br>
              Address: 123 Family Tree Street, Genealogy City, GC 12345
            </p>
          </div>
        </section>
      </div>

      <!-- Acceptance -->
      <div class="mt-8 text-center">
        <p class="text-gray-600">
          By using our service, you acknowledge that you have read and agree to these Terms of Service.
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const lastUpdated = ref('March 15, 2024')

const sections = [
  {
    id: 'introduction',
    title: 'Introduction'
  },
  {
    id: 'account-terms',
    title: 'Account Terms'
  },
  {
    id: 'user-content',
    title: 'User Content'
  },
  {
    id: 'privacy',
    title: 'Privacy'
  },
  {
    id: 'prohibited-activities',
    title: 'Prohibited Activities'
  },
  {
    id: 'intellectual-property',
    title: 'Intellectual Property'
  },
  {
    id: 'limitation-of-liability',
    title: 'Limitation of Liability'
  },
  {
    id: 'changes-to-terms',
    title: 'Changes to Terms'
  },
  {
    id: 'contact-information',
    title: 'Contact Information'
  }
]
</script> 