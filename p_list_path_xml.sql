USE [Chinook]
GO

/****** Object:  StoredProcedure [dbo].[p_list_path_xml]    Script Date: 24.08.2020 21:00:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[p_list_path_xml]
	@path varchar(500),
	@xml_files_list XML output
as
begin
	declare @dir_files table (id int identity(1,1),fullpath varchar(500))
	declare @cmd varchar(2000)='dir ' + @path+'/B /S'
	insert into @dir_files(fullpath)
	exec xp_cmdshell @cmd

	set @xml_files_list=
	(
		select fullpath 
		from @dir_files
		where fullpath is not null
		for xml path('file'),
			root('files')
	)
end
GO

