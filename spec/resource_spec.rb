require 'spec_helper'

describe EntityController, :type => :controller do
  before(:all) do
    @john    = User.create!   :admin => false
    @admin   = User.create!   :admin => true
    @public  = Entity.create! :name => 'ent1', :public => false
    @private = Entity.create! :name => 'ent1', :public => true, :owner_id => @john.id
  end

  describe "shows everything to admin" do
    it "showws everything to the admin" do
      User.mock @admin
      get :index

      assigns(:entities).count.should == 2
    end

    it "hides non-public entities" do
      User.mock @john
      get :index

      assigns(:entities).count.should == 1
    end

    it "allows creation for admin" do
      User.mock @admin
      post :create, {}

      assigns(:entity).should == {}
    end
  end
end