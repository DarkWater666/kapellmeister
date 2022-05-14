require 'faraday_middleware'

class Kapellmeister::Dispatcher
  def self.inherited(base)
    super
    base.extend(Kapellmeister::RequestsExtension)

    delegate :report, :configuration, :logger, to: base.module_parent
  end

  FailedResponse = Struct.new(:success?, :response, :payload)

  def connection_by(method_name, path, data = {}, query = {})
    additional_headers = data.delete(:headers) || {}
    requests_data = data.delete(:request) || {}

    generated_connection = connection(additional_headers:, requests_data:)

    process generated_connection.run_request(method_name.downcase.to_sym, path, data.to_json, additional_headers)
  rescue NoMethodError, NameError, RuntimeError
    raise "Library can't process method #{method_name} yet"
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    failed_response(details: e.message)
  end

  def headers
    {}
  end

  def request_options
    {}
  end

  private

  def connection(additional_headers:, requests_data:)
    ::Faraday.new(url: configuration.url,
                  headers: headers_generate(**additional_headers),
                  request: requests_generate(**requests_data)) do |faraday|
      faraday.request :json, content_type: 'application/json; charset=utf-8'
      faraday.request :multipart
      faraday.response :logger, logger
      faraday.response :json, content_type: 'application/json; charset=utf-8'
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

  def process(data)
    report(data).result
  end

  def failed_response(**args)
    FailedResponse.new(false, { message: "#{self.class} no connection" }, { status: 555, **args })
  end
end
