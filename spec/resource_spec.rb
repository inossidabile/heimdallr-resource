require 'spec_helper'

describe EntityController, :type => :controller do
  before do
    Entity.new(:name => 'ent1', :public => false)
    Entity.new(:name => 'ent1', :public => true)
  end

  describe "GET index" do
    it "assigns @entities" do
      User.mock :admin

      get :index

      assigns(:entities).to_a.should == Entity.all
    end

    it "hides non-public entities" do
      User.mock :user

      get :index

      assigns(:entities).to_a.should == Entity.where(:public => true).to_a
    end
  end
end