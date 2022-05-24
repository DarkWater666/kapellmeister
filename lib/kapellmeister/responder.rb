class Kapellmeister::Responder
  Result = Struct.new(:success?, :response, :payload)
  attr_reader :response, :payload

  delegate :body, :status, to: :response

  def initialize(response, **args)
    @response = response
    @payload = args.merge(status: status) # rubocop:disable Style/HashSyntax (for support ruby 2.4+)
  end

  def result
    error = !/2\d{2}/.match?(status.to_s)

    Result.new(!error, parsed_body, payload)
  rescue JSON::ParserError => e
    Result.new(false, { message: e.message }, payload)
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
