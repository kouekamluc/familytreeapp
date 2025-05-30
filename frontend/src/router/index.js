import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'landing',
      component: () => import('../views/LandingPage.vue')
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/auth/LoginPage.vue')
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('../views/auth/RegisterPage.vue')
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: () => import('../views/DashboardPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/trees',
      name: 'trees',
      component: () => import('../views/trees/TreeListPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/trees/create',
      name: 'create-tree',
      component: () => import('../views/trees/CreateTreePage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/trees/:id',
      name: 'tree-view',
      component: () => import('../views/trees/TreeViewPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/trees/:id/settings',
      name: 'tree-settings',
      component: () => import('../views/trees/TreeSettingsPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/people/:id',
      name: 'person-detail',
      component: () => import('../views/people/PersonDetailPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/media',
      name: 'media-gallery',
      component: () => import('../views/media/MediaGalleryPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/profile',
      name: 'profile',
      component: () => import('../views/profile/ProfilePage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/settings',
      name: 'settings',
      component: () => import('../views/settings/SettingsPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/help',
      name: 'help',
      component: () => import('../views/help/HelpCenterPage.vue')
    },
    {
      path: '/password-reset',
      name: 'password-reset-request',
      component: () => import('../views/auth/PasswordResetRequestPage.vue')
    },
    {
      path: '/password-reset/sent',
      name: 'password-reset-sent',
      component: () => import('../views/auth/PasswordResetSentPage.vue')
    },
    {
      path: '/password-reset/confirm',
      name: 'password-reset',
      component: () => import('../views/auth/PasswordResetPage.vue')
    },
    {
      path: '/password-reset/success',
      name: 'password-reset-success',
      component: () => import('../views/auth/PasswordResetSuccessPage.vue')
    },
    {
      path: '/trees/:id/sharing',
      name: 'tree-sharing',
      component: () => import('../views/trees/TreeSharingPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/people/:id/edit',
      name: 'person-edit',
      component: () => import('../views/people/PersonEditPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/people/quick-add',
      name: 'person-quick-add',
      component: () => import('../views/people/PersonQuickAddPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/people/merge',
      name: 'person-merge',
      component: () => import('../views/people/PersonMergePage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/relationships/editor',
      name: 'relationship-editor',
      component: () => import('../views/relationships/RelationshipEditorPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/relationships/family-group',
      name: 'family-group',
      component: () => import('../views/relationships/FamilyGroupPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/media/upload',
      name: 'media-upload',
      component: () => import('../views/media/MediaUploadPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/media/:id',
      name: 'media-detail',
      component: () => import('../views/media/MediaDetailPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/media/:id/edit',
      name: 'media-editor',
      component: () => import('../views/media/MediaEditorPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/import',
      name: 'import-wizard',
      component: () => import('../views/importexport/ImportWizardPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/export',
      name: 'export-options',
      component: () => import('../views/importexport/ExportOptionsPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/search',
      name: 'search-results',
      component: () => import('../views/search/SearchResultsPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/search/advanced',
      name: 'advanced-search',
      component: () => import('../views/search/AdvancedSearchPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/settings/account',
      name: 'account-settings',
      component: () => import('../views/settings/AccountSettingsPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/settings/app',
      name: 'app-settings',
      component: () => import('../views/settings/AppSettingsPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/settings/data',
      name: 'data-management',
      component: () => import('../views/settings/DataManagementPage.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/help/faq',
      name: 'faq',
      component: () => import('../views/help/FAQPage.vue')
    },
    {
      path: '/help/contact',
      name: 'contact-support',
      component: () => import('../views/help/ContactSupportPage.vue')
    },
    {
      path: '/help/privacy',
      name: 'privacy-policy',
      component: () => import('../views/help/PrivacyPolicyPage.vue')
    },
    {
      path: '/help/terms',
      name: 'terms-of-service',
      component: () => import('../views/help/TermsOfServicePage.vue')
    },
    {
      path: '/help/user-guide',
      name: 'user-guide',
      component: () => import('../views/help/UserGuidePage.vue')
    },
    {
      path: '/help/tutorial',
      name: 'interactive-tutorial',
      component: () => import('../views/help/InteractiveTutorialPage.vue')
    },
    {
      path: '/help/videos',
      name: 'video-tutorials',
      component: () => import('../views/help/VideoTutorialsPage.vue')
    },
    {
      path: '/help/shortcuts',
      name: 'keyboard-shortcuts',
      component: () => import('../views/help/KeyboardShortcutsPage.vue')
    },
    {
      path: '/help/glossary',
      name: 'glossary',
      component: () => import('../views/help/GlossaryPage.vue')
    },
    {
      path: '/help/release-notes',
      name: 'release-notes',
      component: () => import('../views/help/ReleaseNotesPage.vue')
    },
    {
      path: '/help/feedback',
      name: 'feedback',
      component: () => import('../views/help/FeedbackPage.vue')
    },
    {
      path: '/help/community',
      name: 'community',
      component: () => import('../views/help/CommunityPage.vue')
    },
    {
      path: '/help/contributing',
      name: 'contributing',
      component: () => import('../views/help/ContributingPage.vue')
    }
  ]
})

// Navigation guard
router.beforeEach((to, from, next) => {
  const isAuthenticated = localStorage.getItem('token')
  
  if (to.meta.requiresAuth && !isAuthenticated) {
    next({ name: 'login', query: { redirect: to.fullPath } })
  } else {
    next()
  }
})

export default router 