ActiveRecord::Schema.define(:version => 1) do
  create_table "posts", :force => true do |t|
    t.integer "owner_id"
    t.boolean "public"
    t.string  "title"
  end

  create_table "comments", :force => true do |t|
    t.integer "post_id"
    t.string  "text"
  end

  create_table "users", :force => true do |t|
    t.boolean "admin"
  end
end
