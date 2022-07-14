require 'active_record'
require 'active_support/concern'
require 'dragonfly'
require 'charlock_holmes/string'

module Csv2db
  module Import
    extend ActiveSupport::Concern

    class ImportError < StandardError; end

    RECENT_IMPORT_LIMIT = 5
    BYTE_ORDER_MARK = "\xEF\xBB\xBF".freeze

    module ClassMethods
      def before_process(*args, &block)
        set_callback :process, :before, *args, &block
      end

      def after_process(*args, &block)
        set_callback :process, :after, *args, &block
      end

      def around_process(*args, &block)
        set_callback :process, :around, *args, &block
      end
    end

    included do
      extend Dragonfly::Model

      validates :file, presence: true
      validate :required_params_are_present
      validate :check_file_extension

      dragonfly_accessor :file

      after_initialize :set_default_values, :set_required_params

      serialize :log_messages, Array
      serialize :summary, Array
      serialize :params, Hash

      scope :newest_first, -> { order(created_at: :desc) }
      scope :most_recent, -> { newest_first.limit(RECENT_IMPORT_LIMIT) }

      define_callbacks :process
    end

    module Status
      PENDING = 'pending'.freeze
      COMPLETED = 'completed'.freeze
      ABORTED = 'aborted'.freeze
      FAILED = 'failed'.freeze
    end

    def enqueue
      save && ImportWorker.perform_async(self.class.name, id)
    end

    def process
      run_callbacks :process do
        unless pending?
          log("Skipping - file is not in pending state (#{status})", :warn)
          return false
        end

        with_lock do
          log("Starting to process Import:#{id}")

          begin
            check_file_contains_data
            check_headers
            process_file
            stop if errors?
            log('Completed.')
            self.status = Status::COMPLETED
          rescue ImportError
            log(I18n.t('shared.file_processor.failed_due_to_errors'), :error)
            self.status = Status::FAILED
            raise ActiveRecord::Rollback
          rescue => e
            log('Aborted due to exception.', :error)
            log(e.message, :error)
            self.status = Status::ABORTED
            raise ActiveRecord::Rollback
          end
        end

        save!
      end
    end

    def errors?
      log_messages.any? { |msg| msg[:level] == :error }
    end

    def param(name, value = nil)
      if value.nil?
        params[name.to_s] if params.key? name.to_s
      else
        params[name.to_s] = value
      end
    end

    def summary_item(name, value, category = '')
      summary << { name: name, value: value, category: category }
    end

    def summary_categories
      summary.map { |item| item[:category] }.uniq
    end

    def summary_items_for_category(category)
      summary.select { |item| item[:category] == category }
    end

    def pending?
      status == Status::PENDING
    end

    def method_missing(method, *args, &block)
      if method.to_s.start_with?('param_')
        param_name = method.to_s.gsub(/^param_/, '').gsub(/=$/, '')
        param(param_name, *args)
      else
        super
      end
    end

    private

    def check_file_contains_data
      error(I18n.t('shared.file_processor.insufficient_rows')) unless file.data.present? && csv.count > 0
      stop if errors?
    end

    def check_headers
      check_for_required_headers
      check_for_allowed_headers
      stop if errors?
    end

    def check_for_allowed_headers
      headers = csv.headers - allowed_headers
      unless headers.empty?
        error(I18n.t('shared.file_processor.headers_not_recognised', headers: headers.join(', ')))
      end
    end

    def check_for_required_headers
      headers = required_headers - (required_headers & csv.headers)
      error(I18n.t('shared.file_processor.headers_missing', headers: headers.join(', '))) unless headers.empty?
    end

    def required_headers
      raise NotImplementedError
    end

    def allowed_headers
      required_headers
    end

    def csv
      @csv ||= CSV.parse(file_data, headers: true)
    end

    def file_data
      file_data = str_to_utf_8(file.data)
      file_data.sub!(BYTE_ORDER_MARK, '') if file_data.starts_with?(BYTE_ORDER_MARK)
      file_data
    end

    def required_params_are_present
      return if @required_params.empty?

      missing_params = @required_params.map(&:to_sym) - params.keys.map(&:to_sym)
      unless missing_params.empty?
        errors.add(
          :param, "One or more required params are missing: #{missing_params.join(', ')}"
        )
      end
    end

    def log(message, level = :info)
      log_messages << { message: str_to_utf_8(message), level: level, time: Time.now }
    end

    def error(message)
      log(message, :error)
    end

    def stop
      raise ImportError
    end

    def process_file
      raise NotImplementedError
    end

    def set_default_values
      self.log_messages ||= []
      self.status ||= Status::PENDING
    end

    def str_to_utf_8(str)
      CharlockHolmes::Converter.convert(str, str.detect_encoding[:encoding], 'UTF-8')
    end

    def set_required_params
      @required_params = []
    end

    def check_file_extension
      errors.add(:file, I18n.t('shared.file_processor.incorrect_file_type')) unless file.ext == 'csv'
    end
  end
end
