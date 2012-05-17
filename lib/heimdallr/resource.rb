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
            target = load_target(controller, options)

            if target
              if options[:singleton]
                scope = target.send(:"#{variable_name(options)}")
              else
                scope = target.send(:"#{variable_name(options).pluralize}")
              end
            elsif options[:shallow]
              scope = class_name(options).constantize.scoped
            else
              raise "Cannot fetch #{options[:resource]} via #{options[:through]}"
            end
          else
            scope = class_name(options).constantize.scoped
          end

          loaders = {
            collection: -> {
              controller.instance_variable_set(ivar_name(controller, options), scope)
            },

            new_record: -> {
              controller.instance_variable_set(
                ivar_name(controller, options),
                scope.new(controller.params[params_key_name(options)])
              )
            },

            record: -> {
              controller.instance_variable_set(
                ivar_name(controller, options),
                scope.find([:"#{params_key_name(options)}_id", :id].map{|key| controller.params[key] }.reject(&:blank?)[0])
              )
            },

            related_record: -> {
              unless controller.params[:"#{params_key_name(options)}_id"].blank?
                controller.instance_variable_set(
                  ivar_name(controller, options),
                  scope.find(controller.params[:"#{params_key_name(options)}_id"])
                )
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
          value.assign_attributes(value.reflect_on_security[:restrictions].fixtures[:create])

          unless value.reflect_on_security[:operations].include? :create
            raise Heimdallr::AccessDenied, "Cannot create model"
          end

        when 'edit', 'update'
          value.assign_attributes(value.reflect_on_security[:restrictions].fixtures[:update])

          unless value.reflect_on_security[:operations].include? :update
            raise Heimdallr::AccessDenied, "Cannot update model"
          end

        when 'destroy'
          unless value.destroyable?
            raise Heimdallr::AccessDenied, "Cannot delete model"
          end
        end unless options[:related]
      end

      def load_target(controller, options)
        Array.wrap(options[:through]).map do |parent|
          loaded = controller.instance_variable_get(:"@#{variable_name parent}")
          unless loaded
            load(controller, :resource => parent.to_s, :related => true)
            loaded = controller.instance_variable_get(:"@#{variable_name parent}")
          end
          if loaded && options[:authorize_chain]
            authorize(controller, :resource => parent.to_s, :related => true)
          end
          controller.instance_variable_get(:"@#{variable_name parent}")
        end.reject(&:nil?).first
      end

      def ivar_name(controller, options)
        if action_type(controller.params[:action], options) == :collection
          :"@#{variable_name(options).pluralize}"
        else
          :"@#{variable_name(options)}"
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

      def variable_name(options)
        if options.kind_of? Hash
          options[:resource]
        else
          options.to_s
        end.parameterize('_')
      end

      def class_name(options)
        if options.kind_of? Hash
          options[:resource]
        else
          options.to_s
        end.classify
      end

      def params_key_name(options)
        if options.kind_of? Hash
          options[:resource]
        else
          options.to_s
        end.split('/').last
      end
    end
  end

  # {Resource} is a mixin providing CanCan-like interface for Rails controllers.
  module Resource
    extend ActiveSupport::Concern

    module ClassMethods
      def load_and_authorize_resource(options={})
        options[:authorize_chain] = true
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