CREATE OR REPLACE FUNCTION mlws.do_osm_reverse_geocode(latitude double precision, longitude double precision)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
  DECLARE
  latitude ALIAS FOR $1;
  longitude ALIAS FOR $2;
  
  addr mlws.poi_info;
  roaddst mlws.poi_info;  
  binfo mlws.boundary_info;
  
  tmp TEXT;
  rc TEXT := '';

  admcur NO SCROLL CURSOR (lon double precision, lat double precision) FOR SELECT place,name,admin_level  
  FROM multipolygons AS boundary WHERE ST_Contains(boundary.wkb_geometry, ST_SetSRID(ST_Point(lon, lat),4326)) = 't'
  ORDER BY admin_level DESC;

  address_search_radius CONSTANT DOUBLE PRECISION := 0.001;
  road_search_radius CONSTANT DOUBLE PRECISION := 0.0023;

  address_hysteresis CONSTANT INT = 20;
  road_hysteresis CONSTANT INT = 20;

BEGIN
---------------------
-- ADDRESS PROCESSING
---------------------
SELECT
 (other_tags->'addr:street') || ' ' ||
 (other_tags->'addr:housenumber'),
 round(ST_DistanceSpheroid(b.wkb_geometry, loc.geom, 'SPHEROID["WGS 84",6378137,298.257223563]')) AS distance,
 ST_ClosestPoint(b.wkb_geometry, ST_SetSRID(ST_Point(longitude, latitude),4326))
 INTO addr
 FROM multipolygons b
 INNER JOIN (SELECT ST_SetSRID(ST_Point(longitude, latitude),4326) AS geom) AS loc ON ST_DWithin(b.wkb_geometry, loc.geom, address_search_radius)
 WHERE other_tags->'addr:street' IS NOT NULL 
   AND other_tags->'addr:housenumber' IS NOT NULL
   AND building <> ''
 ORDER BY distance 
 LIMIT 1; 

 IF addr.name IS NOT NULL AND addr.name <> ''
 THEN
   IF addr.distance > address_hysteresis THEN
     rc = addr.name || ' (' || addr.distance || 'м)';
   ELSE 
     rc = addr.name;
   END IF;
 ELSE
-------------------
-- ROAD PROCESSING
-------------------
   SELECT 
   COALESCE(other_tags->'ref', '') 
   || 
   CASE WHEN other_tags->'ref' IS NULL THEN name
   ELSE ' ' || name
   END,
   round(ST_DistanceSpheroid(road.wkb_geometry, ST_SetSRID(ST_Point(longitude, latitude), 4326), 'SPHEROID["WGS 84",6378137,298.257223563]')) AS distance,
   ST_ClosestPoint(road.wkb_geometry, ST_SetSRID(ST_Point(longitude, latitude),4326))
   INTO roaddst
   FROM multilinestrings road 
   INNER JOIN (SELECT ST_SetSRID(ST_Point(longitude, latitude),4326) AS geom) AS loc ON ST_DWithin(road.wkb_geometry, loc.geom, road_search_radius)
   WHERE name IS NOT NULL
--    AND highway <> ''
   AND (other_tags->'route' = 'road')
   AND (other_tags->'network' like 'ru%')
   OR  (other_tags->'network' = '') 
   ORDER BY distance 
   LIMIT 1;

   IF roaddst.name IS NOT NULL AND roaddst.name <> ''
     THEN
       IF roaddst.distance > road_hysteresis THEN
        rc =  roaddst.name || ' (' || roaddst.distance || 'м)';
       ELSE 
        rc = roaddst.name;
       END IF;     
   END IF;
  END IF;

 OPEN admcur (lon:=longitude, lat:=latitude);
 LOOP
   FETCH admcur INTO binfo;
   EXIT WHEN NOT FOUND;

   tmp = '';
   IF binfo.place <> '' THEN
     CASE binfo.place
       WHEN 'city' THEN tmp ='г';
       WHEN 'village' THEN tmp ='д';
       WHEN 'locality' THEN tmp ='рн';
       WHEN 'town' THEN tmp ='г';
       WHEN 'hamlet' THEN tmp ='п';
     ELSE
       tmp = binfo.place;
     END CASE;
          
     rc = COALESCE(rc,'') || ',' || tmp;   
     rc = COALESCE(rc,'') || ' ' || binfo.name;
   END IF;
   
   IF binfo.level <> '1'
     AND binfo.level <> '2'
     AND binfo.level <> '3'
     AND binfo.level <> '5' THEN
       rc = COALESCE(rc,'') || ',' || binfo.name;
   END IF;
 END LOOP;

 CLOSE admcur;

 rc = COALESCE(trim (leading ',' from trim (both ' ' from rc)),'');

 -- INSERT INTO stats.geoquerylog(geom, name) VALUES (st_setsrid(st_makepoint(longitude,latitude), 4326),rc);
 
 RETURN rc;
END;
$function$
