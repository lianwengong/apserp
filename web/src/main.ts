import { createApp } from 'vue'
import ElementPlus from 'element-plus'
import zhCn from 'element-plus/es/locale/lang/zh-cn'
import 'element-plus/dist/index.css'
import 'element-plus/theme-chalk/dark/css-vars.css'
import './styles/base.css'
import './schema/pages'
import App from './App.vue'
import router from './router'
import { onUnauthorized } from './api/http'
import { session } from './stores/session'
import { applyAppearance } from './stores/appearance'

applyAppearance()

const app = createApp(App)
app.use(ElementPlus, { locale: zhCn, size: 'default' })
app.use(router)

// 全局 401：清会话并回登录页，避免 token 过期后每个页面各自弹错。
onUnauthorized(() => {
  session.logout()
  const current = router.currentRoute.value
  if (current.name !== 'login') {
    void router.replace({ name: 'login', query: { redirect: current.fullPath } })
  }
})

app.mount('#app')
