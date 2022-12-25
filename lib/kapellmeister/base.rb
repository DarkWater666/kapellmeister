module Kapellmeister::Base
  def configuration
    @configuration ||= self::Configuration.new
  end

  def report(data)
    responder.new(data)
  end

  def configure
    yield(configuration)
  end

  def logger
    @logger ||= configuration.logger
  end

  def requests
    @requests ||= generate_routes(self::ROUTES).transform_values! do |value|
      value.except!(:use_wrapper)
    end
  end

  def responder
    @responder ||= defined?(self::Responder) ? self::Responder : Kapellmeister::Responder
  end

  def self.routes_scheme_parse(path)
    template = ERB.new(File.read(path)).result
    YAML.safe_load(template, aliases: true, permitted_classes: [Symbol, Date, Time]).deep_symbolize_keys
  rescue Errno::ENOENT
    warn 'No such file or directory', path
    {}
  end
end

def generate_routes(json_scheme)
  json_scheme.dup.each_with_object({}) do |(key, value), scheme|
    scheme[key] = value.delete(:scheme) if (value.is_a?(Hash) && value.key?(:scheme)) || value.is_a?(String)
    next if value.nil? || value.length.zero?

    generate_routes(value).map { |deep_key, deep_value| mapping(deep_key, deep_value, key, scheme) }
  end
end

def mapping(deep_key, deep_value, key, scheme)
  old_path = deep_value[:path].presence || deep_key.to_s
  name = old_path.split('/').map { |part| part.gsub(/%<.*?>/, '') }.reject(&:empty?)
  deep_value[:path] = [key, old_path].join('/')

  use_wrapper = deep_value.key?(:use_wrapper) ? deep_value[:use_wrapper] : true
  new_key = if name.size == 1
              deep_key
            else
              use_wrapper ? [name.first.presence || key, deep_key].join('_').to_sym : deep_key
            end
  scheme[new_key] = deep_value
end
