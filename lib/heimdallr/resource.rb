module Heimdallr
  # {AccessDenied} exception is to be raised when access is denied to an action.
  class AccessDenied < StandardError; end

  module ResourceImplementation
    class << self
      def prepare_options(klass, resource, options)
        options.merge! :resource => (resource || klass.name.sub(/Controller$/, '').underscore)

        filter_options = {}
        filter_options[:only]   = options.delete(:only)   if options.has_key?(:only)
        filter_options[:except] = options.delete(:except) if options.has_key?(:except)

        [ options, filter_options ]
      end

      def load(controller, options)
        unless controller.instance_variable_defined?(ivar_name(controller, options))
          if options.has_key? :through
            if options[:singleton]
              scope = controller.instance_variable_get(:"@#{options[:through]}").
                          send(:"#{options[:resource]}")
            else
              scope = controller.instance_variable_get(:"@#{options[:through]}").
                          send(:"#{options[:resource].pluralize}")
            end
          else
            scope = options[:resource].camelize.constantize.scoped
          end

          case controller.params[:action]
          when 'index'
            controller.instance_variable_set(ivar_name(controller, options), scope)
          when 'new', 'create'
            controller.instance_variable_set(ivar_name(controller, options),
                scope.new(controller.params[options[:resource]]))
          when 'show', 'edit', 'update', 'destroy'
            controller.instance_variable_set(ivar_name(controller, options),
                scope.find(controller.params[:"#{options[:resource]}_id"] ||
                           controller.params[:id]))
          end
        end
      end

      def authorize(controller, options)
        controller.instance_variable_set(ivar_name(controller, options.merge(:insecure => true)),
            controller.instance_variable_get(ivar_name(controller, options)))

        value = controller.instance_variable_get(ivar_name(controller, options)).
              restrict(controller.security_context)
        controller.instance_variable_set(ivar_name(controller, options), value)

        case controller.params[:action]
        when 'new', 'create'
          unless value.reflect_on_security[:operations].include? :create
            raise Heimdallr::AccessDenied, "Cannot create model"
          end
        when 'edit', 'update'
          unless value.reflect_on_security[:operations].include? :update
            raise Heimdallr::AccessDenied, "Cannot update model"
          end
        end
      end

      def ivar_name(controller, options)
        if controller.params[:action] == 'index'
          :"@#{options[:resource].pluralize}"
        else
          :"@#{options[:resource]}"
        end
      end
    end
  end

  # {Resource} is a mixin providing CanCan-like interface for Rails controllers.
  module Resource
    extend ActiveSupport::Concern

    module ClassMethods
      def load_and_authorize_resource(resource=nil, options={})
        load_resource(resource, options)
        authorize_resource(resource, options)
      end

      def load_resource(resource=nil, options={})
        options, filter_options = Heimdallr::ResourceImplementation.prepare_options(self, resource, options)

        before_filter filter_options do |controller|
          Heimdallr::ResourceImplementation.load(controller, options)
        end
      end

      def authorize_resource(resource=nil, options={})
        options, filter_options = Heimdallr::ResourceImplementation.prepare_options(self, resource, options)

        before_filter filter_options do |controller|
          Heimdallr::ResourceImplementation.authorize(controller, options)
        end
      end
    end
  end
end