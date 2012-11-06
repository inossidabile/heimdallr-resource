module Heimdallr
  class ResourceImplementation
    def self.add_before_filter(controller_class, method, options)
      options, filter_options = Heimdallr::ResourceImplementation.prepare_options controller_class, options

      controller_class.class_eval do
        before_filter filter_options do |controller|
          Heimdallr::ResourceImplementation.new(controller, options).send(method)
        end
      end
    end

    def self.prepare_options(controller_class, options)
      options = options.dup
      options[:resource] = (options[:resource] || controller_class.name.sub(/Controller$/, '').singularize.underscore).to_s

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

      [options, filter_options]
    end

    def initialize(controller, options)
      @controller = controller
      @options = options
      @params = controller.params
    end

    def load_resource
      load_scoped @options
    end

    def load_and_authorize_resource
      load_restricted @options
      authorize_resource
    end

    def load_scoped(options)
      return if @controller.instance_variable_defined? ivar_name(options)

      scope = class_name(options).constantize.scoped
      load options, scope, :load_scoped
    end

    def load_restricted(options)
      return if @controller.instance_variable_defined? ivar_name(options)

      scope = class_name(options).constantize.restrict(@controller.security_context)
      load options, scope, :load_restricted
    end

    def authorize_resource
      resource = @controller.instance_variable_get ivar_name(@options)

      case @params[:action]
        when 'new', 'create'
          raise Heimdallr::AccessDenied, "Cannot create model" unless resource.creatable?
          resource.assign_attributes resource.reflect_on_security[:restrictions].fixtures[:create]

        when 'edit', 'update'
          raise Heimdallr::AccessDenied, "Cannot update model" unless resource.modifiable?
          resource.assign_attributes resource.reflect_on_security[:restrictions].fixtures[:update]

        when 'destroy'
          raise Heimdallr::AccessDenied, "Cannot delete model" unless resource.destroyable?
      end

      nil
    end

    def load(options, base_scope, caller)
      if options.has_key? :through
        target = Array.wrap(options[:through]).map { |parent|
          loaded = @controller.instance_variable_get(:"@#{variable_name(parent)}")
          unless loaded
            self.send caller, :resource => parent.to_s, :related => true
            loaded = @controller.instance_variable_get(:"@#{variable_name(parent)}")
          end
          loaded
        }.reject(&:nil?).first

        if target
          if options[:singleton]
            scope = target.send :"#{variable_name(options)}"
          else
            scope = target.send :"#{variable_name(options).pluralize}"
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
          @controller.instance_variable_set(
            ivar_name(options),
            scope
          )
        },

        new_record: -> {
          @controller.instance_variable_set(
            ivar_name(options),
            scope.new(@params[params_key_name(options)] || {})
          )
        },

        record: -> {
          key = [:"#{params_key_name(options)}_id", :id].map{|key| @params[key] }.find &:present?
          @controller.instance_variable_set(
            ivar_name(options),
            scope.send(options[:finder] || :find, key)
          )
        },

        related_record: -> {
          key = @params[:"#{params_key_name(options)}_id"]
          unless key.blank?
            @controller.instance_variable_set(
              ivar_name(options),
              scope.send(options[:finder] || :find, key)
            )
          end
        }
      }

      loaders[action_type(options)].()

      nil
    end

    def action_type(options)
      if options[:related]
        :related_record
      else
        action = @params[:action].to_sym
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

    def ivar_name(options)
      if action_type(options) == :collection
        :"@#{variable_name(options).pluralize}"
      else
        :"@#{variable_name(options)}"
      end
    end

    def resource_name(options)
      if options.kind_of? Hash
        options[:resource]
      else
        options.to_s
      end
    end

    def variable_name(options)
      resource_name(options).parameterize('_')
    end

    def class_name(options)
      resource_name(options).classify
    end

    def params_key_name(options)
      resource_name(options).split('/').last
    end
  end
end