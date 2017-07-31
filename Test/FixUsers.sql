exec sp_change_users_login 'Auto_fix', 'ReconcilorUI' 
exec sp_change_users_login 'Auto_fix', 'ReconcilorEngine' 
exec sp_change_users_login 'Auto_fix', 'ReconcilorImport' 
exec sp_change_users_login 'Auto_fix', 'ReconcilorReport' 
exec sp_change_users_login 'Auto_fix', 'ReconcilorRecalc' 
exec sp_change_users_login 'Auto_fix', 'ReconcilorAdmin'
exec sp_change_users_login 'Auto_fix', 'ReconcilorSupport'

insert into SecurityUser (NTAccountName, IsActive, FirstName, LastName) values ('SNOWDEN\gpattenden', 1, 'Gary', 'Pattenden')
insert into SecurityUser (NTAccountName, IsActive, FirstName, LastName) values ('SNOWDEN\dandrade', 1, 'Daniel', 'Andrade')
insert into SecurityUser (NTAccountName, IsActive, FirstName, LastName) values ('SNOWDEN\jclaughton', 1, 'Jennifer', 'Claughton')

insert into SecurityRoleAssignment (UserId, RoleId)
select su.UserId, 'REC_ADMIN'
from SecurityUser su
left join SecurityRoleAssignment sra
	on su.UserId = sra.UserId
	and sra.RoleId = 'REC_ADMIN'
where su.NTAccountName like 'SNOWDEN%'

