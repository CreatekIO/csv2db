module Csv2db::DragonflyAdapter
  extend ActiveSupport::Concern
  require 'dragonfly'

  included do
    extend Dragonfly::Model

    dragonfly_accessor :file

    validate :check_file_extension
    validates :file, presence: true
  end

  def check_file_extension
    # very basic check of file extension
    errors.add(:file, I18n.t('shared.file_processor.incorrect_file_type')) unless file.ext == 'csv'
  end
end
