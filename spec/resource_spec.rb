require 'spec_helper'

describe Heimdallr::ResourceImplementation, :focus => true do
  let(:controller) { Object.new }
  let(:params) { HashWithIndifferentAccess.new :controller => :entities }
  let(:entity) { stub!.id{1}.subject }
  before do
    stub(controller).params { params }
  end

  describe '.load' do
    it "loads and assigns the resource to an instance variable for show action" do
      params.merge! :action => 'show', :id => entity.id
      stub(Entity).scoped.mock!.find(entity.id) { entity }
      Heimdallr::ResourceImplementation.load controller, :resource => 'entity'
      controller.instance_variable_get(:@entity).should == entity
    end

    it "loads and assigns the resource to an instance variable for edit action" do
      params.merge! :action => 'edit', :id => entity.id
      stub(Entity).scoped.mock!.find(entity.id) { entity }
      Heimdallr::ResourceImplementation.load controller, :resource => 'entity'
      controller.instance_variable_get(:@entity).should == entity
    end

    it "loads and assigns the resource to an instance variable for update action" do
      params.merge! :action => 'edit', :id => entity.id
      stub(Entity).scoped.mock!.find(entity.id) { entity }
      Heimdallr::ResourceImplementation.load controller, :resource => 'entity'
      controller.instance_variable_get(:@entity).should == entity
    end

    it "loads and assigns the resource to an instance variable for destroy action" do
      params.merge! :action => 'destroy', :id => entity.id
      stub(Entity).scoped.mock!.find(entity.id) { entity }
      Heimdallr::ResourceImplementation.load controller, :resource => 'entity'
      controller.instance_variable_get(:@entity).should == entity
    end

    it "builds and assigns a new resource for new action" do
      params.merge! :action => 'new'
      mock(Entity).new({}) { :new_entity }
      Heimdallr::ResourceImplementation.load controller, :resource => 'entity'
      controller.instance_variable_get(:@entity).should == :new_entity
    end

    it "builds and assigns a new resource for create action" do
      params.merge! :action => 'create', :entity => {:name => 'foo'}
      mock(Entity).new('name' => 'foo') { :new_entity }
      Heimdallr::ResourceImplementation.load controller, :resource => 'entity'
      controller.instance_variable_get(:@entity).should == :new_entity
    end

    it "loads and assigns a resource collection for index action" do
      params.merge! :action => 'index'
      mock(Entity).scoped { :entity_collection }
      Heimdallr::ResourceImplementation.load controller, :resource => 'entity'
      controller.instance_variable_get(:@entities).should == :entity_collection
    end

    it "loads and assigns a single resource for custom action by default" do
      params.merge! :action => 'fetch', :id => entity.id
      stub(Entity).scoped.mock!.find(entity.id) { entity }
      Heimdallr::ResourceImplementation.load controller, :resource => 'entity'
      controller.instance_variable_get(:@entity).should == entity
    end

    it "loads and assigns a collection for custom action if specified in options" do
      params.merge! :action => 'sort'
      mock(Entity).scoped { :entity_collection }
      Heimdallr::ResourceImplementation.load controller, :resource => 'entity', :collection => [:sort]
      controller.instance_variable_get(:@entities).should == :entity_collection
    end

    it "builds and assigns a new resource for custom action if specified in options" do
      params.merge! :action => 'generate', :entity => {:name => 'foo'}
      mock(Entity).new('name' => 'foo') { :new_entity }
      Heimdallr::ResourceImplementation.load controller, :resource => 'entity', :new_record => [:generate]
      controller.instance_variable_get(:@entity).should == :new_entity
    end

    it "doesn't assign the resource to an instance variable if it is already assigned" do
      params.merge! :action => 'show', :id => entity.id
      controller.instance_variable_set :@entity, :different_entity
      stub(Entity).scoped.stub!.find(entity.id) { entity }
      Heimdallr::ResourceImplementation.load controller, :resource => 'entity'
      controller.instance_variable_get(:@entity).should == :different_entity
    end

    it "loads and assigns a resource through the association of another parent resource" do
      thing = stub!.id{1}.subject
      params.merge! :controller => :things, :action => 'show', :entity_id => entity.id, :id => thing.id
      controller.instance_variable_set(:@entity, entity)
      stub(entity).things.mock!.find(thing.id) { thing }
      Heimdallr::ResourceImplementation.load controller, :resource => 'thing', :through => 'entity'
      controller.instance_variable_get(:@thing).should == thing
    end

    it "loads and assigns the parent resource if :through option is provided" do
      params.merge! :controller => :things, :action => 'index', :entity_id => entity.id
      stub(Entity).scoped.mock!.find(entity.id) { entity }
      stub(entity).things
      Heimdallr::ResourceImplementation.load controller, :resource => 'thing', :through => 'entity'
      controller.instance_variable_get(:@entity).should == entity
    end

    it "loads the resource directly if the parent isn't found and :shallow option is true" do
      thing = stub!.id{1}.subject
      params.merge! :controller => :things, :action => 'show', :id => thing.id
      stub(Thing).scoped.mock!.find(thing.id) { thing }
      Heimdallr::ResourceImplementation.load controller, :resource => 'thing', :through => 'entity', :shallow => true
      controller.instance_variable_get(:@thing).should == thing
    end

    it "raises an error when the parent's id is not provided" do
      params.merge! :controller => :things, :action => 'show', :id => 1
      expect {
        Heimdallr::ResourceImplementation.load controller, :resource => 'thing', :through => 'entity'
      }.to raise_error(RuntimeError)
    end

    it "loads through the first parent found when multiple are given" do
      thing = stub!.id{1}.subject
      params.merge! :controller => :things, :action => 'show', :id => thing.id
      class Nothing; end
      stub(Nothing).scoped
      controller.instance_variable_set(:@entity, entity)
      controller.instance_variable_set(:@user, Object.new)
      stub(entity).things.mock!.find(thing.id) { thing }
      Heimdallr::ResourceImplementation.load controller, :resource => 'thing', :through => [:nothing, :entity, :user]
      controller.instance_variable_get(:@thing).should == thing
    end

    pending "loads through has_one association with :singleton option" do
      thing = stub!.id{1}.subject
      params.merge! :controller => :things, :action => 'show', :id => thing.id
      controller.instance_variable_set(:@entity, entity)
      mock(entity).thing { thing }
      Heimdallr::ResourceImplementation.load controller, :resource => 'thing', :through => 'entity', :singleton => true
      controller.instance_variable_get(:@thing).should == thing
    end

    it "loads through custom association if :through_association option is provided"
  end

  describe '.load_and_authorize' do
    let(:user) { stub!.id{1}.subject }
    before do
      stub(controller).security_context { user }
    end

    it "initializes new resource with predefined attributes"
  end
end