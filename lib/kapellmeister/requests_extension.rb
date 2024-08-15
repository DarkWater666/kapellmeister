module Kapellmeister::RequestsExtension
  def self.request_processing(klass, (name, request_data))
    mod = if Object.const_defined?("#{self}::#{klass}InstanceMethods")
            const_get("#{self}::#{klass}InstanceMethods")
          else
            const_set(:"#{klass}InstanceMethods", Module.new)
          end

    mod.module_eval do
      define_method name do |data = {}|
        data.deep_compact!

        proc { |method:, path: nil, body: {}, query_params: {}, mock: ''|
          if (Rails.try(:env) || ENV.fetch('APP_ENV', nil)) == 'test'
            return ::Kapellmeister::Base.routes_scheme_parse(mock)
          end

          data, query_keys = *parsed_query(query_params, data)
          valid_query?(data, query_keys)
          valid_body?(data, body)

          full_path = generate_full_path(path, data)

          connection_by(method, full_path, data)
        }.call(**request_data)
      end
    end

    mod
  rescue NoMethodError
    raise "You need to define #{self} class with connection_by method"
  end
end

def parsed_query(params, data)
  return [data, []] if params.blank?

  hash_data, filtered_query = *split_hashes(params)
  required_empty_query, default_data = *hash_data.partition { |elem| elem.values.compact_blank.blank? }
  data = filtered_query.zip([]).to_h.compact_blank.merge(data) if data.is_a?(Hash)
  _optional_data, default_data = *split_optional(default_data)
  data = data.merge(default_data) if !data.blank? || !default_data.blank?

  [data, filtered_query + required_empty_query.map(&:keys).flatten + default_data.keys.flatten]
end

def split_hashes(params)
  return [[], []] if params.blank?

  case params
  when Array then params.compact_blank.partition { |elem| elem.is_a?(Hash) }
  when Hash then [[params], []]
  else [[], []]
  end
end

def split_optional(params)
  return [{}, {}] if params.blank?

  params.inject(:merge).partition { |key, _value|  key == :optional }.map(&:to_h)
end

def generate_full_path(original_path, data)
  path = generate_path(original_path, data)
  query = data.delete(:query_params)&.to_query
  return "?#{query}" if path.blank?

  [path, query].compact_blank!.join('?')
end

def generate_path(original_path, data)
  return nil unless original_path

  original_path.split('/').map do |part|
    next part unless part.include? '%<'

    data.delete(part.match(/%<(.*)>/).to_a.last.to_sym)
  end.join('/').squeeze('/')
end

def valid_body?(data, body)
  return true if body.blank? || body.is_a?(Hash)

  schema = Object.const_get(body).schema
  result = schema.call(data)
  return data if result.success?

  raise ArgumentError, result.errors.to_h
end

def valid_query?(data, query)
  return true if query.blank?

  required_keys = query.map(&:to_sym)

  from_data = data.slice(*required_keys)
  data.except!(*required_keys)
  data[:query_params] ||= {}
  data[:query_params] = data[:query_params].to_h.merge!(from_data)

  different_keys = data[:query_params].transform_keys(&:to_sym)
  return true if required_keys.all? { |key| different_keys.key? key.to_sym }

  raise ArgumentError, "Query params needs keys #{required_keys}"
end
