require 'faraday/follow_redirects'
require_relative 'requests_extension'

class Kapellmeister::Dispatcher
  def self.new(**args)
    main_klass = module_parent.name&.delete('::')

    module_parent.requests.each do |request|
      include Kapellmeister::RequestsExtension.request_processing(main_klass, request)
    end
    super(**args)
  end

  def self.inherited(base)
    super
    delegate :report, :logger, to: base.module_parent
  end

  FailedResponse = Struct.new(:success?, :response, :payload)

  def headers
    {}
  end

  def request_options
    {}
  end

  def query_params
    {}
  end

  def configuration
    self.class.module_parent.configuration
  end

  private

  def connection_by(method_name, path, data = {})
    additional_headers = data.delete(:headers) || {}
    requests_data = data.delete(:request) || {}
    data_json = data.blank? ? '' : data.to_json

    generated_connection = connection(additional_headers: additional_headers, requests_data: requests_data) # rubocop:disable Style/HashSyntax (for support ruby 2.4+)

    process generated_connection.run_request(method_name.downcase.to_sym,
                                             url_with_params(path, data, method_name),
                                             data_json,
                                             additional_headers)

  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    failed_response(details: e.message)
  end

  def connection(additional_headers:, requests_data:)
    @connection ||= ::Faraday.new(url: configuration.url,
                                  headers: headers_generate(**additional_headers),
                                  request: requests_generate(**requests_data)) do |faraday|
      faraday.request :json, content_type: 'application/json; charset=utf-8'
      faraday.request :multipart
      faraday.response :logger, logger
      faraday.response :json, content_type: 'application/json; charset=utf-8'
      faraday.response :follow_redirects
      faraday.adapter :typhoeus do |http|
        http.timeout = 20
      end
    end
  end

  def headers_generate(**additional)
    {
      # accept: 'application/json, text/plain, */*, charset=utf-8',
      **additional,
      **headers
    }
  end

  def requests_generate(**requests_data)
    {
      **requests_data,
      **request_options
    }
  end

  def path_generate(path)
    path.query_parameters
  end

  def process(data)
    report(data).result
  end

  def url_with_params(url, data, method_name)
    url = url.split('/').map do |url_part|
      url_part.ascii_only? ? url_part : CGI.escape(url_part)
    end.join('/')

    url = url_repacking(url, data) if method_name == 'GET'

    return url if query_params.blank?

    url_repacking(url, query_params)
  end

  def url_repacking(url, queries)
    uri = URI(url)
    params = URI.decode_www_form(uri.query || '').to_h.merge(queries)
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def failed_response(**args)
    FailedResponse.new(false, { message: "#{self.class} no connection" }, { status: 555, **args })
  end
end
