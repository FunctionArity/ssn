# API tokens revoked before they expire, by their jti. Rows can go once the token would have expired anyway.
class CreateJwtDenylists < ActiveRecord::Migration[8.1]
  def change
    create_table :jwt_denylists do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false

      t.timestamps
    end
    add_index :jwt_denylists, :jti, unique: true
    add_index :jwt_denylists, :exp
  end
end
