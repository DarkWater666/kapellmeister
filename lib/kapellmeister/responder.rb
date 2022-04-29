class Kapellmeister::Responder
  Result = Struct.new(:success?, :response, :payload)
  attr_reader :response, :payload

  delegate :body, :status, to: :response

  def initialize(response, **args)
    @response = response
    @payload = args
  end

  def result
    error = !/2\d{2}/.match?(status.to_s)

    Result.new(!error, parsed_body, { status: }.merge(payload))
  rescue JSON::ParserError => e
    Result.new(false, e)
  end

  private

  def parsed_body
    return body if body.empty?

    case body
    when Hash then body
    else JSON.parse(body, symbolize_names: true, quirks_mode: true)
    end
  end
end
