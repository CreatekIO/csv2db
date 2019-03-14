class Csv2dbCreateCsvImports < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        if table_exists?('file_processors') || table_exists?('csv_imports')
          say 'Table already created, skipping migration'
          return
        end
      end
    end

    create_table :csv_imports do |t|
      t.string   :type
      t.string   :status
      t.string   :file_name
      t.string   :file_uid
      t.text     :log_messages, limit: 2147483647
      t.datetime :started_at
      t.datetime :completed_at
      t.text     :summary
      t.text     :params

      t.timestamps
    end
  end
end
