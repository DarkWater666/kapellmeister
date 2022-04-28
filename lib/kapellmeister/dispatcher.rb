require 'faraday_middleware'

class Kapellmeister::Dispatcher
  def self.inherited(base)
    base.extend(RequestsExtension)

    delegate :report, :configuration, :logger, to: base.module_parent

    def custom_headers
      @custom_headers ||= try(:headers) || {}
    end

    def custom_request_options
      @custom_request_options ||= try(:request_options) || {}
    end
  end

  FailedResponse = Struct.new(:success?, :response, :payload)

  def connection_by(method, path, data = {})
    headers_params = data.delete(:headers) || {}
    requests_data = data.delete(:request) || {}

    generated_connection = connection(additional_headers: headers_params, requests_data:)

    case method.upcase.to_sym
    when :GET
      process generated_connection.get([path, data.to_query].compact_blank!.join('?'))
    when :POST
      process generated_connection.post(path, data.to_json)
    when :PUT
      process generated_connection.put(path, data.to_json)
    else
      raise "Library can't process method #{method} yet"
    end
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    failed_response(details: e.message)
  end

  private

  def connection(additional_headers:, requests_data:)
    ::Faraday.new(url: configuration.url,
                  headers: headers_generate(**additional_headers),
                  request: requests_generate(**requests_data)) do |faraday|
      faraday.request :authorization, *authorization
      faraday.request :json, content_type: 'application/json'
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
      authority: Credentials.send_it.host,
      accept: 'application/json, text/plain, */*',
      **additional,
      **custom_headers
    }
  end

  def requests_generate(**requests_data)
    {
      **requests_data,
      **custom_request_options
    }
  end

  def process(data)
    report(data).result
  end

  def failed_response(**args)
    FailedResponse.new(false, { message: "#{self.class} no connection" }, { status: 555, **args })
  end
end
