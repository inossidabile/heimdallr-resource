require 'spec_helper'

describe PostCommentsController, :type => :controller do
  before(:all) do
    User.destroy_all
    Post.destroy_all

    @john = User.create! :admin => false
    @admin = User.create! :admin => true

    @post = Post.create! :title => "Test post", :owner_id => @john.id
    @comment = @post.comments.create! :text => "Test comment"
  end

  describe '#index' do
    before { get :index, :post_id => @post.id }

    it "assigns post to @post" do
      assigns(:post).id.should == @post.id
    end

    it "assigns comments to @comments" do
      assigns(:comments).should have(1).items
      assigns(:comments).first.id.should == @comment.id
    end

    it "loads post in the base controller" do
      controller.loaded_by_base_post.should == assigns(:post)
    end
  end

  describe '#show' do
    before { get :show, :post_id => @post.id, :id => @comment.id }

    it "assigns post to @post" do
      assigns(:post).id.should == @post.id
    end

    it "assigns comment to @comment" do
      assigns(:comment).id.should == @comment.id
    end

    it "loads post in the base controller" do
      controller.loaded_by_base_post.should == assigns(:post)
    end
  end
end
