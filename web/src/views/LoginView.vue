<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { FormInstance, FormRules } from 'element-plus'
import { Key, Lock, OfficeBuilding, User } from '@element-plus/icons-vue'
import { login, platformLogin } from '../api/auth'
import { session } from '../stores/session'
import { resetSessionCaches } from '../stores/reset'
import { appearance } from '../stores/appearance'

const route = useRoute()
const router = useRouter()

const formRef = ref<FormInstance>()
const loading = ref(false)
const error = ref('')
/** 登录方式：tenant 租户登录（默认）/ platform 平台登录（无租户名） */
const mode = ref<'tenant' | 'platform'>(String(route.query.app) === '1' ? 'platform' : 'tenant')

const form = reactive({
  tenantCode: session.lastTenantCode(),
  userName: import.meta.env.DEV ? 'admin' : '',
  password: ''
})

const rules: FormRules = {
  tenantCode: [{ required: true, message: '请输入租户名称', trigger: 'blur' }],
  userName: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入口令', trigger: 'blur' }]
}

const isDev = import.meta.env.DEV
const isPlatform = computed(() => mode.value === 'platform')

function switchMode(next: 'tenant' | 'platform'): void {
  mode.value = next
  error.value = ''
  form.password = ''
}

async function submit(): Promise<void> {
  if (loading.value) return
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return

  loading.value = true
  error.value = ''
  try {
    // 两种登录走两个接口：平台登录不带租户名，令牌带平台作用域（可管理所有租户）
    const result = isPlatform.value
      ? await platformLogin({ userName: form.userName.trim(), password: form.password })
      : await login({
          tenantCode: form.tenantCode.trim(),
          userName: form.userName.trim(),
          password: form.password,
          appType: 2
        })
    session.setLogin(result, isPlatform.value ? '' : form.tenantCode.trim())
    // 新会话：清掉上一会话的菜单树与对象目录，否则侧边栏会少内容（刷新后才好）
    resetSessionCaches()
    await session.loadMe()
    await appearance.loadRemote()
    const home = result.appType === 1 ? '/platform' : '/'
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : home
    await router.replace(redirect)
  } catch (ex) {
    error.value = ex instanceof Error ? ex.message : '登录失败，请稍后重试'
    form.password = ''
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="login">
    <section class="brand-panel">
      <div class="brand-row">
        <span class="logo">AS</span>
        <span class="brand-name">阿申商链</span>
      </div>

      <div class="brand-copy">
        <p class="eyebrow">ENGINE-DRIVEN ERP</p>
        <h1>一套元数据<br />长出整个进销存</h1>
        <p class="lead">
          列表、表单、权限、编号全部由配置驱动。新增一个数据对象，页面自动生成——不写页面代码。
        </p>
        <ul class="features">
          <li><span class="tick">✓</span>元数据驱动：换 objectCode 不改代码</li>
          <li><span class="tick">✓</span>多租户隔离：连接级 SESSION_CONTEXT + RLS</li>
          <li><span class="tick">✓</span>字段级权限：不可见字段根本不下发</li>
        </ul>
      </div>

      <div class="brand-foot">阿申商链 · 商贸供应链管理系统 · v0.1.0</div>
    </section>

    <section class="form-panel">
      <div class="form-card">
        <header class="form-head">
          <h2>{{ isPlatform ? '平台登录' : '登录' }}</h2>
          <p class="muted">
            {{ isPlatform ? '平台账号不绑定租户，可管理所有租户' : '使用租户账号进入业务管理' }}
          </p>
        </header>

        <el-alert
          v-if="error"
          :title="error"
          type="error"
          show-icon
          :closable="false"
          class="login-error"
        />

        <el-form
          ref="formRef"
          :model="form"
          :rules="rules"
          label-position="top"
          size="large"
          @submit.prevent="submit"
        >
          <el-form-item v-if="!isPlatform" label="租户名称" prop="tenantCode">
            <el-input
              v-model="form.tenantCode"
              placeholder="如 T001 / 示例商贸有限公司"
              :prefix-icon="OfficeBuilding"
              autocomplete="organization"
            />
          </el-form-item>
          <el-form-item label="用户名" prop="userName">
            <el-input
              v-model="form.userName"
              placeholder="请输入用户名"
              :prefix-icon="User"
              autocomplete="username"
            />
          </el-form-item>
          <el-form-item label="口令" prop="password">
            <el-input
              v-model="form.password"
              type="password"
              placeholder="请输入口令"
              :prefix-icon="Lock"
              show-password
              autocomplete="current-password"
              @keyup.enter="submit"
            />
          </el-form-item>

          <el-button type="primary" class="submit" :loading="loading" native-type="submit">
            {{ isPlatform ? '进入平台管理' : '进入业务管理' }}
          </el-button>
        </el-form>

        <!-- 平台登录入口：默认收起，放在租户登录下面，避免抢占普通用户的注意力 -->
        <button
          v-if="!isPlatform"
          type="button"
          class="platform-hotspot"
          @click="switchMode('platform')"
        >
          <el-icon><Key /></el-icon>
          <span>平台管理员登录</span>
          <span class="hotspot-hint">无需租户名，可管理所有租户</span>
        </button>
        <button v-else type="button" class="platform-hotspot is-back" @click="switchMode('tenant')">
          <el-icon><OfficeBuilding /></el-icon>
          <span>返回租户登录</span>
        </button>

        <p v-if="isDev" class="dev-hint">
          <template v-if="isPlatform">
            开发环境平台账号：<code>admin / AsChain@2026</code>
          </template>
          <template v-else>开发环境演示账号：<code>T001 / admin / AsChain@2026</code></template>
        </p>
        <p class="legal muted">登录即表示同意内部系统使用规范</p>
      </div>
    </section>
  </div>
</template>

<style scoped>
/* 平台登录热区：默认收在租户登录下面，不抢普通用户注意力 */
.platform-hotspot {
  display: flex;
  align-items: center;
  gap: 6px;
  width: 100%;
  margin-top: 14px;
  padding: 10px 12px;
  border: 1px dashed var(--line);
  border-radius: 10px;
  background: transparent;
  color: var(--muted);
  font-size: 12px;
  text-align: left;
  cursor: pointer;
  transition: border-color 0.12s ease, color 0.12s ease, background 0.12s ease;
}
.platform-hotspot:hover {
  border-color: var(--brand-400);
  color: var(--brand-700);
  background: var(--brand-50);
}
.platform-hotspot.is-back { justify-content: center; border-style: solid; }
.hotspot-hint { margin-left: auto; font-size: 11px; color: var(--muted); }
.form-head h2 { margin: 0; font-size: 20px; }

/* 入口选择：两张卡片，登录前先定身份 */
.entrance-switch {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin: 14px 0 18px;
}
.entrance-card {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 12px 14px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--card);
  text-align: left;
  cursor: pointer;
  transition: border-color 0.12s ease, background 0.12s ease, box-shadow 0.12s ease;
}
.entrance-card:hover { border-color: var(--brand-400); }
.entrance-card.active {
  border-color: var(--brand);
  background: var(--brand-50);
  box-shadow: inset 0 0 0 1px var(--brand);
}
.entrance-title { font-size: 14px; font-weight: 600; color: var(--ink); }
.entrance-card.active .entrance-title { color: var(--brand-700); }
.entrance-hint { font-size: 11px; color: var(--muted); line-height: 1.5; }
.login {
  display: flex;
  min-height: 100%;
  background: #fff;
}

/* ---------------------------------------------------------------- 左侧品牌区 */

.brand-panel {
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  width: 56%;
  max-width: 820px;
  padding: 40px 56px 32px;
  overflow: hidden;
  color: #e8f1ec;
  background:
    radial-gradient(900px 500px at 12% 0%, rgba(63, 191, 146, 0.22), transparent 60%),
    radial-gradient(700px 500px at 100% 100%, rgba(28, 109, 81, 0.35), transparent 62%),
    linear-gradient(155deg, #0d1f2c 0%, #12202e 48%, #0d2b22 100%);
}

.brand-panel::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(255, 255, 255, 0.035) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255, 255, 255, 0.035) 1px, transparent 1px);
  background-size: 44px 44px;
  mask-image: linear-gradient(180deg, rgba(0, 0, 0, 0.9), transparent 75%);
  pointer-events: none;
}

