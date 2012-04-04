class User < ActiveRecord::Base
  class << self
    attr_accessor :current
  end

  def self.mock(user)
    @current = user
  end
end