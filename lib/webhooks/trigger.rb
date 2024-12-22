class Webhooks::Trigger
  SUPPORTED_ERROR_HANDLE_EVENTS = %w[message_created message_updated].freeze

  def initialize(url, payload, account, webhook_type)
    @url = url
    @payload = payload
    @account = account
    @webhook_type = webhook_type
  end

  def self.execute(url, payload, account, webhook_type)
    new(url, payload, account, webhook_type).execute
  end

  def execute
    perform_request
  rescue StandardError => e
    handle_error(e)
    Rails.logger.warn "Exception: Invalid webhook URL #{@url} : #{e.message}"
  end

  private

  def perform_request
    RestClient::Request.execute(
      method: :post,
      url: @url,
      payload: @payload.to_json,
      headers: headers,
      timeout: 5
    )
  end

  def headers
    headers = { content_type: :json, accept: :json }

    if @account.hmac_token.present?
      timestamp = Time.now.to_i.to_s
      headers['X-Chatwoot-Signature'] = generate_signature(@payload.to_json, @account.hmac_token, timestamp)
      headers['X-Chatwoot-Timestamp'] = timestamp
    end

    headers
  end

  def generate_signature(payload_body, hmac_token, timestamp)
    signature_payload = "#{timestamp}.#{payload_body}"
    OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha256'),
      hmac_token,
      signature_payload
    )
  end

  def handle_error(error)
    return unless should_handle_error?
    return unless message
    update_message_status(error)
  end

  def should_handle_error?
    @webhook_type == :api_inbox_webhook && SUPPORTED_ERROR_HANDLE_EVENTS.include?(@payload[:event])
  end

  def update_message_status(error)
    message.update!(status: :failed, external_error: error.message)
  end

  def message
    return if message_id.blank?
    @message ||= Message.find_by(id: message_id)
  end

  def message_id
    @payload[:id]
  end
end
