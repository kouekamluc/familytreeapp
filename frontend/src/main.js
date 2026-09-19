import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './assets/main.css'

// Create Vue app instance
const app = createApp(App)

// Create Pinia instance
const pinia = createPinia()

// Use plugins
app.use(pinia)
app.use(router)

// Mount app
app.mount('#app') 