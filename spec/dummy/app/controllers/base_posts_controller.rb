class BasePostsController < ApplicationController
  include Heimdallr::Resource

  load_and_authorize_resource :resource => :post

  before_filter do
    # This filter could access @post and do something with it in a real app,
    # but here it just gets saved in a variable for the testing purpose.
    @loaded_by_base_post = @post
  end

  attr_reader :loaded_by_base_post
end
