require 'spec_helper'

describe FluffiesController, :type => :controller do
  before(:all) do
    @john    = User.create!   :admin => false
    @maria   = User.create!   :admin => false
    @admin   = User.create!   :admin => true
    @private = Entity.create! :name => 'ent1', :public => false
    @public  = Entity.create! :name => 'ent1', :public => true, :owner_id => @john.id
  end

  after(:all) do
    Entity.delete_all
  end

  it "accepts load_and_authorize_resource params" do
    User.mock @admin
    get :index

    assigns(:entities).count.should == 2
  end
end