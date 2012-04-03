require 'spec_helper'

describe EntityController, :type => :controller do
  describe "GET index" do
    it "assigns @entities" do
      get :index

      assigns(:entities).should_not be_nil
    end
  end
end