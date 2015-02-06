# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150203072202) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "authentications", force: true do |t|
    t.string   "client_id",                 null: false
    t.string   "client_secret",             null: false
    t.string   "redirect_uri",              null: false
    t.string   "access_token"
    t.integer  "client_count",  default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
    t.string   "password"
  end

  create_table "cities", force: true do |t|
    t.string   "name"
    t.string   "code"
    t.integer  "time_zone"
    t.text     "suggest_bounds"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "detect_results", force: true do |t|
    t.integer  "media_instagram_id"
    t.integer  "age_range"
    t.integer  "age_value"
    t.float    "gender_conf"
    t.string   "gender_value"
    t.float    "race_conf"
    t.string   "race_value"
    t.float    "smiling"
    t.float    "pitch_angle"
    t.float    "roll_angle"
    t.float    "yaw_angle"
    t.float    "center_x"
    t.float    "center_y"
    t.float    "width"
    t.float    "height"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "media_instagrams", force: true do |t|
    t.string   "url"
    t.string   "media_type"
    t.text     "tags"
    t.integer  "comment_count"
    t.datetime "created_time"
    t.string   "location_id"
    t.string   "location_name"
    t.float    "lat"
    t.float    "lng"
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "filter_tags"
    t.string   "media_id"
    t.integer  "time_zone",     default: 0
  end

  add_index "media_instagrams", ["created_time"], name: "index_media_instagrams_on_created_time", using: :btree
  add_index "media_instagrams", ["media_id"], name: "index_media_instagrams_on_media_id", unique: true, using: :btree

  create_table "media_searches", force: true do |t|
    t.float    "lat"
    t.float    "lng"
    t.integer  "max_time"
    t.integer  "min_time"
    t.integer  "status",           default: 0
    t.integer  "media_count",      default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "search_area_id"
    t.text     "media_timestamps"
    t.integer  "time_zone",        default: 0
  end

  add_index "media_searches", ["lat", "lng", "max_time", "min_time"], name: "media_searches_unique_index", unique: true, using: :btree

  create_table "search_areas", force: true do |t|
    t.float    "lat"
    t.float    "lng"
    t.integer  "cycle",            default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "last_searched_at", default: 0
    t.integer  "time_zone",        default: 0
    t.text     "statistics"
    t.integer  "city_id"
  end

  add_index "search_areas", ["lat", "lng"], name: "index_search_areas_on_lat_and_lng", unique: true, using: :btree

end
