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

ActiveRecord::Schema.define(version: 20150603094657) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bots", force: true do |t|
    t.string   "name"
    t.string   "role"
    t.integer  "wallet",     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password"
    t.string   "status"
  end

  create_table "magic_accounts", force: true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.integer  "tickets_depositing",  default: 0
    t.integer  "tickets_withdrawing", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "magic_accounts", ["user_id"], name: "index_magic_accounts_on_user_id", using: :btree

  create_table "magic_blocks", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "magic_blocks", ["name"], name: "index_magic_blocks_on_name", unique: true, using: :btree

  create_table "magic_cards", force: true do |t|
    t.integer  "mtgo_id"
    t.string   "object_type"
    t.string   "name"
    t.string   "plain_name"
    t.integer  "magic_set_id"
    t.string   "rarity"
    t.boolean  "foil",             default: false
    t.string   "collector_number"
    t.string   "art_version",      default: "default"
    t.boolean  "disabled",         default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "magic_cards", ["magic_set_id"], name: "index_magic_cards_on_magic_set_id", using: :btree
  add_index "magic_cards", ["mtgo_id"], name: "index_magic_cards_on_mtgo_id", unique: true, using: :btree
  add_index "magic_cards", ["name"], name: "index_magic_cards_on_name", using: :btree
  add_index "magic_cards", ["object_type"], name: "index_magic_cards_on_object_type", using: :btree
  add_index "magic_cards", ["plain_name"], name: "index_magic_cards_on_plain_name", using: :btree

  create_table "magic_sets", force: true do |t|
    t.string   "name"
    t.string   "code"
    t.integer  "magic_block_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "magic_sets", ["code"], name: "index_magic_sets_on_code", unique: true, using: :btree
  add_index "magic_sets", ["name"], name: "index_magic_sets_on_name", unique: true, using: :btree

  create_table "stocks", force: true do |t|
    t.integer  "user_id"
    t.integer  "magic_account_id"
    t.integer  "bot_id"
    t.integer  "magic_card_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stocks", ["user_id", "magic_card_id"], name: "index_stocks_on_user_id_and_magic_card_id", using: :btree

  create_table "trade_queues", force: true do |t|
    t.integer  "magic_account_id"
    t.integer  "runner_id"
    t.integer  "bank_id"
    t.string   "status"
    t.text     "history"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transactions", force: true do |t|
    t.integer  "buyer_id"
    t.integer  "seller_id"
    t.integer  "stock_id"
    t.integer  "magic_card_id"
    t.decimal  "price",         precision: 15, scale: 3
    t.datetime "start"
    t.datetime "finish"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transactions", ["buyer_id", "status"], name: "index_transactions_on_buyer_id_and_status", using: :btree
  add_index "transactions", ["magic_card_id", "status", "price"], name: "index_transactions_on_magic_card_id_and_status_and_price", using: :btree
  add_index "transactions", ["seller_id", "status"], name: "index_transactions_on_seller_id_and_status", using: :btree

  create_table "users", force: true do |t|
    t.string   "account_status",                             default: "active"
    t.string   "email"
    t.string   "password_digest"
    t.string   "confirmation_code"
    t.boolean  "confirmed",                                  default: false
    t.string   "user_code"
    t.string   "bot_code"
    t.integer  "bot_id"
    t.decimal  "wallet",            precision: 15, scale: 3, default: 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

end
