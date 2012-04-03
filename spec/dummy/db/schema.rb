ActiveRecord::Schema.define(:version => 1) do
  create_table "entities", :force => true do |t|
    t.string "name"
  end
end
