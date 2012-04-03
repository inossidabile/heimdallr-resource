class EntityController < ApplicationController
  include Heimdallr::Resource

  load_and_authorize_resource

  def index
    render :nothing => true
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end
end