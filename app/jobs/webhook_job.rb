class WebhookJob < ApplicationJob
  queue_as :medium

  def perform(url, payload, account, webhook_type = :account_webhook)
    Webhooks::Trigger.execute(url, payload, account, webhook_type)
  end
end
