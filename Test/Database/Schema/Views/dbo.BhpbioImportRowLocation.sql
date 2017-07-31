
IF Object_Id('dbo.BhpbioImportRowLocation') IS NOT NULL
	DROP VIEW dbo.BhpbioImportRowLocation
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[BhpbioImportRowLocation]
AS
SELECT
	[RootImportSyncRowId],
	[ImportSyncRowId],
	B.Location_Id,
	B.SiteLocationId
FROM 

		--Sample structure of the XML. Note the tag Site and Pit.
		--<BlockModelSource>
		--  <BlastModelBlockWithPointAndGrade>
		--    <Site>YANDI</Site>
		--    <Orebody>YN</Orebody>
		--    <Pit>C1</Pit>
		--    <Bench>0522</Bench>
		--    <PatternNumber>0368</PatternNumber>
		--    <BlockName>1</BlockName>
		--    <ModelName>Geology</ModelName>
		--    <ModelOreType>HSHA</ModelOreType>
		--    <BlockNumber>0</BlockNumber>
		--    <BlockedDate>2008-05-28T06:54:52</BlockedDate>
		--    <BlastedDate>1900-01-01T00:00:00</BlastedDate>
		--    <CentroidEasting>14731.21</CentroidEasting>
		--    <CentroidNorthing>86392.42</CentroidNorthing>
		--    <CentroidRL>528</CentroidRL>
		--    <ModelTonnes>11075</ModelTonnes>
		--    <LastModifiedUser>riddp1</LastModifiedUser>
		--    <LastModifiedDate>2008-05-28T07:47:26</LastModifiedDate>
		--    <Grade>&lt;Grade&gt;&lt;row&gt;&lt;GradeName&gt;al2o3&lt;/GradeName&gt;&lt;GradeValue&gt;1.725000000000000e+000&lt;/GradeValue&gt;&lt;/row&gt;&lt;row&gt;&lt;GradeName&gt;fe&lt;/GradeName&gt;&lt;GradeValue&gt;5.755000000000000e+001&lt;/GradeValue&gt;&lt;/row&gt;&lt;row&gt;&lt;GradeName&gt;loi&lt;/GradeName&gt;&lt;GradeValue&gt;1.068900000000000e+001&lt;/GradeValue&gt;&lt;/row&gt;&lt;row&gt;&lt;GradeName&gt;p&lt;/GradeName&gt;&lt;GradeValue&gt;4.700000000000000e-002&lt;/GradeValue&gt;&lt;/row&gt;&lt;row&gt;&lt;GradeName&gt;sio2&lt;/GradeName&gt;&lt;GradeValue&gt;5.670000000000000e+000&lt;/GradeValue&gt;&lt;/row&gt;&lt;row&gt;&lt;GradeName&gt;Density&lt;/GradeName&gt;&lt;GradeValue&gt;3.065000000000000e+000&lt;/GradeValue&gt;&lt;/row&gt;&lt;/Grade&gt;</Grade>
		--  </BlastModelBlockWithPointAndGrade>
		--</BlockModelSource>

	(SELECT 
		[RootImportSyncRowId],
		[ImportSyncRowId],
		SourceRow.query('/BlockModelSource/BlastModelBlockWithPointAndGrade/Site').value('.','varchar(31)') AS SiteName,
		SourceRow.query('/BlockModelSource/BlastModelBlockWithPointAndGrade/Pit').value('.','varchar(31)') AS PitName
	FROM ImportSyncRow) AS A

INNER JOIN 

	(SELECT 
		L1.Location_Id,
		L1.Parent_Location_Id as SiteLocationId,
		L1.Name AS PitName,
		L2.Name AS SiteName 
	FROM [dbo].[Location] L1 
		INNER JOIN [dbo].[Location] L2 ON
		L1.Parent_Location_Id = L2.Location_Id
	WHERE 
		L1.Location_Type_Id=4 --PIT
		AND 
		L2.Location_Type_Id=3 --SITE
		) AS B


ON A.PitNAme=B.PitName AND A.SiteName= B.SiteName


GO
