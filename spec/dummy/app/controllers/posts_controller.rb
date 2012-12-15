class PostsController < ApplicationController
  include Heimdallr::Resource

  load_and_authorize_resource

  def index
    render :nothing => true
  end

  def show
    render :nothing => true
  end

  def new
    render :nothing => true
  end

  def create
    render :nothing => true
  end

  def edit
    render :nothing => true
  end

  def update
    render :nothing => true
  end

  def destroy
    render :nothing => true
  end

  def hide
    render :nothing => true
  end
end
