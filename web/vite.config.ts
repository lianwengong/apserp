import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// 开发态：前端 5200，后端 8080；构建产物为纯静态文件，由部署层（Nginx/网关）托管。
export default defineConfig({
  plugins: [vue()],
  base: './',
  server: {
    port: 5200,
    strictPort: true,
    proxy: {
      '/api': { target: 'http://127.0.0.1:8080', changeOrigin: true },
      '/actuator': { target: 'http://127.0.0.1:8080', changeOrigin: true }
    }
  },
  build: {
    outDir: 'dist',
    chunkSizeWarningLimit: 1500,
    rollupOptions: {
      output: {
        // 拆包：既利于缓存，也避开 esbuild 在 Windows 上处理超大 chunk 的临时文件问题
        manualChunks(id: string): string | undefined {
          if (!id.includes('node_modules')) return undefined
          if (id.includes('element-plus') || id.includes('@element-plus')) return 'element-plus'
          if (id.includes('@vue/') || id.includes('/vue/') || id.includes('vue-router')) return 'vue'
          return 'vendor'
        }
      }
    }
  }
})
