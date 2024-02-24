require "active_support/log_subscriber"
require "active_job/base"

module Railcutters::Logging::RailsExt::LogSubscriber
  class ActiveJob < ActiveSupport::LogSubscriber
    class_attribute :backtrace_cleaner, default: ActiveSupport::BacktraceCleaner.new

    def enqueue(event)
      job = event.payload[:job]
      ex = event.payload[:exception_object] || job.enqueue_error

      if ex
        error(msg(event, "Failed enqueuing", error_msg(ex)))
      elsif event.payload[:aborted]
        info(msg(event, "Failed enqueuing: a before_enqueue callback halted the enqueuing execution", error_msg(ex)))
      else
        info(msg(event, "Enqueued"))
      end
    end
    subscribe_log_level :enqueue, :info

    alias_method :enqueue_at, :enqueue
    subscribe_log_level :enqueue_at, :info

    def enqueue_all(event)
      jobs = event.payload[:jobs]
      adapter = ::ActiveJob.adapter_name(event.payload[:adapter])
      enqueued_count = event.payload[:enqueued_count]
      failures_count = jobs.size - enqueued_count
      job_classes = jobs.select(&:successfully_enqueued?)
        .map(&:class).tally.sort_by { |_k, v| -v }
        .map { |klass, count| "#{klass}(#{count})" }.join(", ")

      details = {enqueued_count:, failures_count:, jobs: job_classes, adapter:}

      if failures_count > 0
        warn(msg: "Enqueued jobs with failures", **details)
      else
        info(msg: "Enqueued jobs", **details)
      end
    end
    subscribe_log_level :enqueue_all, :info

    def perform_start(event)
      info do
        enqueued_at = self.enqueued_at(event)
        msg(event, "Performing job", enqueued_at:)
      end
    end
    subscribe_log_level :perform_start, :info

    def perform(event)
      ex = event.payload[:exception_object]
      duration = "#{event.duration.round(2)}ms"
      enqueued_at = self.enqueued_at(event)

      if ex
        error(msg(event, "Error performing job", {enqueued_at:, duration:, **error_msg(ex)}))
      elsif event.payload[:aborted]
        info(msg(event, "Job not performed: a before_perform callback halted the job execution",
          {enqueued_at:, duration:, **error_msg(ex)}))
      else
        info(msg(event, "Performed job", {enqueued_at:, duration:}))
      end
    end
    subscribe_log_level :perform, :info

    def enqueue_retry(event)
      ex = event.payload[:error]
      wait = event.payload[:wait]

      info(msg(event, "Retrying job", {attempts:, wait:, **error_msg(ex)}))
    end
    subscribe_log_level :enqueue_retry, :info

    def retry_stopped(event)
      ex = event.payload[:error]

      error(msg(event, "Stopped retrying job", {attempts:, **error_msg(ex)}))
    end
    subscribe_log_level :enqueue_retry, :error

    def discard(event)
      ex = event.payload[:error]

      error(msg(event, "Discarded job due to error", error_msg(ex)))
    end
    subscribe_log_level :discard, :error

    private

    def msg(event, msg, extra = {})
      job = event.payload[:job]
      scheduled_at = Time.at(job.scheduled_at).utc if job.scheduled_at
      queue = ::ActiveJob.adapter_name(event.payload[:adapter]) + "(#{job.queue_name})"

      additional = {
        args: args_info(job),
        scheduled_at:
      }.compact_blank

      {
        msg:,
        **job_data(job),
        queue:,
        **additional,
        **extra
      }
    end

    def error_msg(exception)
      return {} unless exception

      {
        exception: exception.class,
        error: exception.message,
        location: backtrace_cleaner.clean(exception.backtrace).first
      }
    end

    def job_data(job)
      {job: job.class.name, job_id: job.job_id}
    end

    def enqueued_at(event)
      job = event.payload[:job]
      Time.at(job.enqueued_at).utc if event.payload[:job].enqueued_at
    end

    def args_info(job)
      if job.class.log_arguments? && job.arguments.any?
        job.arguments.map { |arg| format(arg).inspect }.join(", ")
      end
    end

    def format(arg)
      case arg
      when Hash
        arg.transform_values { |value| format(value) }
      when Array
        arg.map { |value| format(value) }
      when GlobalID::Identification
        begin
          arg.to_global_id
        rescue
          arg
        end
      else
        arg
      end
    end

    def logger
      ::ActiveJob::Base.logger
    end

    def info(entry = nil, &)
      entry = yield if block_given?
      entry.merge!(log_enqueue_source) if ::ActiveJob.verbose_enqueue_logs
      super
    end

    def warn(entry = nil, &)
      entry = yield if block_given?
      entry.merge!(log_enqueue_source) if ::ActiveJob.verbose_enqueue_logs
      super
    end

    def error(entry = nil, &)
      entry = yield if block_given?
      entry.merge!(log_enqueue_source) if ::ActiveJob.verbose_enqueue_logs
      super
    end

    def log_enqueue_source
      source = backtrace_cleaner.clean(caller.lazy).first
      source ? {source:} : {}
    end
  end
end
