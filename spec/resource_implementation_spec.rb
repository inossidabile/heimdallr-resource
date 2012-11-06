require 'spec_helper'

describe Heimdallr::ResourceImplementation do
  let(:controller) { Object.new }
  let(:params) { HashWithIndifferentAccess.new :controller => :entities }
  let(:entity) { stub!.id{1}.subject }
  before { stub(controller).params { params } }

  describe '#load_resource' do
    it "loads and assigns the resource to an instance variable for show action" do
      params.merge! :action => 'show', :id => entity.id
      stub(Entity).scoped.mock!.find(entity.id) { entity }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      resource.load_resource
      controller.instance_variable_get(:@entity).should == entity
    end

    it "loads and assigns the resource to an instance variable for edit action" do
      params.merge! :action => 'edit', :id => entity.id
      stub(Entity).scoped.mock!.find(entity.id) { entity }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      resource.load_resource
      controller.instance_variable_get(:@entity).should == entity
    end

    it "loads and assigns the resource to an instance variable for update action" do
      params.merge! :action => 'edit', :id => entity.id
      stub(Entity).scoped.mock!.find(entity.id) { entity }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      resource.load_resource
      controller.instance_variable_get(:@entity).should == entity
    end

    it "loads and assigns the resource to an instance variable for destroy action" do
      params.merge! :action => 'destroy', :id => entity.id
      stub(Entity).scoped.mock!.find(entity.id) { entity }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      resource.load_resource
      controller.instance_variable_get(:@entity).should == entity
    end

    it "builds and assigns a new resource for new action" do
      params.merge! :action => 'new'
      mock(Entity).new({}) { :new_entity }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      resource.load_resource
      controller.instance_variable_get(:@entity).should == :new_entity
    end

    it "builds and assigns a new resource for create action" do
      params.merge! :action => 'create', :entity => {:name => 'foo'}
      mock(Entity).new('name' => 'foo') { :new_entity }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      resource.load_resource
      controller.instance_variable_get(:@entity).should == :new_entity
    end

    it "loads and assigns a resource collection for index action" do
      params.merge! :action => 'index'
      mock(Entity).scoped { :entity_collection }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      resource.load_resource
      controller.instance_variable_get(:@entities).should == :entity_collection
    end

    it "loads and assigns a single resource for custom action by default" do
      params.merge! :action => 'fetch', :id => entity.id
      stub(Entity).scoped.mock!.find(entity.id) { entity }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      resource.load_resource
      controller.instance_variable_get(:@entity).should == entity
    end

    it "loads and assigns a collection for custom action if specified in options" do
      params.merge! :action => 'sort'
      mock(Entity).scoped { :entity_collection }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity', :collection => [:sort]
      resource.load_resource
      controller.instance_variable_get(:@entities).should == :entity_collection
    end

    it "builds and assigns a new resource for custom action if specified in options" do
      params.merge! :action => 'generate', :entity => {:name => 'foo'}
      mock(Entity).new('name' => 'foo') { :new_entity }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity', :new_record => [:generate]
      resource.load_resource
      controller.instance_variable_get(:@entity).should == :new_entity
    end

    it "doesn't assign the resource to an instance variable if it is already assigned" do
      params.merge! :action => 'show', :id => entity.id
      controller.instance_variable_set :@entity, :different_entity
      stub(Entity).scoped.stub!.find(entity.id) { entity }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      resource.load_resource
      controller.instance_variable_get(:@entity).should == :different_entity
    end

    it "loads and assigns a resource through the association of another parent resource" do
      thing = stub!.id{1}.subject
      params.merge! :controller => :things, :action => 'show', :entity_id => entity.id, :id => thing.id
      controller.instance_variable_set(:@entity, entity)
      stub(entity).things.mock!.find(thing.id) { thing }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'thing', :through => 'entity'
      resource.load_resource
      controller.instance_variable_get(:@thing).should == thing
    end

    it "loads and assigns the parent resource if :through option is provided" do
      params.merge! :controller => :things, :action => 'index', :entity_id => entity.id
      stub(Entity).scoped.mock!.find(entity.id) { entity }
      stub(entity).things
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'thing', :through => 'entity'
      resource.load_resource
      controller.instance_variable_get(:@entity).should == entity
    end

    it "loads the resource directly if the parent isn't found and :shallow option is true" do
      thing = stub!.id{1}.subject
      params.merge! :controller => :things, :action => 'show', :id => thing.id
      stub(Thing).scoped.mock!.find(thing.id) { thing }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'thing', :through => 'entity', :shallow => true
      resource.load_resource
      controller.instance_variable_get(:@thing).should == thing
    end

    it "raises an error when the parent's id is not provided" do
      params.merge! :controller => :things, :action => 'show', :id => 1
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'thing', :through => 'entity'
      expect { resource.load_resource }.to raise_error(RuntimeError)
    end

    it "loads through the first parent found when multiple are given" do
      thing = stub!.id{1}.subject
      params.merge! :controller => :things, :action => 'show', :id => thing.id
      class Nothing; end
      stub(Nothing).scoped
      controller.instance_variable_set(:@entity, entity)
      controller.instance_variable_set(:@user, Object.new)
      stub(entity).things.mock!.find(thing.id) { thing }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'thing', :through => [:nothing, :entity, :user]
      resource.load_resource
      controller.instance_variable_get(:@thing).should == thing
    end

    pending "loads through has_one association with :singleton option" do
      thing = stub!.id{1}.subject
      params.merge! :controller => :things, :action => 'show', :id => thing.id
      controller.instance_variable_set(:@entity, entity)
      mock(entity).thing { thing }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'thing', :through => 'entity', :singleton => true
      resource.load_resource
      controller.instance_variable_get(:@thing).should == thing
    end

    it "should not build record through has_one association with :singleton option because it can cause it to delete it in the database"
    it "should find record through has_one association with :singleton and :shallow options"
    it "should build record through has_one association with :singleton and :shallow options"

    it "loads through custom association if :through_association option is provided"
  end

  describe '#load_and_authorize_resource' do
    let(:user) { stub!.id{1}.subject }
    before do
      stub(user).admin { false }
      stub(controller).security_context { user }
    end

    it "calls #restrict on the loaded resource" do
      params.merge! :action => 'show', :id => entity.id
      mock(Entity).restrict(controller.security_context).stub!.find(entity.id) { entity }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      resource.load_and_authorize_resource
    end

    it "raises AccessDenied when calling :new action for resource that can't be created" do
      params.merge! :action => 'new'
      mock(Entity).new.mock!.restrict(controller.security_context, {}) { entity }
      stub(entity).assign_attributes
      mock(entity).creatable? { false }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      expect { resource.load_and_authorize_resource }.to raise_error(Heimdallr::AccessDenied)
    end

    it "raises AccessDenied when creating a resource that can't be created" do
      params.merge! :action => 'create'
      mock(Entity).new.mock!.restrict(controller.security_context, {}) { entity }
      stub(entity).assign_attributes
      mock(entity).creatable? { false }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      expect { resource.load_and_authorize_resource }.to raise_error(Heimdallr::AccessDenied)
    end

    it "raises AccessDenied when calling :edit action for resource that can't be updated" do
      params.merge! :action => 'edit', :id => entity.id
      mock(Entity).restrict(controller.security_context).stub!.find(entity.id) { entity }
      mock(entity).modifiable? { false }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      expect { resource.load_and_authorize_resource }.to raise_error(Heimdallr::AccessDenied)
    end

    it "raises AccessDenied when updating a resource that can't be updated" do
      params.merge! :action => 'update', :id => entity.id
      mock(Entity).restrict(controller.security_context).stub!.find(entity.id) { entity }
      mock(entity).modifiable? { false }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      expect { resource.load_and_authorize_resource }.to raise_error(Heimdallr::AccessDenied)
    end

    it "fixes certain attributes of a new resource" do
      params.merge! :action => 'new', :entity => {:name => 'foo'}
      mock(Entity).new.mock!.restrict(controller.security_context, {}) { entity }
      mock(entity).creatable? { true }
      fixtures = {:create => {:name => 'bar'}}
      mock(entity).reflect_on_security { {:restrictions => stub!.fixtures{fixtures}.subject} }
      stub(entity).assign_attributes('name' => 'foo')
      mock(entity).assign_attributes(fixtures[:create])
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      resource.load_and_authorize_resource
      controller.instance_variable_get(:@entity) == entity
    end

    it "fixes certain attributes of an updating resource" do
      params.merge! :action => 'update', :id => entity.id, :entity => {:name => 'foo'}
      mock(Entity).restrict(controller.security_context).stub!.find(entity.id) { entity }
      mock(entity).modifiable? { true }
      fixtures = {:update => {:name => 'bar'}}
      mock(entity).reflect_on_security { {:restrictions => stub!.fixtures{fixtures}.subject} }
      stub(entity).assign_attributes('name' => 'foo')
      mock(entity).assign_attributes(fixtures[:update])
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      resource.load_and_authorize_resource
      controller.instance_variable_get(:@entity) == entity
    end

    it "raises AccessDenied when destroying a resource that can't be destroyed" do
      params.merge! :action => 'destroy', :id => entity.id
      mock(Entity).restrict(controller.security_context).stub!.find(entity.id) { entity }
      mock(entity).destroyable? { false }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'entity'
      expect { resource.load_and_authorize_resource }.to raise_error(Heimdallr::AccessDenied)
    end
  end
end