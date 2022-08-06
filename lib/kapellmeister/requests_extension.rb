module Kapellmeister::RequestsExtension
  def self.request_processing
    proc do |name, request_data|
      define_method name do |data = {}|
        proc { |method:, path:, body: {}, query_params: {}, mock: ''|
          return ::Kapellmeister::Base.routes_scheme_parse(mock) if (Rails.try(:env) || ENV['APP_ENV']) == 'test'

          valid_body?(data, body)
          valid_query?(data, query_params)

          full_path = generate_full_path(path, data)

          connection_by(method, full_path, data)
        }.call(**request_data)
      end
    end
  rescue NoMethodError
    raise "You need to define #{self} class with connection_by method"
  end
end

def generate_full_path(original_path, data)
  path = generate_path(original_path, data)
  [path, data.delete(:query_params)&.to_query].compact_blank!.join('?')
end

def generate_path(original_path, data)
  original_path.split('/').map do |part|
    next part unless part.include? '%<'

    data.delete(part.match(/%<(.*)>/).to_a.last.to_sym)
  end.join('/')
end

def valid_body?(data, body)
  return if body.blank? || body.is_a?(Hash)

  schema = Object.const_get(body).schema
  result = schema.(data)
  return data if result.success?

  raise ArgumentError, result.errors.to_h
end

def valid_query?(data, query)
  return if query.blank?
  required_keys = query.keys

  from_data = data.slice(*required_keys)
  data.except!(*required_keys)
  data[:query_params] ||= {}
  data[:query_params] = data[:query_params].to_h.merge!(from_data)

  diffirent_keys = data[:query_params].transform_keys(&:to_sym)
  return if required_keys.all? { |key| diffirent_keys.has_key? key.to_sym }

  raise ArgumentError, "Query params needs keys #{required_keys}"
end
