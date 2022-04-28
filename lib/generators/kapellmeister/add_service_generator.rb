module Kapellmeister
  class AddServiceGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    desc <<-EOF
      Prepares application to possibility to get third parties requests.
    EOF

    class_option :responder, type: :boolean, default: false

    argument :attributes, type: :array, default: [], banner: 'attribute'

    def copy_initializer_file
      template 'initializers/add_service_initializer.rb', "config/initializers/#{file_name}.rb"
    end

    def copy_base_file
      template 'lib/add_service.rb', "app/lib/#{file_name}.rb"
    end

    def copy_lib_folder
      copy_client_file
      copy_configuration_file
      copy_responder_file
      copy_routes_file
    end

    private

    def copy_client_file
      template 'lib/add_service/client.rb', "app/lib/#{file_name}/client.rb"
    end

    def copy_configuration_file
      template 'lib/add_service/configuration.rb', "app/lib/#{file_name}/configuration.rb"
    end

    def copy_responder_file
      return unless options[:responder]

      template 'lib/add_service/responder.rb', "app/lib/#{file_name}/responder.rb"
    end

    def copy_routes_file
      template 'lib/add_service/routes.yml', "app/lib/#{file_name}/routes.yml"
    end

    def initialize_signatures
      attributes.map { |attr| attr.name.to_sym }
    end
  end
end
