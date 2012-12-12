require 'spec_helper'

describe ThingsController, :type => :controller do
  before(:all) do
    User.delete_all
    Entity.delete_all

    @admin = User.create! :admin => true

    @entity1 = Entity.create! :name => 'entity 1'
    @entity2 = Entity.create! :name => 'entity 2'

    @thing1 = Thing.create! :name => 'thing 1', :entity_id => @entity1.id
    @thing2 = Thing.create! :name => 'thing 2', :entity_id => @entity1.id
    @thing3 = Thing.create! :name => 'thing 3', :entity_id => @entity2.id
  end

  it "loads entity resource and assigns to @entity" do
    User.mock @admin
    get :index, :entity_id => @entity1.id

    assigns(:entity).id.should == @entity1.id
  end

  it "loads thing resources through @entity and assigns to @things" do
    User.mock @admin
    get :index, :entity_id => @entity1.id

    assigns(:things).should have(2).items
  end
end