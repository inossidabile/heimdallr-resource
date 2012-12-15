class Post < ActiveRecord::Base
  include Heimdallr::Model

  has_many :comments, :dependent => :destroy

  restrict do |user, record|
    if user.admin
      scope :fetch
      scope :delete
      can [:view, :create, :update]
    else
      scope :fetch,  -> { where('public = ? or owner_id = ?', true, user.id) }
      scope :delete, -> { where('owner_id = ?', user.id) }
    end
  end
end