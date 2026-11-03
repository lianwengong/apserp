package com.aschain.plat.admin;

import com.aschain.common.ApiResult;
import com.aschain.common.security.RequiresPermission;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 平台管理：平台角色与权限（{@code PLAT:*}）。
 *
 * <pre>
 * GET  /api/admin/roles                 角色列表（含权限点、成员数）
 * GET  /api/admin/roles/permissions     平台权限点清单
 * POST /api/admin/roles                 新建/修改角色（含权限勾选，覆盖式）
 * GET  /api/admin/roles/{id}/members    角色成员（平台账号 Id）
 * PUT  /api/admin/roles/{id}/members    覆盖式设置成员
 * </pre>
 */
@RestController
@RequiresPermission("PLAT:ROLE")
@RequestMapping("/api/admin/roles")
public class PlatformRoleController {

    private final PlatformRoleService platformRoles;

    public PlatformRoleController(PlatformRoleService platformRoles) {
        this.platformRoles = platformRoles;
    }

    public record MembersRequest(List<Long> userIds) {
    }

    @GetMapping
    public ApiResult<List<PlatformRoleService.RoleDto>> roles() {
        return ApiResult.ok(platformRoles.roles());
    }

    @GetMapping("/permissions")
    public ApiResult<List<PlatformRoleService.PermissionDto>> permissions() {
        return ApiResult.ok(platformRoles.permissions());
    }

    @PostMapping
    public ApiResult<Map<String, Long>> save(@RequestBody PlatformRoleService.SaveRequest req) {
        return ApiResult.ok(Map.of("id", platformRoles.save(req)));
    }

    @GetMapping("/{id}/members")
    public ApiResult<List<Long>> members(@PathVariable long id) {
        return ApiResult.ok(platformRoles.members(id));
    }

    @PutMapping("/{id}/members")
    public ApiResult<Void> setMembers(@PathVariable long id, @RequestBody MembersRequest req) {
        platformRoles.setMembers(id, req.userIds());
        return ApiResult.ok(null);
    }
}
