import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
const apiTarget = globalThis.process?.env?.VITE_API_TARGET || 'http://backend:4000'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    middlewareMode: false,
    proxy: {
      '/api': {
        target: apiTarget,
        changeOrigin: true,
        ws: false,
        // Preserve request headers exactly as sent
        headers: {},
      },
    },
  },
})
