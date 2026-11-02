import { createRouter, createWebHashHistory } from 'vue-router'
import MainLayout from '../layouts/MainLayout.vue'
import HomeView from '../views/HomeView.vue'
import LoginView from '../views/LoginView.vue'
import MetaListView from '../views/MetaListView.vue'
import DesignerView from '../views/design/DesignerView.vue'
import TodoView from '../views/TodoView.vue'
import WorkflowCenter from '../views/WorkflowCenter.vue'
import ModuleAdminView from '../views/system/ModuleAdminView.vue'
import MenuAdminView from '../views/system/MenuAdminView.vue'
import TerminalAdminView from '../views/system/TerminalAdminView.vue'
import MenuPlaceholder from '../views/MenuPlaceholder.vue'
import PlatformOverview from '../views/admin/PlatformOverview.vue'
import TenantListView from '../views/admin/TenantListView.vue'
import MenuOverviewView from '../views/admin/MenuOverviewView.vue'
import ForbiddenView from '../views/ForbiddenView.vue'
import NotFoundView from '../views/NotFoundView.vue'
import { session } from '../stores/session'

declare module 'vue-router' {
  interface RouteMeta {
    /** 免登录页面（仅登录页） */
    public?: boolean
    title?: string
  }
}

const router = createRouter({
  // Hash 路由：静态托管到任意子路径都不用改服务器 rewrite 规则
  history: createWebHashHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: LoginView,
      meta: { public: true, title: '登录' }
    },
    {
      path: '/',
      component: MainLayout,
      children: [
        { path: '', name: 'home', component: HomeView, meta: { title: '工作台' } },
        {
          path: 'object/:code',
          name: 'object',
          component: MetaListView,
          meta: { title: '数据列表' }
        },
        { path: 'design', name: 'design', component: DesignerView, meta: { title: '设计器中心' } },
        { path: 'todo', name: 'todo', component: TodoView, meta: { title: '我的待办' } },
        { path: 'workflow', name: 'workflow', component: WorkflowCenter, meta: { title: '流程中心' } },
        { path: 'system/modules', name: 'system-modules', component: ModuleAdminView, meta: { title: '功能模块管理' } },
        { path: 'system/menus', name: 'system-menus', component: MenuAdminView, meta: { title: '菜单设置' } },
        { path: 'system/terminals', name: 'system-terminals', component: TerminalAdminView, meta: { title: '终端与功能' } },
        {
          path: 'm/:code',
          name: 'menu-page',
          component: MenuPlaceholder,
          meta: { title: '功能页面' }
        },
        {
          path: 'admin',
          name: 'platform-overview',
          component: PlatformOverview,
          meta: { title: '平台概览' }
        },
        {
          path: 'admin/tenants',
          name: 'platform-tenants',
          component: TenantListView,
          meta: { title: '租户管理' }
        },
        {
          path: 'admin/menus',
          name: 'platform-menus',
          component: MenuOverviewView,
          meta: { title: '菜单总览' }
        },
        { path: '403', name: 'forbidden', component: ForbiddenView, meta: { title: '无访问权限' } },
        {
          path: ':pathMatch(.*)*',
          name: 'not-found',
          component: NotFoundView,
          meta: { title: '页面不存在' }
        }
      ]
    }
  ],
  scrollBehavior: () => ({ top: 0 })
})

router.beforeEach(async (to) => {
  if (to.meta.public) {
    // 已登录时访问登录页 → 回工作台
    if (to.name === 'login' && session.state.token) return { name: 'home' }
    return true
  }
  if (!session.state.token) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  if (!session.state.loaded) {
    try {
      await session.loadMe()
    } catch {
      session.logout()
      return { name: 'login', query: { redirect: to.fullPath } }
    }
  }
  return true
})

router.afterEach((to) => {
  const title = to.meta.title
  document.title = title ? `${title} · APS ERP` : 'APS ERP · 进销存'
})

export default router