.brand-row {
  position: relative;
  display: flex;
  align-items: center;
  gap: 10px;
  z-index: 1;
}

.logo {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  border-radius: 9px;
  background: linear-gradient(135deg, #3fbf92, #1c6d51);
  color: #fff;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.04em;
}

.brand-name {
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 0.04em;
}

.brand-copy {
  position: relative;
  z-index: 1;
  max-width: 520px;
}

.eyebrow {
  color: #6fd3ae;
  margin: 0 0 14px;
}

h1 {
  font-size: 40px;
  line-height: 1.25;
  color: #fff;
  letter-spacing: -0.02em;
  font-weight: 650;
}

.lead {
  margin: 18px 0 0;
  font-size: 14px;
  line-height: 1.85;
  color: #a9bcb4;
  max-width: 460px;
}

.features {
  margin: 30px 0 0;
  padding: 0;
  list-style: none;
  display: grid;
  gap: 12px;
  font-size: 13px;
  color: #c9d8d1;
}

.features li {
  display: flex;
  align-items: center;
  gap: 10px;
}

.tick {
  display: grid;
  place-items: center;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  background: rgba(63, 191, 146, 0.16);
  color: #6fd3ae;
  font-size: 11px;
}

.brand-foot {
  position: relative;
  z-index: 1;
  font-size: 11px;
  color: #6f8478;
}

/* ---------------------------------------------------------------- 右侧表单区 */

.form-panel {
  display: grid;
  place-items: center;
  flex: 1;
  padding: 40px 24px;
  background: #fbfcfd;
}

.form-card {
  width: 100%;
  max-width: 360px;
}

.form-head {
  margin-bottom: 26px;
}

.form-head h2 {
  font-size: 22px;
  letter-spacing: -0.01em;
}

.form-head p {
  margin: 6px 0 0;
  font-size: 13px;
}

.login-error {
  margin-bottom: 16px;
}

.submit {
  width: 100%;
  margin-top: 6px;
  font-weight: 600;
  letter-spacing: 0.04em;
}

.dev-hint {
  margin: 18px 0 0;
  padding: 9px 12px;
  border: 1px dashed var(--line-strong);
  border-radius: 8px;
  background: #f7faf9;
  font-size: 11.5px;
  color: #5f7082;
}

.dev-hint code {
  font-family: "Cascadia Code", Consolas, monospace;
  color: var(--brand-700);
}

.legal {
  margin: 18px 0 0;
  font-size: 11px;
  text-align: center;
}

@media (max-width: 900px) {
  .brand-panel {
    display: none;
  }

  .login {
    min-height: 100vh;
  }
}
</style>
