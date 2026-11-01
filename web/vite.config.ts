import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// 开发态：前端 5200，后端 8080；构建产物为纯静态文件，由部署层（Nginx/网关）托管。
export default defineConfig({
  plugins: [vue()],
  base: './',
  server: {
    host: '127.0.0.1',
    port: 5200,
    strictPort: true,
    proxy: {
      '/api': { target: 'http://127.0.0.1:8080', changeOrigin: true },
      '/actuator': { target: 'http://127.0.0.1:8080', changeOrigin: true }
    }
  },
  preview: {
    host: '127.0.0.1',
    port: 5201,
    proxy: {
      '/api': { target: 'http://127.0.0.1:8080', changeOrigin: true },
      '/actuator': { target: 'http://127.0.0.1:8080', changeOrigin: true }
    }
  },
  build: {
    outDir: 'dist',
    chunkSizeWarningLimit: 1500,
    // Windows 下 esbuild 处理超大 chunk 会因临时文件删除失败而中断构建，
    // 这里改用纯 JS 的 terser 压缩，并把 target 固定为 esnext（浏览器内网环境可控）。
    target: 'esnext',
    minify: 'terser',
    terserOptions: {
      compress: { passes: 2 },
      format: { comments: false }
    },
    rollupOptions: {
      output: {
        // 拆包：既利于缓存，也减小单文件体积
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
