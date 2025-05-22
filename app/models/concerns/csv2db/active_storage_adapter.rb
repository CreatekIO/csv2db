module Csv2db::ActiveStorageAdapter
  require 'active_support/all'

  extend ActiveSupport::Concern
  FILE_TYPE = 'text/csv'.freeze
  MAX_EXPIRY = 7.days.to_s.freeze

  included do
    has_one_attached :csv_upload

    validate :check_file_extension
  end

  def file=(file)
    # Override Dragonfly setter method
    return unless file.present?

    filename = file.original_filename

    csv_upload.attach(
      io: File.open(file),
      filename: filename,
      content_type: file.content_type
    )

    self.file_name = filename
  end

  def expiring_link(expires_in: MAX_EXPIRY)
    return unless csv_upload.present?

    set_current_host_if_local

    csv_upload.service_url(expires_in: expires_in.to_i, disposition: 'attachment')
  end

  private

  def set_current_host_if_local
    return unless Rails.application.config.active_storage.service == :local

    ActiveStorage::Current.host = ReportGenerator.config.local_storage_host
  end

  def check_file_extension
    # very basic check of file extension
    errors.add(:file, I18n.t('shared.file_processor.incorrect_file_type')) unless csv_upload.blob.content_type == FILE_TYPE
  end

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
