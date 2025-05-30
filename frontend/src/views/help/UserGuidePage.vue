<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          User Guide
        </h1>
        <p class="mt-4 text-lg text-gray-500">
          Learn how to make the most of your family tree
        </p>
      </div>

      <!-- Search -->
      <div class="max-w-2xl mx-auto mb-12">
        <div class="relative">
          <input
            type="text"
            v-model="searchQuery"
            placeholder="Search the guide..."
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
          />
          <div class="absolute inset-y-0 right-0 flex items-center pr-3">
            <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
        </div>
      </div>

      <!-- Table of Contents -->
      <div class="bg-white rounded-lg shadow-lg p-6 mb-8">
        <h2 class="text-xl font-bold text-gray-900 mb-4">Table of Contents</h2>
        <nav class="space-y-2">
          <a
            v-for="section in filteredSections"
            :key="section.id"
            :href="`#${section.id}`"
            class="block text-indigo-600 hover:text-indigo-800"
          >
            {{ section.title }}
          </a>
        </nav>
      </div>

      <!-- Guide Content -->
      <div class="bg-white rounded-lg shadow-lg p-6 space-y-8">
        <!-- Getting Started -->
        <section :id="sections[0].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[0].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <h3>Creating Your First Tree</h3>
            <ol>
              <li>Click the "Create New Tree" button on your dashboard</li>
              <li>Enter a name for your family tree</li>
              <li>Add yourself as the first person</li>
              <li>Start adding family members</li>
            </ol>

            <h3>Basic Navigation</h3>
            <ul>
              <li>Use the sidebar to access different sections</li>
              <li>Click on a person to view their profile</li>
              <li>Use the search bar to find people quickly</li>
              <li>Access settings through the gear icon</li>
            </ul>
          </div>
        </section>

        <!-- Adding People -->
        <section :id="sections[1].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[1].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <h3>Adding a New Person</h3>
            <ol>
              <li>Click the "Add Person" button</li>
              <li>Fill in the basic information:
                <ul>
                  <li>First and last name</li>
                  <li>Birth date and place</li>
                  <li>Gender</li>
                  <li>Biography (optional)</li>
                </ul>
              </li>
              <li>Add relationships to existing family members</li>
              <li>Upload photos and documents</li>
            </ol>

            <h3>Editing Person Information</h3>
            <ul>
              <li>Click the edit button on a person's profile</li>
              <li>Update any information as needed</li>
              <li>Add or modify relationships</li>
              <li>Save your changes</li>
            </ul>
          </div>
        </section>

        <!-- Managing Relationships -->
        <section :id="sections[2].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[2].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <h3>Adding Relationships</h3>
            <ol>
              <li>Go to a person's profile</li>
              <li>Click "Add Relationship"</li>
              <li>Select the relationship type:
                <ul>
                  <li>Parent</li>
                  <li>Child</li>
                  <li>Spouse</li>
                  <li>Sibling</li>
                </ul>
              </li>
              <li>Select or add the related person</li>
            </ol>

            <h3>Managing Complex Relationships</h3>
            <ul>
              <li>Add multiple marriages</li>
              <li>Handle adoptions and step-relationships</li>
              <li>Add custom relationship types</li>
              <li>Document relationship dates</li>
            </ul>
          </div>
        </section>

        <!-- Media Management -->
        <section :id="sections[3].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[3].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <h3>Uploading Media</h3>
            <ol>
              <li>Go to the Media section</li>
              <li>Click "Upload Media"</li>
              <li>Select files or drag and drop</li>
              <li>Add descriptions and tags</li>
              <li>Link to people in your tree</li>
            </ol>

            <h3>Organizing Media</h3>
            <ul>
              <li>Create albums for different events or families</li>
              <li>Add tags for easy searching</li>
              <li>Set privacy levels for each item</li>
              <li>Download or share media with family</li>
            </ul>
          </div>
        </section>

        <!-- Privacy Settings -->
        <section :id="sections[4].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[4].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <h3>Tree Privacy</h3>
            <ul>
              <li>Set overall tree visibility</li>
              <li>Control who can view and edit</li>
              <li>Manage member permissions</li>
              <li>Set privacy for living people</li>
            </ul>

            <h3>Person Privacy</h3>
            <ul>
              <li>Hide sensitive information</li>
              <li>Restrict access to specific people</li>
              <li>Set privacy for photos and documents</li>
              <li>Manage public profiles</li>
            </ul>
          </div>
        </section>

        <!-- Collaboration -->
        <section :id="sections[5].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[5].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <h3>Inviting Family Members</h3>
            <ol>
              <li>Go to Tree Settings</li>
              <li>Click "Invite Members"</li>
              <li>Enter email addresses</li>
              <li>Set permission levels</li>
              <li>Send invitations</li>
            </ol>

            <h3>Working Together</h3>
            <ul>
              <li>Assign roles to members</li>
              <li>Track changes and contributions</li>
              <li>Communicate through comments</li>
              <li>Resolve conflicts</li>
            </ul>
          </div>
        </section>

        <!-- Advanced Features -->
        <section :id="sections[6].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[6].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <h3>Import/Export</h3>
            <ul>
              <li>Import from GEDCOM files</li>
              <li>Export your tree data</li>
              <li>Backup your information</li>
              <li>Transfer between accounts</li>
            </ul>

            <h3>Research Tools</h3>
            <ul>
              <li>Search historical records</li>
              <li>Find potential matches</li>
              <li>Access genealogy databases</li>
              <li>Generate research reports</li>
            </ul>
          </div>
        </section>

        <!-- Troubleshooting -->
        <section :id="sections[7].id">
          <h2 class="text-2xl font-bold text-gray-900 mb-4">{{ sections[7].title }}</h2>
          <div class="prose prose-indigo max-w-none">
            <h3>Common Issues</h3>
            <ul>
              <li>Account access problems</li>
              <li>Upload failures</li>
              <li>Relationship errors</li>
              <li>Privacy concerns</li>
            </ul>

            <h3>Getting Help</h3>
            <ul>
              <li>Check the FAQ section</li>
              <li>Contact support</li>
              <li>Join the community forum</li>
              <li>Watch tutorial videos</li>
            </ul>
          </div>
        </section>
      </div>

      <!-- Feedback -->
      <div class="mt-12 text-center">
        <p class="text-gray-600 mb-4">Was this guide helpful?</p>
        <div class="flex justify-center space-x-4">
          <button
            @click="provideFeedback('helpful')"
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
          >
            Yes, it was helpful
          </button>
          <button
            @click="provideFeedback('not-helpful')"
            class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
          >
            No, I need more help
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useToast } from 'vue-toastification'

const toast = useToast()
const searchQuery = ref('')

const sections = [
  {
    id: 'getting-started',
    title: 'Getting Started'
  },
  {
    id: 'adding-people',
    title: 'Adding People'
  },
  {
    id: 'managing-relationships',
    title: 'Managing Relationships'
  },
  {
    id: 'media-management',
    title: 'Media Management'
  },
  {
    id: 'privacy-settings',
    title: 'Privacy Settings'
  },
  {
    id: 'collaboration',
    title: 'Collaboration'
  },
  {
    id: 'advanced-features',
    title: 'Advanced Features'
  },
  {
    id: 'troubleshooting',
    title: 'Troubleshooting'
  }
]

const filteredSections = computed(() => {
  const query = searchQuery.value.toLowerCase()
  if (!query) return sections

  return sections.filter(section =>
    section.title.toLowerCase().includes(query)
  )
})

const provideFeedback = (type) => {
  if (type === 'helpful') {
    toast.success('Thank you for your feedback!')
  } else {
    toast.info('We\'re sorry the guide wasn\'t helpful. Please contact our support team for assistance.')
  }
}
</script> 