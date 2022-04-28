module Kapellmeister::RequestsExtension
  def self.request_processing
    proc do |name, request_data|
      define_method name do |data = {}|
        proc { |method:, path:, mock:| # rubocop:disable Lint/UnusedBlockArgument:
          # return mock if ENV['APP_ENV'] == 'development'

          path = path.split('/').map do |part|
            next part unless part.include? '%<'

            data.delete(part.match(/%<(.*)>/).to_a.last.to_sym)
          end.join('/')

          new.connection_by(method, path, data)
        }.call(**request_data)
      end
    end
  rescue NoMethodError
    raise "You need to define #{self} class with connection_by method"
  end

  def self.extended(base)
    base.module_parent.requests.each(&request_processing)
  end
end
