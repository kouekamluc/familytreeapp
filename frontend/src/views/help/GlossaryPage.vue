<template>
  <div class="min-h-screen bg-gray-50 py-8">
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      <!-- Header -->
      <div class="text-center mb-12">
        <h1 class="text-3xl font-extrabold text-gray-900 sm:text-4xl">
          Genealogy Glossary
        </h1>
        <p class="mt-4 text-lg text-gray-500">
          Common terms and definitions in family history research
        </p>
      </div>

      <!-- Search -->
      <div class="max-w-2xl mx-auto mb-12">
        <div class="relative">
          <input
            type="text"
            v-model="searchQuery"
            placeholder="Search terms..."
            class="w-full px-4 py-3 rounded-lg border border-gray-300 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
          />
          <div class="absolute inset-y-0 right-0 flex items-center pr-3">
            <svg
              class="h-5 w-5 text-gray-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
              />
            </svg>
          </div>
        </div>
      </div>

      <!-- Categories -->
      <div class="mb-8">
        <div class="flex flex-wrap gap-2">
          <button
            v-for="category in categories"
            :key="category.id"
            @click="selectedCategory = category.id"
            :class="[
              'px-4 py-2 text-sm font-medium rounded-md',
              selectedCategory === category.id
                ? 'bg-indigo-100 text-indigo-700'
                : 'bg-white text-gray-700 hover:bg-gray-50'
            ]"
          >
            {{ category.name }}
          </button>
        </div>
      </div>

      <!-- Terms -->
      <div class="bg-white rounded-lg shadow-lg p-6">
        <div class="space-y-8">
          <div
            v-for="(terms, category) in filteredTerms"
            :key="category"
            class="border-b border-gray-200 last:border-0 pb-8 last:pb-0"
          >
            <h2 class="text-2xl font-bold text-gray-900 mb-6">
              {{ getCategoryName(category) }}
            </h2>
            <div class="grid gap-6">
              <div
                v-for="term in terms"
                :key="term.term"
                class="bg-gray-50 rounded-lg p-6"
              >
                <div class="flex items-start">
                  <div class="flex-1">
                    <h3 class="text-lg font-medium text-gray-900 mb-2">
                      {{ term.term }}
                    </h3>
                    <p class="text-gray-600 mb-4">{{ term.definition }}</p>
                    <div v-if="term.examples" class="mt-4">
                      <h4 class="text-sm font-medium text-gray-700 mb-2">
                        Examples:
                      </h4>
                      <ul class="list-disc list-inside text-gray-600 space-y-1">
                        <li v-for="example in term.examples" :key="example">
                          {{ example }}
                        </li>
                      </ul>
                    </div>
                    <div v-if="term.relatedTerms" class="mt-4">
                      <h4 class="text-sm font-medium text-gray-700 mb-2">
                        Related Terms:
                      </h4>
                      <div class="flex flex-wrap gap-2">
                        <span
                          v-for="relatedTerm in term.relatedTerms"
                          :key="relatedTerm"
                          class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800"
                        >
                          {{ relatedTerm }}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Contribute -->
      <div class="mt-12 text-center">
        <p class="text-gray-600 mb-4">
          Don't see a term you're looking for?
        </p>
        <button
          class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
        >
          Suggest a Term
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const categories = [
  { id: 'all', name: 'All Terms' },
  { id: 'relationships', name: 'Relationships' },
  { id: 'documents', name: 'Documents & Records' },
  { id: 'research', name: 'Research Methods' },
  { id: 'dna', name: 'DNA & Genetics' },
  { id: 'software', name: 'Software Terms' }
]

const selectedCategory = ref('all')
const searchQuery = ref('')

