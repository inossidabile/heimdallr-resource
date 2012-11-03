require 'spec_helper'

describe FluffiesController, :type => :controller do
  before(:all) do
    User.delete_all
    Entity.delete_all

    @admin = User.create! :admin => true

    @entity1 = Entity.create! :name => 'entity 1'
    @entity2 = Entity.create! :name => 'entity 2'
  end

  it "loads entity resources and assigns to @entities" do
    User.mock @admin
    get :index

    assigns(:entities).should have(2).items
  end
end