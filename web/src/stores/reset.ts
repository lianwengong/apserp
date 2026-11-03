import { catalog } from './catalog'
import { menus } from './menu'

/**
 * 清掉「跟着登录会话走」的前端缓存。
 *
 * <p>{@code menus} / {@code catalog} 是模块级单例：同一个标签页里退出再登录、
 * 或从平台入口切到业务入口，它们不会自己失效。不复位就会出现
 * 「登录进去侧边栏少一截，刷新一下才对」——因为侧边栏拿到的是上一个会话的树。</p>
 *
 * <p>放在单独模块里而不是塞进 session store，是为了避免
 * session → menu → session 的循环依赖。</p>
 */
export function resetSessionCaches(): void {
  menus.reset()
  catalog.reset()
}
