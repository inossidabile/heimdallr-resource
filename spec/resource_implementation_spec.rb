require 'spec_helper'

describe Heimdallr::ResourceImplementation do
  let(:controller) { Object.new }
  let(:params) { HashWithIndifferentAccess.new :controller => :posts }
  let(:post) { stub!.id{1}.subject }
  before do
    stub(controller).params { params }
    stub(controller).skip_authorization_check? { false }
  end

  describe '#load_resource' do
    it "loads and assigns the resource to an instance variable for show action" do
      params.merge! :action => 'show', :id => post.id
      stub(Post).scoped.mock!.find(post.id) { post }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      resource.load_resource
      controller.instance_variable_get(:@post).should == post
    end

    it "loads and assigns the resource to an instance variable for edit action" do
      params.merge! :action => 'edit', :id => post.id
      stub(Post).scoped.mock!.find(post.id) { post }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      resource.load_resource
      controller.instance_variable_get(:@post).should == post
    end

    it "loads and assigns the resource to an instance variable for update action" do
      params.merge! :action => 'edit', :id => post.id
      stub(Post).scoped.mock!.find(post.id) { post }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      resource.load_resource
      controller.instance_variable_get(:@post).should == post
    end

    it "loads and assigns the resource to an instance variable for destroy action" do
      params.merge! :action => 'destroy', :id => post.id
      stub(Post).scoped.mock!.find(post.id) { post }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      resource.load_resource
      controller.instance_variable_get(:@post).should == post
    end

    it "builds and assigns a new resource for new action" do
      params.merge! :action => 'new'
      mock(Post).new({}) { :new_post }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      resource.load_resource
      controller.instance_variable_get(:@post).should == :new_post
    end

    it "builds and assigns a new resource for create action" do
      params.merge! :action => 'create', :post => {:title => 'foo'}
      mock(Post).new('title' => 'foo') { :new_post }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      resource.load_resource
      controller.instance_variable_get(:@post).should == :new_post
    end

    it "loads and assigns a resource collection for index action" do
      params.merge! :action => 'index'
      mock(Post).scoped { :post_collection }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      resource.load_resource
      controller.instance_variable_get(:@posts).should == :post_collection
    end

    it "loads and assigns a namespaced resource" do
      params.merge! :action => 'show', :id => post.id
      module SomeProject
        class Post < ::Post; end
      end
      stub(SomeProject::Post).scoped.mock!.find(post.id) { post }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'some_project/post'
      resource.load_resource
      controller.instance_variable_get(:@some_project_post).should == post
    end
    
    it "loads the resource with a custom finder" do
      params.merge! :action => 'show', :id => post.id
      stub(Post).scoped.mock!.find_by_title(post.id) { post }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post', :finder => :find_by_title
      resource.load_resource
      controller.instance_variable_get(:@post).should == post
    end

    it "loads and assigns a single resource for custom action by default" do
      params.merge! :action => 'fetch', :id => post.id
      stub(Post).scoped.mock!.find(post.id) { post }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      resource.load_resource
      controller.instance_variable_get(:@post).should == post
    end

    it "loads and assigns a collection for custom action if specified in options" do
      params.merge! :action => 'sort'
      mock(Post).scoped { :post_collection }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post', :collection => [:sort]
      resource.load_resource
      controller.instance_variable_get(:@posts).should == :post_collection
    end

    it "builds and assigns a new resource for custom action if specified in options" do
      params.merge! :action => 'generate', :post => {:title => 'foo'}
      mock(Post).new('title' => 'foo') { :new_post }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post', :new_record => [:generate]
      resource.load_resource
      controller.instance_variable_get(:@post).should == :new_post
    end

    it "doesn't assign the resource to an instance variable if it is already assigned" do
      params.merge! :action => 'show', :id => post.id
      controller.instance_variable_set :@post, :different_post
      stub(Post).scoped.stub!.find(post.id) { post }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      resource.load_resource
      controller.instance_variable_get(:@post).should == :different_post
    end

    it "loads and assigns a resource through the association of another parent resource" do
      comment = stub!.id{1}.subject
      params.merge! :controller => :comments, :action => 'show', :post_id => post.id, :id => comment.id
      controller.instance_variable_set(:@post, post)
      stub(post).comments.mock!.find(comment.id) { comment }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => 'post'
      resource.load_resource
      controller.instance_variable_get(:@comment).should == comment
    end

    it "loads and assigns the parent resource if :through option is provided" do
      params.merge! :controller => :comments, :action => 'index', :post_id => post.id
      stub(Post).scoped.mock!.find(post.id) { post }
      stub(post).comments
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => 'post'
      resource.load_resource
      controller.instance_variable_get(:@post).should == post
    end

    it "loads the resource directly if the parent isn't found and :shallow option is true" do
      comment = stub!.id{1}.subject
      params.merge! :controller => :comments, :action => 'show', :id => comment.id
      stub(Comment).scoped.mock!.find(comment.id) { comment }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => 'post', :shallow => true
      resource.load_resource
      controller.instance_variable_get(:@comment).should == comment
    end

    it "raises an error when the parent's id is not provided" do
      params.merge! :controller => :comments, :action => 'show', :id => 1
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => 'post'
      expect { resource.load_resource }.to raise_error(RuntimeError)
    end

    it "loads through the first parent found when multiple are given" do
      comment = stub!.id{1}.subject
      params.merge! :controller => :comments, :action => 'show', :id => comment.id
      class Nothing; end
      stub(Nothing).scoped
      controller.instance_variable_set(:@post, post)
      controller.instance_variable_set(:@user, Object.new)
      stub(post).comments.mock!.find(comment.id) { comment }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => [:nothing, :post, :user]
      resource.load_resource
      controller.instance_variable_get(:@comment).should == comment
    end

    it "loads through has_one association with :singleton option" do
      comment = stub!.id{1}.subject
      params.merge! :controller => :comments, :action => 'show'
      controller.instance_variable_set(:@post, post)
      mock(post).comment { comment }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => 'post', :singleton => true
      resource.load_resource
      controller.instance_variable_get(:@comment).should == comment
    end

    it "builds a record through has_one association with :singleton option" do
      params.merge! :controller => :comments, :action => 'create', :comment => {:text => 'foo'}
      controller.instance_variable_set(:@post, post)
      comment = stub!.id{1}.subject
      stub(post).comment { nil }
      mock(post).build_comment('text' => 'foo') { comment }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => 'post', :singleton => true
      resource.load_resource
      controller.instance_variable_get(:@comment).should == comment
    end

    it "builds a record with correct method name with :singleton and :through_association options" do
      params.merge! :controller => :comments, :action => 'create', :comment => {:text => 'foo'}
      controller.instance_variable_set(:@post, post)
      comment = stub!.id{1}.subject
      stub(post).review { nil }
      mock(post).build_review('text' => 'foo') { comment }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => 'post', :singleton => true, :through_association => :review
      resource.load_resource
      controller.instance_variable_get(:@comment).should == comment
    end

    it "doesn't build a record through has_one association with :singleton option if one already exists because it can cause it to delete it in the database" do
      params.merge! :controller => :comments, :action => 'create', :comment => {:text => 'foo'}
      controller.instance_variable_set(:@post, post)
      comment = stub!.id{1}.subject
      mock(post).comment { comment }
      mock(comment).assign_attributes 'text' => 'foo'
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => 'post', :singleton => true
      resource.load_resource
      controller.instance_variable_get(:@comment).should == comment
    end

    it "loads through has_one association with :singleton and :shallow options" do
      comment = stub!.id{1}.subject
      params.merge! :controller => :comments, :action => 'show', :id => comment.id
      stub(Comment).scoped.mock!.find(comment.id) { comment }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => 'post', :singleton => true, :shallow => :true
      resource.load_resource
      controller.instance_variable_get(:@comment).should == comment
    end

    it "builds a record through has_one association with :singleton and :shallow options" do
      params.merge! :controller => :comments, :action => 'create', :comment => {:text => 'foo'}
      stub(Comment).scoped.mock!.new('text' => 'foo') { :new_comment }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => 'post', :singleton => true, :shallow => :true
      resource.load_resource
      controller.instance_variable_get(:@comment).should == :new_comment
    end

    it "builds a record through has_one association with :singleton and :shallow options even if the parent is present" do
      params.merge! :controller => :comments, :action => 'create', :comment => {:text => 'foo'}
      controller.instance_variable_set(:@post, post)
      stub(post).comment { nil }
      mock(post).build_comment('text' => 'foo') { :new_comment}
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => 'post', :singleton => true, :shallow => :true
      resource.load_resource
      controller.instance_variable_get(:@comment).should == :new_comment
    end

    it "loads through custom association if :through_association option is provided" do
      comment = stub!.id{1}.subject
      params.merge! :controller => :comments, :action => 'show', :post_id => post.id, :id => comment.id
      controller.instance_variable_set(:@post, post)
      stub(post).reviews.mock!.find(comment.id) { comment }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => 'post', :through_association => :reviews
      resource.load_resource
      controller.instance_variable_get(:@comment).should == comment
    end

    it "loads through custom association if both :through_association and :singleton options are provided" do
      comment = stub!.id{1}.subject
      params.merge! :controller => :comments, :action => 'show', :post_id => post.id, :id => comment.id
      controller.instance_variable_set(:@post, post)
      mock(post).review { comment }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'comment', :through => 'post', :through_association => :review, :singleton => true
      resource.load_resource
      controller.instance_variable_get(:@comment).should == comment
    end

    it "loads and assigns a resource using custom instance name" do
      params.merge! :action => 'show', :id => post.id
      stub(Post).scoped.mock!.find(post.id) { post }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post', :instance_name => :something
      resource.load_resource
      controller.instance_variable_get(:@something).should == post
    end

    it "loads and assigns a resource collection using custom instance name" do
      params.merge! :action => 'index'
      mock(Post).scoped { :post_collection }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post', :instance_name => :something
      resource.load_resource
      controller.instance_variable_get(:@somethings).should == :post_collection
    end
  end

  describe '#load_and_authorize_resource' do
    let(:user) { stub!.id{1}.subject }
    before do
      stub(user).admin { false }
      stub(controller).security_context { user }
      stub(post).restrict { post }
    end

    it "calls #restrict on the loaded resource" do
      params.merge! :action => 'show', :id => post.id
      mock(Post).restrict(controller.security_context).stub!.find(post.id) { post }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      resource.load_and_authorize_resource
    end

    it "raises AccessDenied when calling :new action for resource that can't be created" do
      params.merge! :action => 'new'
      mock(Post).new.mock!.restrict(controller.security_context, {}) { post }
      stub(post).assign_attributes
      mock(post).creatable? { false }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      expect { resource.load_and_authorize_resource }.to raise_error(Heimdallr::AccessDenied)
    end

    it "raises AccessDenied when creating a resource that can't be created" do
      params.merge! :action => 'create'
      mock(Post).new.mock!.restrict(controller.security_context, {}) { post }
      stub(post).assign_attributes
      mock(post).creatable? { false }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      expect { resource.load_and_authorize_resource }.to raise_error(Heimdallr::AccessDenied)
    end

    it "raises AccessDenied when calling :edit action for resource that can't be updated" do
      params.merge! :action => 'edit', :id => post.id
      mock(Post).restrict(controller.security_context).stub!.find(post.id) { post }
      mock(post).modifiable? { false }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      expect { resource.load_and_authorize_resource }.to raise_error(Heimdallr::AccessDenied)
    end

    it "raises AccessDenied when updating a resource that can't be updated" do
      params.merge! :action => 'update', :id => post.id
      mock(Post).restrict(controller.security_context).stub!.find(post.id) { post }
      mock(post).modifiable? { false }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      expect { resource.load_and_authorize_resource }.to raise_error(Heimdallr::AccessDenied)
    end

    it "raises AccessDenied when destroying a resource that can't be destroyed" do
      params.merge! :action => 'destroy', :id => post.id
      mock(Post).restrict(controller.security_context).stub!.find(post.id) { post }
      mock(post).destroyable? { false }
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      expect { resource.load_and_authorize_resource }.to raise_error(Heimdallr::AccessDenied)
    end

    it "fixates certain attributes of a new resource" do
      params.merge! :action => 'new', :post => {:title => 'foo'}
      mock(Post).new.mock!.restrict(controller.security_context, {}) { post }
      mock(post).creatable? { true }
      fixtures = {:create => {:title => 'bar'}}
      stub(post).reflect_on_security { {:restrictions => stub!.fixtures{fixtures}.subject} }
      stub(post).assign_attributes('title' => 'foo')
      mock(post).assign_attributes(fixtures[:create])
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      resource.load_and_authorize_resource
      controller.instance_variable_get(:@post) == post
    end

    it "fixates certain attributes of an updating resource" do
      params.merge! :action => 'update', :id => post.id, :post => {:title => 'foo'}
      mock(Post).restrict(controller.security_context).stub!.find(post.id) { post }
      mock(post).modifiable? { true }
      fixtures = {:update => {:title => 'bar'}}
      stub(post).reflect_on_security { {:restrictions => stub!.fixtures{fixtures}.subject} }
      stub(post).assign_attributes('title' => 'foo')
      mock(post).assign_attributes(fixtures[:update])
      resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
      resource.load_and_authorize_resource
      controller.instance_variable_get(:@post) == post
    end

    context "when controller.skip_authorization_check? is true" do
      before { stub(controller).skip_authorization_check? { true } }

      it "doesn't raise AccessDenied" do
        params.merge! :action => 'destroy', :id => post.id
        mock(Post).restrict(controller.security_context).stub!.find(post.id) { post }
        stub(post).destroyable? { false }
        resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
        expect { resource.load_and_authorize_resource }.not_to raise_error(Heimdallr::AccessDenied)
      end

      it "doesn't fixate attributes" do
        params.merge! :action => 'new', :post => {:title => 'foo'}
        mock(Post).new.mock!.restrict(controller.security_context, {}) { post }
        stub(post).creatable? { true }
        fixtures = {:create => {:title => 'bar'}}
        stub(post).reflect_on_security { {:restrictions => stub!.fixtures{fixtures}.subject} }
        stub(post).assign_attributes('title' => 'foo')
        dont_allow(post).assign_attributes(fixtures[:create])
        resource = Heimdallr::ResourceImplementation.new controller, :resource => 'post'
        resource.load_and_authorize_resource
        controller.instance_variable_get(:@post) == post
      end
    end
  end
end