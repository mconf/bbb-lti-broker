class CreateRsaKeyPairsTable < ActiveRecord::Migration[6.1]
  def change
    create_table(:rsa_key_pairs, if_not_exists: true) do |t|
      t.text(:private_key)
      t.text(:public_key)
      t.string(:tool_id)

      t.timestamps
    end
  end
end
