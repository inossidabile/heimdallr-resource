require 'spec_helper'

describe EntityController, :type => :controller do
  before(:all) do
    @john    = User.create!   :admin => false
    @maria   = User.create!   :admin => false
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

      assigns(:entity).should be_kind_of Heimdallr::Proxy::Record
    end

    it "disallows creation for non-admin" do
      User.mock @john
      expect { post :create, {} }.should raise_error
    end

    it "allows update for admin" do
      User.mock @admin
      post :update, {:id => 1}

      assigns(:entity).should be_kind_of Heimdallr::Proxy::Record
      assigns(:entity).id.should == 1
    end

    it "disallows update for non-admin" do
      User.mock @john
      expect { post :update, {:id => 2} }.should raise_error
    end

    it "allows destroy for admin" do
      User.mock @admin
      post :destroy, {:id => 1}

      assigns(:entity).should be_kind_of Heimdallr::Proxy::Record
      assigns(:entity).id.should == 1
    end

    it "allows destroy for owner" do
      User.mock @john
      post :destroy, {:id => 2}

      assigns(:entity).should be_kind_of Heimdallr::Proxy::Record
      assigns(:entity).id.should == 2
    end

    it "disallows destroy for nobody" do
      User.mock @maria
      expect { post :destroy, {:id => 2} }.should raise_error
    end
  end
end