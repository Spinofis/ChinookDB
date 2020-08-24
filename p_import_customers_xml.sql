USE [Chinook]
GO

/****** Object:  StoredProcedure [dbo].[p_import_customers_xml]    Script Date: 24.08.2020 21:00:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[p_import_customers_xml]
@directory varchar(max)='C:\Users\Bartek\Desktop\customers*.xml'
as
begin

declare @files table (id int identity(1,1),full_path varchar(500))
declare @xml_files_paths XML
declare @xml_customers XML
declare @hdoc int
declare @i int
declare @i_max int
declare @customers_filepath varchar(max)
declare @command nvarchar(max)
declare @max_id int

EXEC [dbo].p_list_path_xml @directory, @xml_files_paths output

exec sp_xml_preparedocument  @hdoc output,@xml_files_paths

insert into @files(full_path)
select fullpath
from openxml(@hdoc,'/files/file',2)
with(fullpath varchar(500))

exec sp_xml_removedocument @hdoc

select @i=1,@i_max=max(id) from @files
while @i<=@i_max
begin
	set @customers_filepath=(select full_path from @files where id=@i)
	set @command='select @xml_customers1=c
		from openrowset(bulk '''+@customers_filepath+''',single_blob) as customers(c)'
	exec sp_executesql @command,N'@xml_customers1 XML output',@xml_customers1 =@xml_customers output

	exec sp_xml_preparedocument @hdoc output,@xml_customers

	set @max_id=(select max(CustomerId) from Customer)

	select 
		(row_number() over(order by c.CustomerId))+@max_id as CustomerId,
		c.FirstName,
		c.LastName,
		c.Company,
		c.[Address],
		c.City,
		c.State,
		c.Country,
		c.PostalCode,
		c.Phone,
		c.Fax,
		c.Email,
		c.SupportRepId
	into #customers
	from openxml(@hdoc,'/customers/customer',2)
	with
	(
		CustomerId int,
		FirstName nvarchar(40),
		LastName nvarchar(20),
		Company nvarchar(80),
		[Address] nvarchar(70),
		City nvarchar(40),
		State nvarchar(40),
		Country nvarchar(40),
		PostalCode nvarchar(10),
		Phone nvarchar(24),
		Fax nvarchar(24),
		Email nvarchar(60),
		SupportRepId int
	) c


	merge Customer as target
	using #customers as source
	on target.Email=source.Email
	when matched then 
		update set 
			target.FirstName=source.FirstName,
			target.LastName=source.LastName,
			target.Company=source.Company,
			target.[Address]=source.[Address],
			target.City=source.City,
			target.[State]=source.[State],
			target.Country=source.Country,
			target.PostalCode=source.PostalCode,
			target.Phone=source.Phone,
			target.Fax=source.Fax,
			target.Email=source.Email,
			target.SupportRepId=source.SupportRepId
	when not matched by target then
		insert (
			CustomerId,
			FirstName,
			LastName,
			Company,
			[Address],
			City,
			State,
			Country,
			PostalCode,
			Phone,
			Fax,
			Email,
			SupportRepId 
		)
		values 
		(
			source.CustomerId,
			source.FirstName,
			source.LastName,
			source.Company,
			source.[Address],
			source.City,
			source.State,
			source.Country,
			source.PostalCode,
			source.Phone,
			source.Fax,
			source.Email,
			source.SupportRepId 
		)
	;

	
	set @i=@i+1

	drop table #customers
end

end
GO

