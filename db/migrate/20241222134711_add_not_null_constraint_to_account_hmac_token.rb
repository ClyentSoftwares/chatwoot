class AddNotNullConstraintToAccountHmacToken < ActiveRecord::Migration[7.0]
  def change
    change_column_null :accounts, :hmac_token, false
  end
end
