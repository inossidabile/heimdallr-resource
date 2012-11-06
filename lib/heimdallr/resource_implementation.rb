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

      filter_keys = [:only, :except]

      filter_options = filter_keys.inject({}) do |hash, key|
        hash[key] = options.delete key if options.has_key? key
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
      load_scoped @options[:resource]
    end

    def load_and_authorize_resource
      load_restricted @options[:resource]
      authorize_resource
    end

    def load_scoped(resource, related = false)
      return if @controller.instance_variable_defined? ivar_name(resource, related)

      scope = class_name(resource).constantize.scoped
      load resource, scope, :load_scoped, related
    end

    def load_restricted(resource, related = false)
      return if @controller.instance_variable_defined? ivar_name(resource, related)

      scope = class_name(resource).constantize.restrict(@controller.security_context)
      load resource, scope, :load_restricted, related
    end

    def authorize_resource
      resource = @controller.instance_variable_get ivar_name(@options[:resource])

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

    def load(resource, base_scope, caller, related)
      if !related && @options.has_key?(:through)
        target = Array.wrap(@options[:through]).map { |parent|
          loaded = @controller.instance_variable_get(:"@#{variable_name(parent)}")
          unless loaded
            self.send caller, parent, true
            loaded = @controller.instance_variable_get(:"@#{variable_name(parent)}")
          end
          loaded
        }.reject(&:nil?).first

        if target
          if @options[:singleton]
            scope = target.send :"#{variable_name(resource)}"
          else
            scope = target.send :"#{variable_name(resource).pluralize}"
          end
        elsif @options[:shallow]
          scope = base_scope
        else
          raise "Cannot fetch #{resource} through #{@options[:through]}"
        end
      else
        scope = base_scope
      end

      loaded_resource = self.send(action_type(related), scope, resource, related)
      @controller.instance_variable_set ivar_name(resource, related), loaded_resource unless loaded_resource.nil?

      nil
    end

    def collection(scope, resource, related)
      scope
    end

    def new_record(scope, resource, related)
      scope.new(@params[params_key_name(resource)] || {})
    end

    def record(scope, resource, related)
      key = [:"#{params_key_name(resource)}_id", :id].map{|key| @params[key] }.find &:present?
      scope.send(@options[:finder] || :find, key)
    end

    def related_record(scope, resource, related)
      key = @params[:"#{params_key_name(resource)}_id"]
      return nil if key.blank?
      scope.send(@options[:finder] || :find, key)
    end

    def action_type(related)
      if related
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
            if @options[:collection] && @options[:collection].include?(action)
              :collection
            elsif @options[:new_record] && @options[:new_record].include?(action)
              :new_record
            else
              :record
            end
        end
      end
    end

    def ivar_name(resource, related = false)
      name = variable_name(resource)
      name = name.pluralize if action_type(related) == :collection
      :"@#{name}"
    end

    def resource_name(resource = nil)
      (resource || @options[:resource]).to_s
    end

    def variable_name(resource = nil)
      resource_name(resource).parameterize('_')
    end

    def class_name(resource = nil)
      resource_name(resource).classify
    end

    def params_key_name(resource = nil)
      resource_name(resource).split('/').last
    end
  end
end