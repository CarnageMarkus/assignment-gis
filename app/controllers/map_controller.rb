require 'sun_calc'
require 'date'
class MapController < ApplicationController
  def show
    @camera_lng = params['lng'] || -73.985130
    @camera_lat = params['lat'] || 40.758896
    @camera_zoom = params['zoom'] || 15.5
    @camera_pitch = 45
    @camera_bearing = -17.6
    @building_geojson = self.buildings_for_point(@camera_lng, @camera_lat, 600)
    @building_centroids = self.build_centroids
    @amenity = Building.distinct.where.not(amenity: nil).pluck(:amenity)
    @amenity_buildings = {}
    @sun_locations = {}
    @intersection = {}
    # @sun_times = SunCalc.sun_position(Time.now, 59.3345, 18.0662)
  end

  def heatmap_camera_update
    lng = params['lng'].to_f
    lat = params['lat'].to_f
    dist = params['dist'].to_f
    dist = (dist*1000).clamp(100,10000).round
    @geojson = self.buildings_for_point(lng, lat, dist)

    respond_to do |format|
      format.html
      format.json { render json: @geojson }  # respond with the created JSON object
    end
  end

  def buildings_for_biulding(bid, dist)
    buildings = Building.find_by_sql(
    "SELECT b2*
    FROM buildings as b, buildings as b2
    WHERE b.ogc_fid = #{bid }
    AND b.ogc_fid != b2.ogc_fid
    AND ST_DWITHIN (b.wkb_geometry::geography, b2.wkb_geometry::geography, #{dist});")
    self.buildings_to_geo_json(buildings)
  end

  def buildings_for_point(lng, lat, dist)
    #@buldings = Building.where("building_levels IS NOT NULL OR height IS NOT NULL").limit(2000)
    buildings = Building.find_by_sql(
    "SELECT *
    FROM buildings b
    WHERE ST_DWithin (b.wkb_geometry::geography,ST_MakePoint(#{lng}, #{lat})::geography, #{dist}, false);")
    self.buildings_to_geo_json(buildings)
  end

  def buildings_to_geo_json(buildings)
    geojson = '{ "type": "FeatureCollection", "features": ['
    buildings.each.with_index do |b, index|
      geojson << b.build_geojson.to_s.gsub('\n', '')
      if(index < (buildings.size-1))
        geojson<< ','
      end
    end
    geojson << ']}'
  end

  def buildings_for_intersection(geometry)
    buildings = Building.find_by_sql(
        "SELECT b.*
    FROM buildings b
    WHERE
    ST_Intersects(b.wkb_geometry::geography,ST_GeomFromGeoJSON(#{geometry})::geography)")
    self.buildings_to_geo_json(buildings)
  end

  def buildings_for_polygon
    geom = params['geom'].to_s.gsub('=>',':')
    @intersection = self.buildings_for_intersection(geom)
    respond_to do |format|
      format.html
      format.json { render json: @intersection }  # respond with the created JSON object
    end
  end

  def buildings_by_amenity(lng, lat, dist, amenity)
    police = Building.find_by_sql(
        "SELECT *
    FROM buildings b
    WHERE b.amenity='#{amenity}' AND  ST_DWithin (b.wkb_geometry::geography,ST_MakePoint(#{lng}, #{lat})::geography, #{dist}, false);")
    self.buildings_to_geo_json(police)
  end

  def amenity_search
    lng = params['lng'].to_f
    lat = params['lat'].to_f
    dist = params['dist'].to_f
    amenity = params['amenity'].to_s
    @amenity_buildings = buildings_by_amenity(lng, lat, dist, amenity)

    respond_to do |format|
      format.html
      format.json { render json: @amenity_buildings }  # respond with the created JSON object
    end
  end

  def test_sun_occlusion
    lng = params['lng'].to_f
    lat = params['lat'].to_f
    #dist = params['dist'].to_f
    #dist = 2000

    @sun_locations = sun_occlusion_for(lat,lng)

    respond_to do |format|
      format.html
      format.json { render json: @sun_locations }  # respond with the created JSON object
    end
  end

  def sun_occlusion_for(lat,lng)
    sun_locations = []
    northAzimuthOffset = Math::PI * 3/4
    #1.upto(11) do |month|
      0.upto(23) do |hour|
        now = Time.now
        date = DateTime.new(now.year, now.month, 20, hour,0,0, Rational(-5,24))
        loc = SunCalc.sun_position(date,lat,lng)
        loc[:azimuth] = ((loc[:azimuth] + northAzimuthOffset) * 180) / Math::PI
        loc[:altitude] = (loc[:altitude] * 180) / Math::PI
        sun_locations.push(loc)
      end
    #end

    daylight_azimuths = []
    sun_locations.each { |x| if x[:altitude] > 0 then daylight_azimuths.push(x[:azimuth]) end }
    daylight_azimuths.sort_by { |number| -number }
    daylight_polygon = []
    daylight_polygon.push([lng,lat])
    daylight_azimuths.each do |x|
      xoff = Math::sin(x * Math::PI / 180 )
      yoff = Math::cos(x * Math::PI / 180 )
      coords = [self.offset_lng(lng,lat,200* xoff),self.offset_lat(lat,200 * yoff)]
      daylight_polygon.push(coords)
    end
    daylight_polygon.push([lng,lat])

    daylight_geojson = {
        "type": "Feature",
        "geometry": {
          "type": "Polygon",
          "coordinates":[ daylight_polygon
        ]},
        "properties": {
          "id": "2"
        }
      }

    geometry = {
        "type": "Polygon",
        "coordinates":[ daylight_polygon ]
    }
    geom = '\'' + geometry.to_json.to_s + '\''
    @intersection = self.buildings_for_intersection(geom)

    sunlightdata = { 'hourly':sun_locations, 'daylight':daylight_azimuths, daylight_geo: daylight_geojson, buildings: @intersection.to_s.gsub('=>',':')  }

    sunlightdata.to_json
  end

  EARTH_RADIUS=6378137

  def offset_lng(lng, lat, meters)
    lng + (meters/(EARTH_RADIUS*Math::cos(Math::PI*lat/180))) * 180/Math::PI
  end

  def offset_lat(lat, meters)
    lat + (meters/EARTH_RADIUS) * 180/Math::PI
  end

  # build id -> centroid cache
  def build_centroids
    #sql = "SELECT b.ogc_fid as id, ST_AsGeoJSON(ST_centroid(b.wkb_geometry)) as geo FROM buildings b"
    sql = "SELECT b.ogc_fid as id,
                  st_x(st_transform(ST_Centroid(b.wkb_geometry),4326)) as lng,
                  st_y(st_transform(ST_Centroid(b.wkb_geometry),4326)) as lat
           FROM buildings b;"
    result_set = ActiveRecord::Base.connection.execute(sql)
    results = {}

    result_set.each do |row|
      results[row['id']] = [row['lng'],row['lat']]
    end
    results
  end
end