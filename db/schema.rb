# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_12_04_041631) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "buildings", primary_key: "ogc_fid", id: :serial, force: :cascade do |t|
    t.geometry "wkb_geometry", limit: {:srid=>4326, :type=>"geometry"}
    t.string "building_levels"
    t.string "height"
    t.string "name"
    t.string "type_"
    t.string "building:part"
    t.string "roof:colour"
    t.string "roof:material"
    t.string "roof_shape"
    t.string "wheelchair"
    t.string "amenity"
    t.string "alt_name"
    t.string "roof:levels"
    t.string "name:en"
    t.string "short_name"
    t.string "min_height"
    t.string "construction_date"
    t.string "official_name"
    t.string "roof:height"
    t.string "roof:orientation"
    t.string "roof:direction"
    t.string "building_height"
    t.string "level"
    t.string "access"
    t.string "building_min_level"
    t.string "parking"
    t.string "aeroway"
    t.string "building:level"
    t.string "max_level"
    t.string "min_level"
    t.string "building_max_level"
    t.string "usage"
    t.string "area"
    t.index ["wkb_geometry"], name: "buildings_wkb_geometry_geom_idx", using: :gist
  end

end
