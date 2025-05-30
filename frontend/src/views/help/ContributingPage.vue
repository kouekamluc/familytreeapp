<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          Contributing to Family Tree
        </h1>
        <p class="mt-4 text-lg text-gray-500">
          Help us make the family tree experience better for everyone
        </p>
      </div>

      <!-- Quick Links -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-12">
        <a
          v-for="link in quickLinks"
          :key="link.title"
          :href="link.href"
          class="block p-6 bg-white rounded-lg shadow-lg hover:shadow-xl transition-shadow duration-200"
        >
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <component
                :is="link.icon"
                class="h-8 w-8 text-indigo-600"
                aria-hidden="true"
              />
            </div>
            <div class="ml-4">
              <h3 class="text-lg font-medium text-gray-900">{{ link.title }}</h3>
              <p class="mt-1 text-sm text-gray-500">{{ link.description }}</p>
            </div>
          </div>
        </a>
      </div>

      <!-- Main Content -->
      <div class="bg-white rounded-lg shadow-lg p-6 space-y-8">
        <!-- How to Contribute -->
        <section>
          <h2 class="text-2xl font-bold text-gray-900 mb-4">How to Contribute</h2>
          <div class="prose prose-indigo max-w-none">
            <h3>Ways to Contribute</h3>
            <ul>
              <li>
                <strong>Share Your Family History</strong>
                <p>Add your family stories, photos, and documents to help preserve your heritage.</p>
              </li>
              <li>
                <strong>Help Others</strong>
                <p>Answer questions in the community forum and help other users with their research.</p>
              </li>
              <li>
                <strong>Report Issues</strong>
                <p>Help us improve by reporting bugs or suggesting new features.</p>
              </li>
              <li>
                <strong>Improve Documentation</strong>
                <p>Help make our guides and documentation better for everyone.</p>
              </li>
            </ul>
          </div>
        </section>

        <!-- Guidelines -->
        <section>
          <h2 class="text-2xl font-bold text-gray-900 mb-4">Contribution Guidelines</h2>
          <div class="prose prose-indigo max-w-none">
            <h3>Code of Conduct</h3>
            <p>We expect all contributors to:</p>
            <ul>
              <li>Be respectful and inclusive</li>
              <li>Help create a welcoming environment</li>
              <li>Be patient with new users</li>
              <li>Respect privacy and confidentiality</li>
            </ul>

            <h3>Content Guidelines</h3>
            <ul>
              <li>Ensure all information is accurate and verifiable</li>
              <li>Respect copyright and intellectual property rights</li>
              <li>Use appropriate language and tone</li>
              <li>Cite sources when possible</li>
            </ul>
          </div>
        </section>

        <!-- Getting Started -->
        <section>
          <h2 class="text-2xl font-bold text-gray-900 mb-4">Getting Started</h2>
          <div class="prose prose-indigo max-w-none">
            <h3>First Steps</h3>
            <ol>
              <li>Join our community forum</li>
              <li>Introduce yourself</li>
              <li>Read the documentation</li>
              <li>Start with small contributions</li>
            </ol>

            <h3>Resources</h3>
            <ul>
              <li>User Guide</li>
              <li>FAQ Section</li>
              <li>Video Tutorials</li>
              <li>Community Guidelines</li>
            </ul>
          </div>
        </section>

        <!-- Recognition -->
        <section>
          <h2 class="text-2xl font-bold text-gray-900 mb-4">Recognition</h2>
          <div class="prose prose-indigo max-w-none">
            <h3>Contributor Benefits</h3>
            <ul>
              <li>Recognition in our contributor hall of fame</li>
              <li>Early access to new features</li>
              <li>Special badges and achievements</li>
              <li>Opportunity to shape the future of the platform</li>
            </ul>

            <h3>Contributor Levels</h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
              <div
                v-for="level in contributorLevels"
                :key="level.name"
                class="p-4 border rounded-lg"
              >
                <h4 class="font-bold text-lg">{{ level.name }}</h4>
                <p class="text-sm text-gray-600">{{ level.description }}</p>
                <ul class="mt-2 text-sm">
                  <li v-for="benefit in level.benefits" :key="benefit">
                    {{ benefit }}
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </section>

        <!-- Contact -->
        <section>
          <h2 class="text-2xl font-bold text-gray-900 mb-4">Get in Touch</h2>
          <div class="prose prose-indigo max-w-none">
            <p>Have questions about contributing? We'd love to hear from you!</p>
            <div class="mt-4 space-y-4">
              <a
                href="#"
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
              >
                Join the Community Forum
              </a>
              <a
                href="#"
                class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 ml-4"
              >
                Contact the Team
              </a>
            </div>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const quickLinks = [
  {
    title: 'Community Forum',
    description: 'Join discussions and help other users',
    href: '#',
    icon: 'ChatBubbleLeftRightIcon'
  },
  {
    title: 'Documentation',
    description: 'Learn how to contribute effectively',
    href: '#',
    icon: 'BookOpenIcon'
  },
  {
    title: 'Issue Tracker',
    description: 'Report bugs and suggest features',
    href: '#',
    icon: 'BugAntIcon'
  },
  {
    title: 'Contributor Guide',
    description: 'Detailed guidelines for contributors',
    href: '#',
    icon: 'UserGroupIcon'
  }
]

const contributorLevels = [
  {
    name: 'Bronze',
    description: 'New contributors',
    benefits: [
      'Basic contributor badge',
      'Access to community forum',
      'Ability to report issues'
    ]
  },
  {
    name: 'Silver',
    description: 'Active contributors',
    benefits: [
      'Enhanced contributor badge',
      'Early feature access',
      'Priority support'
    ]
  },
  {
    name: 'Gold',
    description: 'Top contributors',
    benefits: [
      'Premium contributor badge',
      'Beta feature access',
      'Direct team communication'
    ]
  }
]
</script> 