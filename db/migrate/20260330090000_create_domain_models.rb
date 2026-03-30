class CreateDomainModels < ActiveRecord::Migration[7.1]
  def change
    create_table :hotels do |t|
      t.string :name, null: false
      t.string :timezone, null: false

      t.timestamps
    end

    create_table :guests do |t|
      t.references :hotel, null: false, foreign_key: true
      t.string :room_number
      t.string :name, null: false
      t.string :identifier_token, null: false

      t.timestamps
    end
    add_index :guests, :identifier_token

    create_table :staffs do |t|
      t.references :hotel, null: false, foreign_key: true
      t.integer :role, null: false, default: 2
      t.string :name, null: false
      t.string :email, null: false

      t.timestamps
    end

    create_table :departments do |t|
      t.references :hotel, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    create_table :conversations do |t|
      t.references :guest, null: false, foreign_key: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :sender_type, null: false
      t.text :content, null: false

      t.timestamps
    end

    create_table :tickets do |t|
      t.references :guest, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true
      t.references :staff, null: true, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :priority, null: false, default: 1

      t.timestamps
    end

    create_table :knowledge_base_articles do |t|
      t.references :hotel, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.string :category
      t.boolean :published, null: false, default: false

      t.timestamps
    end
  end
end
