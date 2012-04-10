module Heimdallr
  # {AccessDenied} exception is to be raised when access is denied to an action.
  class AccessDenied < StandardError; end

  module ResourceImplementation
    class << self
      def prepare_options(klass, options)
        options = options.merge :resource => (options[:resource] || klass.name.sub(/Controller$/, '').underscore).to_s

        filter_options = {}
        filter_options[:only]   = options.delete(:only)   if options.has_key?(:only)
        filter_options[:except] = options.delete(:except) if options.has_key?(:except)

        [ options, filter_options ]
      end

      def load(controller, options)
        unless controller.instance_variable_defined?(ivar_name(controller, options))
          if options.has_key? :through
            target = Array.wrap(options[:through]).map do |parent|
              controller.instance_variable_get(:"@#{parent}")
            end.reject(&:nil?).first

            if target
              if options[:singleton]
                scope = target.send(:"#{options[:resource]}")
              else
                scope = target.send(:"#{options[:resource].pluralize}")
              end
            elsif options[:shallow]
              scope = options[:resource].camelize.constantize.scoped
            else
              raise "Cannot fetch #{options[:resource]} via #{options[:through]}"
            end
          else
            scope = options[:resource].camelize.constantize.scoped
          end

          loaders = {
            collection: -> {
              controller.instance_variable_set(ivar_name(controller, options), scope)
            },

            new_record: -> {
              controller.instance_variable_set(ivar_name(controller, options),
                  scope.new(controller.params[options[:resource]]))
            },

            record: -> {
              controller.instance_variable_set(ivar_name(controller, options),
                  scope.find(controller.params[:"#{options[:resource]}_id"] ||
                             controller.params[:id]))
            },

            related_record: -> {
              if controller.params[:"#{options[:resource]}_id"]
                controller.instance_variable_set(ivar_name(controller, options),
                    scope.find(controller.params[:"#{options[:resource]}_id"]))
              end
            }
          }

          loaders[action_type(controller.params[:action], options)].()
        end
      end

      def authorize(controller, options)
        value = controller.instance_variable_get(ivar_name(controller, options))
        return unless value

        controller.instance_variable_set(ivar_name(controller, options.merge(:insecure => true)), value)

        value = value.restrict(controller.security_context)
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
        when 'destroy'
          unless value.destroyable?
            raise Heimdallr::AccessDenied, "Cannot delete model"
          end
        end
      end

      def ivar_name(controller, options)
        if action_type(controller.params[:action], options) == :collection
          :"@#{options[:resource].pluralize.gsub('/', '_')}"
        else
          :"@#{options[:resource].gsub('/', '_')}"
        end
      end

      def action_type(action, options)
        if options[:related]
          :related_record
        else
          action = action.to_sym
          case action
          when :index
            :collection
          when :new, :create
            :new_record
          when :show, :edit, :update, :destroy
            :record
          else
            if options[:collection] && options[:collection].include?(action)
              :collection
            elsif options[:new] && options[:new].include?(action)
              :new_record
            else
              :record
            end
          end
        end
      end
    end
  end

  # {Resource} is a mixin providing CanCan-like interface for Rails controllers.
  module Resource extend ActiveSupport::Concern

    module ClassMethods
      def load_and_authorize_resource(options={})
        load_resource(options)
        authorize_resource(options)
      end

      def load_resource(options={})
        options, filter_options = Heimdallr::ResourceImplementation.prepare_options(self, options)
        self.own_heimdallr_options = options

        before_filter filter_options do |controller|
          Heimdallr::ResourceImplementation.load(controller, options)
        end
      end

      def authorize_resource(options={})
        options, filter_options = Heimdallr::ResourceImplementation.prepare_options(self, options)
        self.own_heimdallr_options = options

        before_filter filter_options do |controller|
          Heimdallr::ResourceImplementation.authorize(controller, options)
        end
      end

      protected

      def own_heimdallr_options=(options)
        cattr_accessor :heimdallr_options
        self.heimdallr_options = options
      end
    end
  end
end