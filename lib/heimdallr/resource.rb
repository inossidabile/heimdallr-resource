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
    end
  end

  # {AccessDenied} exception is to be raised when access is denied to an action.
  class AccessDenied < StandardError; end

end
