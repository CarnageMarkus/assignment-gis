class MapController < ApplicationController
  def show
    @buldings = Building.where("building_levels IS NOT NULL OR height IS NOT NULL").limit(2000)
    @geojson = '{ "type": "FeatureCollection", "features": ['
    @buldings.each.with_index do |b, index|
      @geojson << b.build_geojson.to_s.gsub('\n', '')
      if(index < (@buldings.size-1))
        @geojson<< ','
      end
    end
    @geojson << ']}'
  end
end
