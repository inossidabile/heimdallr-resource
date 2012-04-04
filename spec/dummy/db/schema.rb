ActiveRecord::Schema.define(:version => 1) do
  create_table "entities", :force => true do |t|
    t.integer "owner_id"
    t.string  "name"
    t.boolean "public"
  end

  create_table "users", :force => true do |t|
    t.boolean "admin"
  end
end
