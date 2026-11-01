/* 主键必须随列表一起返回
   usp_Meta_List 按 DataObjectField.IsVisible = 1 选择列，而种子数据把主键 Id 标成了不可见，
   于是 /api/meta/{objectCode} 返回的行里没有 Id：
   前端拿到行也发不出“修改”（保存引擎无 Id 即按新增处理，撞唯一键）。
   主键是接口契约的一部分（行标识），这里统一置为可见——列表页仍只显示 ListView 配置的列，
   不会把 Id 展示给用户。 */
SET NOCOUNT ON;
GO
EXEC sys.sp_set_session_context N'BypassRls', 1;
GO
UPDATE plat.DataObjectField
SET IsVisible = 1
WHERE IsPrimaryKey = 1
  AND IsVisible = 0;
GO
