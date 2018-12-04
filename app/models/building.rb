class Building < ApplicationRecord
  def build_geojson
    geojson=  '{
        "type": "Feature",
        "geometry": '+RGeo::GeoJSON.encode(self.wkb_geometry).to_s.gsub('=>' , ':') +',
        "properties": {
          "id": '+self.ogc_fid.to_json+',
          "height": '+self.get_height(self.height, self.building_levels).to_s+',
          "min_height":'+ self.get_height(self.min_height, self.building_min_level).to_s+'
        }
      }'
  end

  def get_height(si, buzerant)
    if si
      return si
    end
    if buzerant
      return ((buzerant.to_f)*2.5)
    end
    return 0
  end
end
