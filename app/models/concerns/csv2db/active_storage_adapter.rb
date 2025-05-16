module Csv2db::ActiveStorageAdapter
  extend ActiveSupport::Concern

  FILE_TYPE = 'text/csv'.freeze

  included do
    has_one_attached :csv_upload
  end

  def file=(file)
    # Override Dragonfly setter method
    csv_upload.attach(
      io: file.tempfile,
      filename: file.original_filename,
      content_type: FILE_TYPE
    )
  end

  private

  def file_data
    return @file_data if @file_data.present?

    csv_upload.blob.open do |blob|
      @file_data = str_to_utf8(blob.read)
    end

    byte_order_mark = Csv2db::Import::BYTE_ORDER_MARK
    @file_data.sub!(byte_order_mark, '') if @file_data.starts_with?(byte_order_mark)

    @file_data
  end
end