const terms = {
  relationships: [
    {
      term: 'Ancestor',
      definition: 'A person from whom one is descended, typically more remote than a grandparent.',
      examples: [
        'Great-grandparents are ancestors',
        'Aunts and uncles are not ancestors'
      ],
      relatedTerms: ['Descendant', 'Lineage', 'Pedigree']
    },
    {
      term: 'Descendant',
      definition: 'A person who is descended from a particular ancestor.',
      examples: [
        'Children are descendants of their parents',
        'Grandchildren are descendants of their grandparents'
      ],
      relatedTerms: ['Ancestor', 'Progeny', 'Offspring']
    },
    {
      term: 'Collateral Relative',
      definition: 'A relative who is not in your direct line of descent, such as siblings, aunts, uncles, and cousins.',
      examples: [
        'Your mother\'s sister is a collateral relative',
        'Your father\'s brother\'s children are collateral relatives'
      ],
      relatedTerms: ['Direct Line', 'Ancestor', 'Descendant']
    }
  ],
  documents: [
    {
      term: 'Vital Records',
      definition: 'Official records of births, deaths, marriages, and divorces.',
      examples: [
        'Birth certificates',
        'Death certificates',
        'Marriage licenses'
      ],
      relatedTerms: ['Civil Registration', 'Certificate', 'Document']
    },
    {
      term: 'Census Record',
      definition: 'An official count of the population, typically including names, ages, and other demographic information.',
      examples: [
        'U.S. Federal Census',
        'State Census',
        'Population Schedule'
      ],
      relatedTerms: ['Enumeration', 'Schedule', 'Population']
    }
  ],
  research: [
    {
      term: 'Primary Source',
      definition: 'A document or record created at the time of an event by someone who witnessed or participated in it.',
      examples: [
        'Birth certificate',
        'Marriage license',
        'Contemporary diary'
      ],
      relatedTerms: ['Secondary Source', 'Evidence', 'Document']
    },
    {
      term: 'Brick Wall',
      definition: 'A point in genealogical research where you cannot find information to proceed further.',
      examples: [
        'Unable to find parents of an ancestor',
        'Cannot locate immigration records'
      ],
      relatedTerms: ['Research Problem', 'Dead End', 'Breakthrough']
    }
  ],
  dna: [
    {
      term: 'Autosomal DNA',
      definition: 'DNA inherited from both parents, found in the 22 pairs of non-sex chromosomes.',
      examples: [
        'Used for finding cousins',
        'Can identify ethnic origins'
      ],
      relatedTerms: ['Chromosome', 'Genetic', 'Inheritance']
    },
    {
      term: 'Centimorgan',
      definition: 'A unit of measurement for genetic linkage, used to describe the amount of DNA shared between relatives.',
      examples: [
        'Siblings share about 2,500-3,500 centimorgans',
        'First cousins share about 850-1,300 centimorgans'
      ],
      relatedTerms: ['DNA Match', 'Genetic Distance', 'Shared DNA']
    }
  ],
  software: [
    {
      term: 'GEDCOM',
      definition: 'Genealogical Data Communication, a standard file format for genealogical data.',
      examples: [
        'Used to transfer family tree data between programs',
        'File extension .ged'
      ],
      relatedTerms: ['Import', 'Export', 'Data Transfer']
    },
    {
      term: 'Source Citation',
      definition: 'A reference to the origin of genealogical information, following a specific format.',
      examples: [
        'Chicago Manual of Style',
        'Evidence Explained format'
      ],
      relatedTerms: ['Citation', 'Source', 'Reference']
    }
  ]
}

const filteredTerms = computed(() => {
  let filtered = { ...terms }

  // Apply category filter
  if (selectedCategory.value !== 'all') {
    const category = selectedCategory.value
    filtered = { [category]: terms[category] }
  }

  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    const result = {}

    Object.entries(filtered).forEach(([category, categoryTerms]) => {
      const matchingTerms = categoryTerms.filter(term => {
        const searchableText = [
          term.term,
          term.definition,
          ...(term.examples || []),
          ...(term.relatedTerms || [])
        ].join(' ').toLowerCase()
        return searchableText.includes(query)
      })

      if (matchingTerms.length > 0) {
        result[category] = matchingTerms
      }
    })

    filtered = result
  }

  return filtered
})

const getCategoryName = (categoryId) => {
  const category = categories.find(c => c.id === categoryId)
  return category ? category.name : categoryId
}
</script> 