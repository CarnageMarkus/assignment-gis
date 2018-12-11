-- fix invalid geometry
UPDATE buildings 
SET wkb_geometry = ST_MakeValid(wkb_geometry) 
WHERE NOT ST_IsValid(wkb_geometry);

UPDATE buildings 
SET wkb_geometry = ST_Multi(ST_Simplify(ST_Multi(ST_CollectionExtract(ST_ForceCollection(ST_MakeValid(wkb_geometry)),3)),0))
WHERE ST_GeometryType(wkb_geometry) = 'ST_GeometryCollection';

DELETE FROM buildings 
WHERE wkb_geometry IS NULL;
																									  
UPDATE buildings 
SET wkb_geometry = ST_Multi(ST_Simplify(wkb_geometry,0));
										
UPDATE buildings 
SET wkb_geometry = ST_Multi(ST_Buffer(wkb_geometry,0))
WHERE NOT ST_IsValid(wkb_geometry);
									  
-- find non numeric row in column									  
select wkb_geometry,type_,ogc_fid, height, min_height, building_levels, building_min_level, roof_shape 
	from  buildings 									  
	WHERE min_height !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$'

-- fix some non numeric row
select wkb_geometry,type_, building, height, min_height, building_levels, building_min_level, building_part, roof_shape 
	from  buildings 
	where ogc_fid = 776
									  
UPDATE buildings SET min_height=5
    where ogc_fid = 776

-- see how many nulls are in the column
SELECT
   count(1) as TotalAll,
   count(building) as TotalNotNull,
   count(1) - count(building) as TotalNull,
   100.0 * count(building) / count(1) as PercentNotNull
FROM
   manhattanbuildings
									  


-- detect overlaps
SELECT *
FROM buildings a
INNER JOIN manhattanbuildings b ON 
   (a.wkb_geometry && b.wkb_geometry AND ST_Relate(a.wkb_geometry, b.wkb_geometry, '2********'))
WHERE a.ogc_fid != b.ogc_fid
LIMIT 1
												   
-- Basic data selects...
select wkb_geometry,type_, building, height, building_levels, building_min_level, building_part, roof_shape 
	from  buildings 
	where building_levels
		IS NOT NULL OR height IS NOT NULL

select * from buildings
