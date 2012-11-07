require 'spec_helper'

describe Heimdallr::Resource do
  let(:controller_class) { Class.new }
  let(:controller) { controller_class.new }
  before do
    controller_class.class_eval { include Heimdallr::Resource }
    stub(controller).params { {} }
  end

  context "#load_resource" do
    it "sets up a before filter which passes the call to ResourceImplementation" do
      mock(controller_class).before_filter({}) { |options, block| block.call(controller) }
      stub(Heimdallr::ResourceImplementation).new(controller, :resource => 'entity').mock!.load_resource
      controller_class.load_resource :resource => :entity
    end

    it "passes relevant options to the filter" do
      mock(controller_class).before_filter(:only => [:create, :update]) { |options, block| block.call(controller) }
      stub(Heimdallr::ResourceImplementation).new(controller, :resource => 'entity').mock!.load_resource
      controller_class.load_resource :resource => :entity, :only => [:create, :update]
    end
  end

  context "#load_and_authorize_resource" do
    it "sets up a before filter which passes the call to ResourceImplementation" do
      mock(controller_class).before_filter({}) { |options, block| block.call(controller) }
      stub(Heimdallr::ResourceImplementation).new(controller, :resource => 'entity').mock!.load_and_authorize_resource
      controller_class.load_and_authorize_resource :resource => :entity
    end

    it "passes relevant options to the filter" do
      mock(controller_class).before_filter(:except => :index) { |options, block| block.call(controller) }
      stub(Heimdallr::ResourceImplementation).new(controller, :resource => 'entity').mock!.load_and_authorize_resource
      controller_class.load_and_authorize_resource :resource => :entity, :except => :index
    end
  end
end