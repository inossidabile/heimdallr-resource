module Heimdallr

  # {Resource} is a mixin providing CanCan-like interface for Rails controllers.
  module Resource
    extend ActiveSupport::Concern

    module ClassMethods
      def load_resource(options = {})
        options, filter_options = Heimdallr::ResourceImplementation.prepare_options self, options

        before_filter filter_options do |controller|
          Heimdallr::ResourceImplementation.load_resource controller, options
        end
      end

      def load_and_authorize_resource(options = {})
        options, filter_options = Heimdallr::ResourceImplementation.prepare_options self, options

        before_filter filter_options do |controller|
          Heimdallr::ResourceImplementation.load_and_authorize_resource controller, options
        end
      end
    end
  end

  # {AccessDenied} exception is to be raised when access is denied to an action.
  class AccessDenied < StandardError; end

end
