module Csv2db::DragonflyAdapter
  extend ActiveSupport::Concern
  require 'dragonfly'

  included do
    extend Dragonfly::Model

    dragonfly_accessor :file

    validates :file, presence: true
    validate :check_file_extension
  end

  def check_file_extension
    # very basic check of file extension
    errors.add(:file, I18n.t('shared.file_processor.incorrect_file_type')) unless file.ext == 'csv'
  end

  def file_data
    file_data = str_to_utf8(file.data)
    byte_order_mark = Csv2db::Import::BYTE_ORDER_MARK
    file_data.sub!(byte_order_mark, '') if file_data.starts_with?(byte_order_mark)
    file_data
  end
end
