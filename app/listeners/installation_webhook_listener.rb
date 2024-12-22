class InstallationWebhookListener < BaseListener
  def account_created(event)
    account = event.data[:account]
    payload = account.webhook_data.merge(
      event: __method__.to_s,
      users: users(event)
    )
    deliver_webhook_payloads(payload, account)
  end

  private

  def account(event)
    event.data[:account]
  end

  def users(event)
    account(event).administrators.map(&:webhook_data)
  end

  def deliver_webhook_payloads(payload, account)
    webhook_url = InstallationConfig.find_by(name: 'INSTALLATION_EVENTS_WEBHOOK_URL')&.value
    WebhookJob.perform_later(webhook_url, payload, account) if webhook_url
  end
end
