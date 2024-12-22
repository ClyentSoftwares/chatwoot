class BackfillAccountHmacTokens < ActiveRecord::Migration[7.0]
  def up
    Account.find_each do |account|
      account.update_column(:hmac_token, SecureRandom.hex(32))
    end
  end

  def down
    Account.update_all(hmac_token: nil)
  end
end
