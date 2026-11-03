import { createRouter, createWebHashHistory } from 'vue-router'
import MainLayout from '../layouts/MainLayout.vue'
import DashboardView from '../views/DashboardView.vue'
import LoginView from '../views/LoginView.vue'
import ObjectPageView from '../views/ObjectPageView.vue'
import PageView from '../views/PageView.vue'
import DesignerView from '../views/design/DesignerView.vue'
import TodoView from '../views/TodoView.vue'
import WorkflowCenter from '../views/WorkflowCenter.vue'
import ModuleAdminView from '../views/system/ModuleAdminView.vue'
import MenuAdminView from '../views/system/MenuAdminView.vue'
import TerminalAdminView from '../views/system/TerminalAdminView.vue'
import CodeRuleView from '../views/system/CodeRuleView.vue'
import PageSchemaAdminView from '../views/system/PageSchemaAdminView.vue'
import MenuPlaceholder from '../views/MenuPlaceholder.vue'
import PlatformOverview from '../views/admin/PlatformOverview.vue'
import TenantListView from '../views/admin/TenantListView.vue'
import MenuOverviewView from '../views/admin/MenuOverviewView.vue'
import PlatformUserView from '../views/admin/PlatformUserView.vue'
import PlatformRoleView from '../views/admin/PlatformRoleView.vue'
import ForbiddenView from '../views/ForbiddenView.vue'
import NotFoundView from '../views/NotFoundView.vue'
import { session } from '../stores/session'

declare module 'vue-router' {
  interface RouteMeta {
    /** 免登录页面（仅登录页） */
    public?: boolean
    title?: string
    /** keep-alive 的组件名；有值才缓存 */
    cacheName?: string
    /** 所属入口：1 平台管理 / 2 业务管理；不填表示两个入口都能进（如 403/404） */
    app?: number
  }
}

/** 入口默认首页：平台管理 → /platform，业务管理 → / */
export function homeOf(appType: number): string {
  return appType === 1 ? '/platform' : '/'
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
        // ---------------------------------------------------------------- 业务管理入口
        { path: '', name: 'home', component: DashboardView, meta: { title: '业务工作台', cacheName: 'DashboardView', app: 2 } },
        {
          path: 'object/:code',
          name: 'object',
          component: ObjectPageView,
          props: (route) => ({ code: String(route.params.code ?? '') }),
          meta: { title: '数据列表', cacheName: 'ObjectPageView', app: 2 }
        },
        {
          path: 'page/:code',
          name: 'page',
          component: PageView,
          props: (route) => ({ code: String(route.params.code ?? '') }),
          meta: { title: '业务页面', cacheName: 'PageView', app: 2 }
        },
        { path: 'todo', name: 'todo', component: TodoView, meta: { title: '我的待办', cacheName: 'TodoView', app: 2 } },
        { path: 'workflow', name: 'workflow', component: WorkflowCenter, meta: { title: '流程中心', cacheName: 'WorkflowCenter', app: 2 } },
        {
          path: 'm/:code',
          name: 'menu-page',
          component: MenuPlaceholder,
          meta: { title: '功能页面', cacheName: 'MenuPlaceholder', app: 2 }
        },
        // ---------------------------------------------------------------- 平台管理入口
        {
          path: 'platform',
          name: 'platform-home',
          component: PlatformOverview,
          meta: { title: '平台工作台', cacheName: 'PlatformOverview', app: 1 }
        },
        { path: 'design', name: 'design', component: DesignerView, meta: { title: '设计器中心', cacheName: 'DesignerView', app: 1 } },
        { path: 'system/modules', name: 'system-modules', component: ModuleAdminView, meta: { title: '功能模块管理', cacheName: 'ModuleAdminView', app: 1 } },
        { path: 'system/menus', name: 'system-menus', component: MenuAdminView, meta: { title: '菜单设置', cacheName: 'MenuAdminView', app: 1 } },
        { path: 'system/terminals', name: 'system-terminals', component: TerminalAdminView, meta: { title: '终端与功能', cacheName: 'TerminalAdminView', app: 1 } },
        { path: 'system/code-rules', name: 'system-code-rules', component: CodeRuleView, meta: { title: '编号规则', cacheName: 'CodeRuleView', app: 1 } },
        { path: 'system/pages', name: 'system-pages', component: PageSchemaAdminView, meta: { title: '页面编排', cacheName: 'PageSchemaAdminView', app: 1 } },
        {
          path: 'admin',
          name: 'platform-overview',
          component: PlatformOverview,
          meta: { title: '平台概览', cacheName: 'PlatformOverview', app: 1 }
        },
        {
          path: 'admin/tenants',
          name: 'platform-tenants',
          component: TenantListView,
          meta: { title: '租户管理', cacheName: 'TenantListView', app: 1 }
        },
        {
          path: 'admin/users',
          name: 'platform-users',
          component: PlatformUserView,
          meta: { title: '用户与权限', cacheName: 'PlatformUserView', app: 1 }
        },
        {
          path: 'admin/roles',
          name: 'platform-roles',
          component: PlatformRoleView,
          meta: { title: '角色与权限', cacheName: 'PlatformRoleView', app: 1 }
        },
        {
          path: 'admin/menus',
          name: 'platform-menus',
          component: MenuOverviewView,
          meta: { title: '菜单总览', cacheName: 'MenuOverviewView', app: 1 }
        },
        // ---------------------------------------------------------------- 公共
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
    // 已登录时访问登录页 → 回当前入口首页
    if (to.name === 'login' && session.state.token) return { path: homeOf(session.state.appType) }
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
  // 入口隔离：平台页面只能在平台入口打开，业务页面同理；跨入口一律回本入口首页
  const routeApp = to.meta.app
  if (routeApp && routeApp !== session.state.appType) {
    return { path: homeOf(session.state.appType) }
  }
  return true
})

router.afterEach((to) => {
  const title = to.meta.title
  document.title = title ? `${title} · 阿申商链` : '阿申商链 · 商贸供应链管理系统'
})

export default router
