class Entity < ActiveRecord::Base
  include Heimdallr::Model

  restrict do |context, record|
    scope :fetch
  end
end