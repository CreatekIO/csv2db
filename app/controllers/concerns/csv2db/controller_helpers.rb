module Csv2db::ControllerHelpers
  extend ActiveSupport::Concern

  class FileRequired < ::Csv2db::Error
    attr_reader :klass, :params

    def initialize(klass, options)
      @klass = klass
      @params = options[:params]

      super('You did not attach a file for processing')
    end
  end

  class EnqueueFailed < ::Csv2db::Error
    attr_reader :csv_import, :params

    def initialize(import, options)
      @csv_import = import
      @params = options[:params]

      message = import.errors.full_messages.join(', ').presence || 'Failed to enqueue import'
      super(message)
    end
  end

  included do
    rescue_from 'Csv2db::ControllerHelpers::FileRequired', with: :handle_csv2db_file_required
    rescue_from 'Csv2db::ControllerHelpers::EnqueueFailed', with: :handle_csv2db_enqueue_failed
  end

  def enqueue_csv_import_and_redirect(klass, options = {}, &block)
    import = enqueue_csv_import(klass, options, &block)

    redirect_to csv2db_success_path(import), notice: csv2db_success_message(import)
  end

  def enqueue_csv_import(klass, options = {})
    permitted_params = options.fetch(:params) do 
      params.require(klass.model_name.param_key).permit(
        :file,
        *options[:extra_params]
      )
    end

    raise FileRequired.new(klass, options) if permitted_params[:file].blank?

    import = klass.new(permitted_params)
    yield(import, permitted_params) if block_given?

    raise EnqueueFailed.new(import, options) unless import.enqueue

    import
  rescue ActionController::ParameterMissing
    raise FileRequired.new(klass, options)
  end

  private

  def csv2db_success_path(_import)
    request.env['HTTP_REFERER'].presence || '/'
  end

  def csv2db_success_message(_import)
    'File has been uploaded for processing'
  end

  def handle_csv2db_file_required(error)
    redirect_to(
      request.env['HTTP_REFERER'].presence || '/',
      alert: error.message
    )
  end

  def handle_csv2db_enqueue_failed(error)
    redirect_to(
      request.env['HTTP_REFERER'].presence || '/',
      alert: error.message
    )
  end
end
