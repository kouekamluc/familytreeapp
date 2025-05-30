<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          Privacy Policy
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

      <!-- Policy Content -->
      <div class="bg-white rounded-lg shadow-lg p-6 space-y-8">
        <!-- Introduction -->
        <section :id="sections[0].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[0].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              At FamilyTree, we take your privacy seriously. This Privacy Policy explains how we collect, use, disclose,
              and safeguard your information when you use our family tree platform. Please read this privacy policy
              carefully. If you do not agree with the terms of this privacy policy, please do not access the site.
            </p>
          </div>
        </section>

        <!-- Information We Collect -->
        <section :id="sections[1].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[1].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <h3>Personal Information</h3>
            <p>We may collect personal information that you voluntarily provide to us when you:</p>
            <ul>
              <li>Register for an account</li>
              <li>Create or edit family tree information</li>
              <li>Upload photos and documents</li>
              <li>Contact our support team</li>
              <li>Subscribe to our newsletter</li>
            </ul>

            <h3>Family Tree Information</h3>
            <p>This includes:</p>
            <ul>
              <li>Names and relationships of family members</li>
              <li>Birth, marriage, and death dates</li>
              <li>Biographical information</li>
              <li>Photos and documents</li>
              <li>Location information</li>
            </ul>

            <h3>Automatically Collected Information</h3>
            <p>When you access our service, we may automatically collect:</p>
            <ul>
              <li>Device information</li>
              <li>IP address</li>
              <li>Browser type</li>
              <li>Usage patterns</li>
              <li>Cookies and similar technologies</li>
            </ul>
          </div>
        </section>

        <!-- How We Use Your Information -->
        <section :id="sections[2].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[2].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>We use the information we collect to:</p>
            <ul>
              <li>Provide and maintain our service</li>
              <li>Process your transactions</li>
              <li>Send you technical notices and support messages</li>
              <li>Communicate with you about products, services, and events</li>
              <li>Improve our service and develop new features</li>
              <li>Protect against fraud and unauthorized access</li>
              <li>Comply with legal obligations</li>
            </ul>
          </div>
        </section>

        <!-- Information Sharing -->
        <section :id="sections[3].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[3].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>We may share your information with:</p>
            <ul>
              <li>Other users according to your privacy settings</li>
              <li>Service providers who assist in our operations</li>
              <li>Legal authorities when required by law</li>
              <li>Business partners with your consent</li>
            </ul>
            <p>
              We do not sell your personal information to third parties.
            </p>
          </div>
        </section>

        <!-- Data Security -->
        <section :id="sections[4].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[4].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              We implement appropriate technical and organizational measures to protect your personal information,
              including:
            </p>
            <ul>
              <li>Encryption of data in transit and at rest</li>
              <li>Regular security assessments</li>
              <li>Access controls and authentication</li>
              <li>Secure data storage and backup</li>
            </ul>
          </div>
        </section>

        <!-- Your Rights -->
        <section :id="sections[5].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[5].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>You have the right to:</p>
            <ul>
              <li>Access your personal information</li>
              <li>Correct inaccurate data</li>
              <li>Request deletion of your data</li>
              <li>Object to processing of your data</li>
              <li>Data portability</li>
              <li>Withdraw consent</li>
            </ul>
          </div>
        </section>

        <!-- Children's Privacy -->
        <section :id="sections[6].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[6].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              Our service is not intended for children under 13. We do not knowingly collect personal information from
              children under 13. If you are a parent or guardian and believe your child has provided us with personal
              information, please contact us.
            </p>
          </div>
        </section>

        <!-- Changes to Privacy Policy -->
        <section :id="sections[7].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[7].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              We may update this privacy policy from time to time. We will notify you of any changes by posting the new
              privacy policy on this page and updating the "Last updated" date.
            </p>
          </div>
        </section>

        <!-- Contact Us -->
        <section :id="sections[8].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[8].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <p>
              If you have questions about this Privacy Policy, please contact us at:
            </p>
            <p>
              Email: privacy@familytree.com<br>
              Address: 123 Family Tree Street, Genealogy City, GC 12345
            </p>
          </div>
        </section>
      </div>

      <!-- Acceptance -->
      <div class="mt-8 text-center">
        <p class="text-gray-600">
          By using our service, you acknowledge that you have read and understand this Privacy Policy.
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
    id: 'information-collection',
    title: 'Information We Collect'
  },
  {
    id: 'information-usage',
    title: 'How We Use Your Information'
  },
  {
    id: 'information-sharing',
    title: 'Information Sharing'
  },
  {
    id: 'data-security',
    title: 'Data Security'
  },
  {
    id: 'your-rights',
    title: 'Your Rights'
  },
  {
    id: 'children-privacy',
    title: 'Children\'s Privacy'
  },
  {
    id: 'policy-changes',
    title: 'Changes to Privacy Policy'
  },
  {
    id: 'contact-us',
    title: 'Contact Us'
  }
]
</script> 