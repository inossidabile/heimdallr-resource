require 'spec_helper'

describe EntityController, :type => :controller do
  before(:all) do
    @john    = User.create!   :admin => false
    @maria   = User.create!   :admin => false
    @admin   = User.create!   :admin => true
    @private = Entity.create! :name => 'ent1', :public => false
    @private_own = Entity.create! :name => 'ent1', :public => false, :owner_id => @john.id
    @public  = Entity.create! :name => 'ent1', :public => true, :owner_id => @john.id
  end

  describe "CRUD" do
    it "shows everything to the admin" do
      User.mock @admin
      get :index

      assigns(:entities).count.should == 3
    end

    it "hides non-public entities" do
      User.mock @john
      get :index

      assigns(:entities).count.should == 2
    end

    it "shows private to owner" do
      User.mock @john
      get :show, {:id => @private_own.id}

      assigns(:entity).insecure.should == @private_own
    end

    it "hides private from non-owner" do
      User.mock @maria

      expect { get :show, {:id => @private_own.id} }.should raise_error
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
      post :update, {:id => @private.id}

      assigns(:entity).should be_kind_of Heimdallr::Proxy::Record
      assigns(:entity).id.should == @private.id
    end

    it "disallows update for non-admin" do
      User.mock @john
      expect { post :update, {:id => @public.id} }.should raise_error
    end

    it "allows destroy for admin" do
      User.mock @admin
      post :destroy, {:id => @private.id}

      assigns(:entity).should be_kind_of Heimdallr::Proxy::Record
      assigns(:entity).id.should == @private.id
    end

    it "allows destroy for owner" do
      User.mock @john
      post :destroy, {:id => @public.id}

      assigns(:entity).should be_kind_of Heimdallr::Proxy::Record
      assigns(:entity).id.should == @public.id
    end

    it "disallows destroy for nobody" do
      User.mock @maria
      expect { post :destroy, {:id => @public.id} }.should raise_error
    end

    it "assigns the custom methods" do
      User.mock @john
      post :penetrate, {:id => @public.id}

      assigns(:entity).should be_kind_of Heimdallr::Proxy::Record
      assigns(:entity).id.should == @public.id
    end
  end
end