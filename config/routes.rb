Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root :to => redirect('/map/show')
  get 'map/show'
  get 'map/heatmap_camera_update'
  get 'map/amenity_search'
  get 'map/test_sun_occlusion'
  get 'map/buildings_for_polygon'
end
