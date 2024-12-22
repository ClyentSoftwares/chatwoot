class AddHmacTokenToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :hmac_token, :string
  end
end
