class MessageFinder
  DEFAULT_AFTER_LIMIT = 100
  DEFAULT_BEFORE_LIMIT = 20
  DEFAULT_BETWEEN_LIMIT = 1000
  DEFAULT_LATEST_LIMIT = 20
  MIN_LIMIT = 1
  MAX_LIMIT = 250

  def initialize(conversation, params)
    @conversation = conversation
    @params = params
  end

  def perform
    current_messages
  end

  private

  def limit_param
    return unless @params[:limit]
    [[[@params[:limit].to_i, MIN_LIMIT].max, MAX_LIMIT].min, 1].max
  end

  def conversation_messages
    @conversation.messages.includes(:attachments, :sender, sender: { avatar_attachment: [:blob] })
  end

  def messages
    return conversation_messages if @params[:filter_internal_messages].blank?
    conversation_messages.where.not('private = ? OR message_type = ?', true, 2)
  end

  def current_messages
    if @params[:after].present? && @params[:before].present?
      messages_between(@params[:after].to_i, @params[:before].to_i)
    elsif @params[:before].present?
      messages_before(@params[:before].to_i)
    elsif @params[:after].present?
      messages_after(@params[:after].to_i)
    else
      messages_latest
    end
  end

  def messages_after(after_id)
    messages.reorder('created_at asc')
           .where('id > ?', after_id)
           .limit(limit_param || DEFAULT_AFTER_LIMIT)
  end

  def messages_before(before_id)
    messages.reorder('created_at desc')
           .where('id < ?', before_id)
           .limit(limit_param || DEFAULT_BEFORE_LIMIT)
           .reverse
  end

  def messages_between(after_id, before_id)
    messages.reorder('created_at asc')
           .where('id >= ? AND id < ?', after_id, before_id)
           .limit(limit_param || DEFAULT_BETWEEN_LIMIT)
  end

  def messages_latest
    messages.reorder('created_at desc')
           .limit(limit_param || DEFAULT_LATEST_LIMIT)
           .reverse
  end
end
