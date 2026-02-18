class AddResendFieldsToDomains < ActiveRecord::Migration[8.1]
  def change
    add_column :domains, :resend_domain_id, :string
    add_column :domains, :resend_records, :jsonb
  end
end
