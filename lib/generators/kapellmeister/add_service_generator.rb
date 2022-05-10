module Kapellmeister
  class AddServiceGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    desc <<-EOF
      Prepares application to possibility to get third parties requests.
    EOF

    class_option :responder, type: :boolean, default: false

    argument :attributes, type: :array, default: [], banner: 'attribute'

    def copy_initializer_file
      template 'initializers/third_party_initializer.rb', "config/initializers/#{file_name}.rb"
    end

    def copy_base_file
      template 'lib/third_party.rb', "app/lib/#{file_name}.rb"
    end

    def copy_lib_folder
      copy_client_file
      copy_configuration_file
      copy_responder_file
      copy_routes_file
    end

    private

    def copy_client_file
      template 'lib/third_party/client.rb', "app/lib/#{file_name}/client.rb"
    end

    def copy_configuration_file
      template 'lib/third_party/configuration.rb', "app/lib/#{file_name}/configuration.rb"
    end

    def copy_responder_file
      return unless options[:responder]

      template 'lib/third_party/responder.rb', "app/lib/#{file_name}/responder.rb"
    end

    def copy_routes_file
      template 'lib/third_party/routes.yml', "app/lib/#{file_name}/routes.yml"
    end

    def initialize_signatures
      attributes.map { |attr| attr.name.to_sym }
    end
  end
end

# ROUTES = Dir['app/lib/yandex_taxi/route_scheme/**/*.yml'].each_with_object({}) do |file, result|
#   routes = ::Kapellmeister::Base.routes_scheme_parse(file)
#   result.merge!(routes)
# end
