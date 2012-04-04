class User < ActiveRecord::Base
  class << self
    attr_accessor :current
  end

  def self.mock(what)
    if what == :admin
      @current = User.new(admin: true)
    else
      @current = User.new(admin: false)
    end
  end
end