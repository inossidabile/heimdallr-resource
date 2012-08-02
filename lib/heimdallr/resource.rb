module Heimdallr

  # {Resource} is a mixin providing CanCan-like interface for Rails controllers.
  module Resource
    extend ActiveSupport::Concern

    module ClassMethods
      def load_resource(options={})
        options, filter_options = Heimdallr::ResourceImplementation.prepare_options self, options
        self.own_heimdallr_options = options

        before_filter filter_options do |controller|
          Heimdallr::ResourceImplementation.load controller, options
        end
      end

      def load_and_authorize_resource(options={})
        options, filter_options = Heimdallr::ResourceImplementation.prepare_options self, options
        self.own_heimdallr_options = options

        before_filter filter_options do |controller|
          Heimdallr::ResourceImplementation.load_and_authorize controller, options
        end
      end

    protected

      def own_heimdallr_options=(options)
        cattr_accessor :heimdallr_options
        self.heimdallr_options = options
      end
    end
  end

  # {AccessDenied} exception is to be raised when access is denied to an action.
  class AccessDenied < StandardError; end

  module ResourceImplementation
    def self.prepare_options(klass, options)
      options = options.dup
      options[:resource] = (options[:resource] || klass.name.sub(/Controller$/, '').underscore).to_s

      filter_keys = [
        :only,
        :except
      ]

      filter_options = filter_keys.inject({}) do |hash, key|
        if options.has_key? key
          hash[key] = options.delete key
        end

        hash
      end

      [ options, filter_options ]
    end

    def self.load(controller, options)
      return if controller.instance_variable_defined? self.ivar_name(controller, options)

      scope = self.class_name(options).constantize.scoped
      self.__load controller, options, scope, :load
    end

    def self.load_and_authorize(controller, options)
      return if controller.instance_variable_defined? self.ivar_name(controller, options)

      scope = self.class_name(options).constantize.restrict(controller.security_context)
      self.__load controller, options, scope, :load_and_authorize

      return if options[:related]

      resource = controller.instance_variable_get self.ivar_name(controller, options)

      case controller.params[:action]
      when 'new', 'create'
        unless resource.creatable?
          raise Heimdallr::AccessDenied, "Cannot create model"
        end
        resource.assign_attributes resource.reflect_on_security[:restrictions].fixtures[:create]

      when 'edit', 'update'
        unless resource.modifiable?
          raise Heimdallr::AccessDenied, "Cannot update model"
        end
        resource.assign_attributes resource.reflect_on_security[:restrictions].fixtures[:update]

      when 'destroy'
        unless resource.destroyable?
          raise Heimdallr::AccessDenied, "Cannot delete model"
        end
      end

      nil
    end

    def self.__load(controller, options, base_scope, caller)
      if options.has_key? :through
        target = Array.wrap(options[:through]).map { |parent|
          loaded = controller.instance_variable_get(:"@#{self.variable_name(parent)}")
          unless loaded
            self.send caller, controller, {:resource => parent.to_s, :related => true}
            loaded = controller.instance_variable_get(:"@#{self.variable_name(parent)}")
          end

          loaded
        }.reject(&:nil?).first

        if target
          if options[:singleton]
            scope = target.send :"#{self.variable_name(options)}"
          else
            scope = target.send :"#{self.variable_name(options).pluralize}"
          end
        elsif options[:shallow]
          scope = base_scope
        else
          raise "Cannot fetch #{options[:resource]} through #{options[:through]}"
        end
      else
        scope = base_scope
      end

      loaders = {
        collection: -> {
          controller.instance_variable_set(
            self.ivar_name(controller, options),
            scope
          )
        },

        new_record: -> {
          controller.instance_variable_set(
            self.ivar_name(controller, options),
            scope.new(controller.params[self.params_key_name(options)] || {})
          )
        },

        record: -> {
          key = [:"#{self.params_key_name(options)}_id", :id].map{|key| controller.params[key] }.find &:present?
          controller.instance_variable_set(
            self.ivar_name(controller, options),
            scope.find(key)
          )
        },

        related_record: -> {
          key = controller.params[:"#{self.params_key_name(options)}_id"]
          unless key.blank?
            controller.instance_variable_set(
              self.ivar_name(controller, options),
              scope.find(key)
            )
          end
        }
      }

      loaders[self.action_type(controller.params[:action], options)].()

      nil
    end

    def self.action_type(action, options)
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
          elsif options[:new_record] && options[:new_record].include?(action)
            :new_record
          else
            :record
          end
        end
      end
    end

    def self.ivar_name(controller, options)
      if action_type(controller.params[:action], options) == :collection
        :"@#{self.variable_name(options).pluralize}"
      else
        :"@#{self.variable_name(options)}"
      end
    end

    def self.variable_name(options)
      if options.kind_of? Hash
        options[:resource]
      else
        options.to_s
      end.parameterize('_')
    end

    def self.class_name(options)
      if options.kind_of? Hash
        options[:resource]
      else
        options.to_s
      end.classify
    end

    def self.params_key_name(options)
      if options.kind_of? Hash
        options[:resource]
      else
        options.to_s
      end.split('/').last
    end
  end
end
