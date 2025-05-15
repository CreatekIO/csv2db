module Csv2db::ActiveStorageAdapter
  extend ActiveSupport::Concern

  included do
    has_one_attached :csv_upload
  end
end
