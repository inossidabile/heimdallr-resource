class Comment < ActiveRecord::Base
  include Heimdallr::Model

  belongs_to :post

  restrict do |user, record|
    scope :fetch
    scope :delete
    can [:view, :create, :update]
  end
end
