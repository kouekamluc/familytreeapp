import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useThemeStore = defineStore('theme', () => {
  const saved = localStorage.getItem('kkevo_theme')
  // Default to dark mode (royal obsidian), allow seamless toggle to light mode (royal ivory)
  const currentTheme = ref(saved === 'light' ? 'light' : 'dark')

  const isLight = computed(() => currentTheme.value === 'light')
  const isDark = computed(() => currentTheme.value === 'dark')

  const applyThemeToDOM = (t) => {
    const root = document.documentElement
    const body = document.body
    if (t === 'light') {
      root.classList.remove('dark')
      root.classList.add('light')
      root.setAttribute('data-theme', 'light')
      if (body) {
        body.classList.remove('dark')
        body.classList.add('light')
        body.setAttribute('data-theme', 'light')
      }
    } else {
      root.classList.remove('light')
      root.classList.add('dark')
      root.setAttribute('data-theme', 'dark')
      if (body) {
        body.classList.remove('light')
        body.classList.add('dark')
        body.setAttribute('data-theme', 'dark')
      }
    }
  }

  const initTheme = () => {
    applyThemeToDOM(currentTheme.value)
  }

  const toggleTheme = () => {
    currentTheme.value = currentTheme.value === 'dark' ? 'light' : 'dark'
    localStorage.setItem('kkevo_theme', currentTheme.value)
    applyThemeToDOM(currentTheme.value)
  }

  const setTheme = (mode) => {
    currentTheme.value = mode === 'light' ? 'light' : 'dark'
    localStorage.setItem('kkevo_theme', currentTheme.value)
    applyThemeToDOM(currentTheme.value)
  }

  return {
    currentTheme,
    isLight,
    isDark,
    initTheme,
    toggleTheme,
    setTheme
  }
})
