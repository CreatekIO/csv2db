module Csv2db::ActiveStorageAdapter
  require 'active_support/all'

  extend ActiveSupport::Concern
  FILE_TYPE = 'text/csv'.freeze
  LINK_MAX_EXPIRY = 7.days.to_s.freeze

  included do
    has_one_attached Csv2db.config.file_attachment_name

    validate :check_file_extension

    alias_method :file_attachment, Csv2db.config.file_attachment_name
  end

  def file=(file)
    # Override Dragonfly setter method
    return unless file.present?

    filename = file.original_filename

    file_attachment.attach(
      io: File.open(file),
      filename: filename,
      content_type: file.content_type
    )

    self.file_name = filename
  end

  def download_link(expires_in: LINK_MAX_EXPIRY)
    return unless file_attachment.present?

    set_current_host

    file_attachment.service_url(expires_in: expires_in.to_i, disposition: 'attachment')
  end

  private

  def set_current_host
    return unless %i[test local].include?(Rails.application.config.active_storage.service)

    ActiveStorage::Current.host = Csv2db.config.local_storage_host
  end

  def check_file_extension
    # very basic check of file extension
    errors.add(:file, I18n.t('shared.file_processor.incorrect_file_type')) unless file_attachment.blob.content_type == FILE_TYPE
  end

  def file_data
    return @file_data if @file_data.present?

    file_attachment.blob.open do |blob|
      @file_data = str_to_utf8(blob.read)
    end

    byte_order_mark = Csv2db::Import::BYTE_ORDER_MARK
    @file_data.sub!(byte_order_mark, '') if @file_data.starts_with?(byte_order_mark)

    @file_data
  end
end
