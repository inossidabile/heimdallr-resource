module Heimdallr
  class ResourceImplementation
    def self.add_before_filter(controller_class, method, options)
      options, filter_options = Heimdallr::ResourceImplementation.prepare_options controller_class, options
      controller_class.send :own_heimdallr_options=, options

      controller_class.class_eval do
        before_filter filter_options do |controller|
          Heimdallr::ResourceImplementation.new(controller, options).send method
        end
      end
    end

    def self.prepare_options(controller_class, options)
      options = options.dup
      options[:resource] ||= controller_class.name.sub(/Controller$/, '').singularize.underscore

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
      ResourceLoader.new(@controller, false, @options).load
    end

    def load_and_authorize_resource
      resource = ResourceLoader.new(@controller, true, @options).load
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
      def initialize(controller, restricted, options)
        @controller = controller
        @restricted = restricted
        @options = options
        @params = controller.params
      end

      def load
        return @controller.instance_variable_get(ivar_name) if @controller.instance_variable_defined? ivar_name

        if !@options[:parent] && @options.has_key?(:through)
          parent_resource = load_parent
          raise "Cannot fetch #{@options[:resource]} through #{@options[:through]}" unless parent_resource || @options[:shallow]
        else
          parent_resource = nil
        end

        resource = self.send action_type, resource_scope(parent_resource), parent_resource
        @controller.instance_variable_set ivar_name, resource unless resource.nil?
        resource
      end

      def load_parent
        Array.wrap(@options[:through]).map { |parent|
          ResourceLoader.new(@controller, @restricted, :resource => parent, :parent => true).load
        }.reject(&:nil?).first
      end

      def resource_scope(parent_resource)
        if parent_resource
          if @options[:through_association]
            parent_resource.send @options[:through_association]
          elsif @options[:singleton]
            parent_resource.send :"#{variable_name}"
          else
            parent_resource.send :"#{variable_name.pluralize}"
          end
        else
          if @restricted
            class_name.constantize.restrict(@controller.security_context)
          else
            class_name.constantize.scoped
          end
        end
      end

      def collection(scope, parent_resource)
        scope
      end

      def new_resource(scope, parent_resource)
        attributes = @params[params_key_name] || {}

        if @options[:singleton] && parent_resource
          if scope.nil?
            parent_resource.send singleton_builder_name, attributes
          else
            scope.assign_attributes attributes
            scope
          end
        else
          scope.new attributes
        end
      end

      def resource(scope, parent_resource)
        if @options[:singleton] && parent_resource
          scope
        else
          key = [:"#{params_key_name}_id", :id].map{|key| @params[key] }.find &:present?
          scope.send(@options[:finder] || :find, key)
        end
      end

      def parent_resource(scope, parent_resource)
        key = @params[:"#{params_key_name}_id"]
        return if key.blank?
        scope.send(@options[:finder] || :find, key)
      end

      def action_type
        if @options[:parent]
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

      def resource_name
        @options[:resource].to_s
      end

      def variable_name
        resource_name.parameterize('_')
      end

      def class_name
        resource_name.classify
      end

      def params_key_name
        resource_name.split('/').last
      end

      def singleton_builder_name
        :"build_#{@options[:through_association] || variable_name}"
      end
    end
  end
end
