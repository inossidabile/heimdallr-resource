class Thing < ActiveRecord::Base
  include Heimdallr::Model

  belongs_to :entity

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