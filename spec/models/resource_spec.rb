require 'spec_helper'

describe Heimdallr::Resource do

  let(:controller_class) { Class.new }
  let(:controller) { controller_class.new }

  before do
    controller_class.class_eval do
      include Heimdallr::Resource
      def params
        {}
      end
    end
  end

  context ".load_resource" do
    it "sets up a before filter which passes the call to ResourceImplementation" do
      mock(controller_class).before_filter({}) { |options, block| block.call(controller) }
      stub(Heimdallr::ResourceImplementation).new(controller, :resource => :entity).mock!.load_resource
      controller_class.load_resource :resource => :entity
    end

    it "passes relevant options to the filter" do
      mock(controller_class).before_filter(:only => [:create, :update]) { |options, block| block.call(controller) }
      stub(Heimdallr::ResourceImplementation).new(controller, :resource => :entity).mock!.load_resource
      controller_class.load_resource :resource => :entity, :only => [:create, :update]
    end

    it "figures out the resource name based on the controller name" do
      mock(controller_class).before_filter({}) { |options, block| block.call(controller) }
      stub(Heimdallr::ResourceImplementation).new(controller, :resource => 'entity').mock!.load_resource
      stub(controller_class).name { 'EntitiesController' }
      controller_class.load_resource
    end

    it "figures out the resource name correctly if the controller is namespaced" do
      mock(controller_class).before_filter({}) { |options, block| block.call(controller) }
      stub(Heimdallr::ResourceImplementation).new(controller, :resource => 'some_project/entity').mock!.load_resource
      stub(controller_class).name { 'SomeProject::EntitiesController' }
      controller_class.load_resource
    end
  end

  context ".load_and_authorize_resource" do
    it "sets up a before filter which passes the call to ResourceImplementation" do
      mock(controller_class).before_filter({}) { |options, block| block.call(controller) }
      stub(Heimdallr::ResourceImplementation).new(controller, :resource => :entity).mock!.load_and_authorize_resource
      controller_class.load_and_authorize_resource :resource => :entity
    end

    it "passes relevant options to the filter" do
      mock(controller_class).before_filter(:except => :index) { |options, block| block.call(controller) }
      stub(Heimdallr::ResourceImplementation).new(controller, :resource => :entity).mock!.load_and_authorize_resource
      controller_class.load_and_authorize_resource :resource => :entity, :except => :index
    end
  end

  context ".skip_authorization_check" do
    it "prepends a before filter which sets controller's instance variable to true" do
      mock(controller_class).prepend_before_filter({}) { |options, block| block.call(controller) }
      controller_class.skip_authorization_check
      controller.instance_variable_get(:@_skip_authorization_check).should be_true
    end

    it "passes options to the filter" do
      mock(controller_class).prepend_before_filter({:only => :show}) { |options, block| block.call(controller) }
      controller_class.skip_authorization_check :only => :show
    end

    it "makes #skip_authorization_check? return true" do
      mock(controller_class).prepend_before_filter({}) { |options, block| block.call(controller) }
      controller_class.skip_authorization_check
      controller.send(:skip_authorization_check?).should be_true
    end
  end

  context "heimdallr_options" do
    it "stores options in class attribute" do
      controller_subclass = Class.new(controller_class)
      controller_subsubclass = Class.new(controller_subclass)
      options1 = {:option => 1}
      options2 = {:option => 2}
      controller_subclass.send :own_heimdallr_options=, options1
      controller_subsubclass.send :own_heimdallr_options=, options2
      controller_subclass.heimdallr_options.should == options1
      controller_subsubclass.heimdallr_options.should == options2
      controller_class.respond_to?(:heimdallr_options).should be_false
    end
  end
end