--
-- This will make the user with @username REC_ADMIN on for the
-- connected db, allowing them to do everything in Reconcilor.
--
-- The user will *need connect at least once* and get the access
-- denied message in order for the user record to be created
--

-- set the username that should be given permissions
declare @username varchar(64)
set @username = 'DOWNERGROUP\Vince.Chun'

------------------------
select top(100) * from securityuser order by userid desc
------------------------
declare @userid int
select @userid = userid from SecurityUser where ntaccountname like '%' + @username + '%'

delete from SecurityRoleAssignment where userid = @userid

insert into SecurityRoleAssignment (RoleId, UserId)
	select 'REC_ADMIN', @userid union
	select 'BHP_NJV', @userid union
	select 'BHP_YANDI', @userid union
	select 'BHP_AREAC', @userid union
	select 'BHP_JIMBLEBAR', @userid union
	select 'BHP_YARRIE', @userid

select * from SecurityRoleAssignment where userid = @userid

--
-- If you're dealing with a db that has just been restored, then
-- use these commands to make sure the users are linked properly
-- from the db to the server level
--
--exec sp_change_users_login 'Auto_fix', 'ReconcilorUI'
--exec sp_change_users_login 'Auto_fix', 'ReconcilorEngine'
--exec sp_change_users_login 'Auto_fix', 'ReconcilorImport'
--exec sp_change_users_login 'Auto_fix', 'ReconcilorReport'
--exec sp_change_users_login 'Auto_fix', 'ReconcilorRecalc'
--exec sp_change_users_login 'Auto_fix', 'ReconcilorAdmin'
--Go

