class EntityController < ApplicationController
  include Heimdallr::Resource

  load_and_authorize_resource

  def index
    render :nothing => true
  end

  def new
    render :nothing => true
  end

  def create
    @entity.create!(params[:entity])

    render :nothing => true
  end

  def edit
    render :nothing => true
  end

  def update
    @entity.update_attributes!(params[:entity])

    render :nothing => true
  end

  def destroy
    @entity.delete

    render :nothing => true
  end
end