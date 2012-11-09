module Heimdallr
  class ResourceImplementation
    def self.add_before_filter(controller_class, method, options)
      options, filter_options = Heimdallr::ResourceImplementation.prepare_options controller_class, options

      controller_class.class_eval do
        before_filter filter_options do |controller|
          Heimdallr::ResourceImplementation.new(controller, options).send method
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
    end

    def load_resource
      ResourceLoader.new(@options[:resource], @controller, @options).load
    end

    def load_and_authorize_resource
      resource = ResourceLoader.new(@options[:resource], @controller, @options, :restricted => true).load
      authorize_resource resource unless @controller.send :skip_authorization_check?
      resource
    end

    def authorize_resource(resource)
      case @controller.params[:action]
      when 'new', 'create'
        raise Heimdallr::AccessDenied, "Cannot create model" unless resource.creatable?
        resource.assign_attributes resource.reflect_on_security[:restrictions].fixtures[:create]

      when 'edit', 'update'
        raise Heimdallr::AccessDenied, "Cannot update model" unless resource.modifiable?
        resource.assign_attributes resource.reflect_on_security[:restrictions].fixtures[:update]

      when 'destroy'
        raise Heimdallr::AccessDenied, "Cannot delete model" unless resource.destroyable?
      end
    end

    class ResourceLoader
      def initialize(resource, controller, options, loader_options = {})
        @restricted = loader_options[:restricted]
        @parent = loader_options[:parent]
        @resource = resource
        @controller = controller
        @options = options
        @params = controller.params
      end

      def load
        return if @controller.instance_variable_defined? ivar_name

        if @restricted
          base_scope = class_name.constantize.restrict(@controller.security_context)
        else
          base_scope = class_name.constantize.scoped
        end

        if !@parent && @options.has_key?(:through)
          parent_resource = Array.wrap(@options[:through]).map { |parent|
            r = @controller.instance_variable_get "@#{variable_name parent}"
            r ||= ResourceLoader.new(parent, @controller, @options, :restricted => @restricted, :parent => true).load
          }.reject(&:nil?).first

          if parent_resource
            if @options[:through_association]
              scope = parent_resource.send @options[:through_association]
            elsif @options[:singleton]
              scope = parent_resource.send :"#{variable_name}"
            else
              scope = parent_resource.send :"#{variable_name.pluralize}"
            end
          elsif @options[:shallow]
            scope = base_scope
          else
            raise "Cannot fetch #{@resource} through #{@options[:through]}"
          end
        else
          scope = base_scope
        end

        resource = self.send action_type, scope
        @controller.instance_variable_set ivar_name, resource unless resource.nil?
        resource
      end

      def collection(scope)
        scope
      end

      def new_resource(scope)
        if @options[:singleton] && !@options[:shallow]
          scope.assign_attributes @params[params_key_name] || {}
          scope
        else
          scope.new @params[params_key_name] || {}
        end
      end

      def resource(scope)
        if @options[:singleton] && !@options[:shallow]
          scope
        else
          key = [:"#{params_key_name}_id", :id].map{|key| @params[key] }.find &:present?
          scope.send(@options[:finder] || :find, key)
        end
      end

      def parent_resource(scope)
        key = @params[:"#{params_key_name}_id"]
        return if key.blank?
        scope.send(@options[:finder] || :find, key)
      end

      def action_type
        if @parent
          :parent_resource
        else
          case action = @params[:action].to_sym
          when :index
            :collection
          when :new, :create
            :new_resource
          when :show, :edit, :update, :destroy
            :resource
          else
            if @options[:collection] && @options[:collection].include?(action)
              :collection
            elsif @options[:new_record] && @options[:new_record].include?(action)
              :new_resource
            else
              :resource
            end
          end
        end
      end

      def ivar_name
        name = (@options[:instance_name] || variable_name).to_s
        name = name.pluralize if action_type == :collection
        :"@#{name}"
      end

      def resource_name(resource = nil)
        (resource || @resource).to_s
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
end