module Heimdallr

  # {Resource} is a mixin providing CanCan-like interface for Rails controllers.
  module Resource
    extend ActiveSupport::Concern

    module ClassMethods
      def load_resource(options = {})
        Heimdallr::ResourceImplementation.add_before_filter self, :load_resource, options
      end

      def load_and_authorize_resource(options = {})
        Heimdallr::ResourceImplementation.add_before_filter self, :load_and_authorize_resource, options
      end

      def skip_authorization_check(options = {})
        prepend_before_filter options do |controller|
          controller.instance_variable_set :@_skip_authorization_check, true
        end
      end

    protected
      def own_heimdallr_options=(options)
        class << self
          attr_accessor :heimdallr_options
        end
        self.heimdallr_options = options
      end
    end

  protected
    def skip_authorization_check?
      @_skip_authorization_check
    end
  end

  # {AccessDenied} exception is to be raised when access is denied to an action.
  class AccessDenied < StandardError; end
  
end
