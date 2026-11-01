import type { ApiEnvelope } from './types'

const TOKEN_KEY = 'apserp.token'

/** 业务错误：携带后端错误码与 HTTP 状态，页面据此区分 401 / 403 / 业务校验失败。 */
export class ApiError extends Error {
  readonly code: number
  readonly status: number

  constructor(message: string, code: number, status: number) {
    super(message)
    this.name = 'ApiError'
    this.code = code
    this.status = status
  }
}

let token: string | null = localStorage.getItem(TOKEN_KEY)
let unauthorizedHandler: (() => void) | null = null

export function getToken(): string | null {
  return token
}

export function setToken(value: string | null): void {
  token = value
  if (value) localStorage.setItem(TOKEN_KEY, value)
  else localStorage.removeItem(TOKEN_KEY)
}

/** 401 统一处理：清会话 + 回登录页，由 main.ts 注入，避免 http 依赖 router。 */
export function onUnauthorized(handler: () => void): void {
  unauthorizedHandler = handler
}

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  body?: unknown
  /** 原始请求体（保存引擎要求把 JSON 原样提交） */
  rawBody?: string
  signal?: AbortSignal
}

export async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const headers = new Headers({ Accept: 'application/json' })
  if (token) headers.set('Authorization', `Bearer ${token}`)

  let body: BodyInit | undefined
  if (options.rawBody !== undefined) {
    headers.set('Content-Type', 'application/json;charset=UTF-8')
    body = options.rawBody
  } else if (options.body !== undefined) {
    headers.set('Content-Type', 'application/json;charset=UTF-8')
    body = JSON.stringify(options.body)
  }

  let response: Response
  try {
    response = await fetch(path, {
      method: options.method ?? 'GET',
      headers,
      body,
      signal: options.signal
    })
  } catch (ex) {
    if (ex instanceof DOMException && ex.name === 'AbortError') throw ex
    throw new ApiError('无法连接服务器，请确认后端已启动（:8080）', -1, 0)
  }

  let envelope: ApiEnvelope<T> | null = null
  try {
    envelope = (await response.json()) as ApiEnvelope<T>
  } catch {
    envelope = null
  }

  if (response.status === 401) {
    if (unauthorizedHandler) unauthorizedHandler()
    throw new ApiError(envelope?.message ?? '登录已失效，请重新登录', envelope?.code ?? 3001, 401)
  }
  if (!response.ok || (envelope && envelope.code !== 0)) {
    throw new ApiError(
      envelope?.message ?? `请求失败（HTTP ${response.status}）`,
      envelope?.code ?? -1,
      response.status
    )
  }
  if (!envelope) throw new ApiError('服务器返回了非 JSON 内容', -1, response.status)
  return envelope.data
}

/** 拼接查询串：自动跳过空值，数组交给调用方先转字符串。 */
export function queryString(params: Record<string, string | number | null | undefined>): string {
  const search = new URLSearchParams()
  for (const [key, value] of Object.entries(params)) {
    if (value === null || value === undefined || value === '') continue
    search.set(key, String(value))
  }
  const text = search.toString()
  return text ? `?${text}` : ''
}
