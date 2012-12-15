require 'spec_helper'

describe PostsController, :type => :controller do
  before(:all) do
    User.destroy_all
    Post.destroy_all

    @john = User.create! :admin => false
    @maria = User.create! :admin => false
    @admin = User.create! :admin => true
    
    @private = Post.create! :title => "John's private post", :public => false, :owner_id => @john.id
    @public = Post.create! :title => "Public post", :public => true, :owner_id => @john.id
  end

  it "shows everything to the admin" do
    User.mock @admin
    get :index

    assigns(:posts).should have(2).items
  end

  it "hides non-public posts" do
    User.mock @maria
    get :index

    assigns(:posts).should have(1).items
  end

  it "shows private to owner" do
    User.mock @john
    get :show, :id => @private.id

    assigns(:post).insecure.should == @private
  end

  it "hides private from non-owner" do
    User.mock @maria

    expect{ get :show, :id => @private.id }.to raise_error
  end

  it "allows creation for admin" do
    User.mock @admin
    post :create

    assigns(:post).should be_kind_of Heimdallr::Proxy::Record
  end

  it "disallows creation for non-admin" do
    User.mock @john
    expect{ post :create }.to raise_error
  end

  it "allows update for admin" do
    User.mock @admin
    post :update, {:id => @private.id}

    assigns(:post).should be_kind_of Heimdallr::Proxy::Record
    assigns(:post).id.should == @private.id
  end

  it "disallows update for non-admin" do
    User.mock @john
    expect { post :update, {:id => @public.id} }.to raise_error
  end

  it "allows destroy for admin" do
    User.mock @admin
    post :destroy, :id => @private.id

    assigns(:post).should be_kind_of Heimdallr::Proxy::Record
    assigns(:post).id.should == @private.id
  end

  it "allows destroy for owner" do
    User.mock @john
    post :destroy, {:id => @public.id}

    assigns(:post).should be_kind_of Heimdallr::Proxy::Record
    assigns(:post).id.should == @public.id
  end

  it "disallows destroy for nobody" do
    User.mock @maria
    expect{ post :destroy, :id => @public.id }.to raise_error
  end

  it "assigns the custom methods" do
    User.mock @john
    post :hide, :id => @public.id

    assigns(:post).should be_kind_of Heimdallr::Proxy::Record
    assigns(:post).id.should == @public.id
  end
end
