require "active_support/log_subscriber"
require "active_job/base"

module Railcutters::Logging::RailsExt::LogSubscriber
  class ActiveJob < ActiveSupport::LogSubscriber
    class_attribute :backtrace_cleaner, default: ActiveSupport::BacktraceCleaner.new

    def enqueue(event)
      job = event.payload[:job]
      ex = event.payload[:exception_object] || job.enqueue_error

      if ex
        error({msg: "Failed enqueuing", queue: queue_name(event)}.merge(exception_details(ex)))
      elsif event.payload[:aborted]
        info(
          msg: "Failed enqueuing: a before_enqueue callback halted the enqueuing execution",
          queue: queue_name(event)
        )
      else
        info({
          msg: "Enqueued",
          queue: queue_name(event),
          args: args_info(job),
          scheduled_at: scheduled_at(event)
        }.compact_blank)
      end
    end
    subscribe_log_level :enqueue, :info

    alias_method :enqueue_at, :enqueue
    subscribe_log_level :enqueue_at, :info

    def enqueue_all(event)
      info do
        jobs = event.payload[:jobs]
        adapter = event.payload[:adapter]
        enqueued_count = event.payload[:enqueued_count]
        failures_count = jobs.size - enqueued_count
        adapter_name = ::ActiveJob.adapter_name(adapter)
        job_classes = enqueued_jobs
          .map(&:class).tally.sort_by { |_k, v| -v }
          .map { |klass, count| "#{klass}(#{count})" }.join(", ")

        if enqueued_count == jobs.size
          {msg: "Enqueued jobs", enqueued_count:, jobs: job_classes, adapter: adapter_name}
        elsif jobs.any?(&:successfully_enqueued?)
          successes_count = jobs.select(&:successfully_enqueued?)

          if failures_count == 0
            {msg: "Enqueued jobs", enqueued_count:, jobs: job_classes, adapter: adapter_name}
          else
            {msg: "Enqueued jobs with failures", enqueued_count:, successes_count:, failures_count:,
             jobs: job_classes, adapter: adapter_name}
          end
        else
          {msg: "Failed enqueuing jobs", enqueued_count:, failures_count:,
           jobs: job_classes, adapter: adapter_name}
        end
      end
    end
    subscribe_log_level :enqueue_all, :info

    def perform_start(event)
      info do
        job = event.payload[:job]
        enqueued_at = job.enqueued_at.utc.iso8601(9) if job.enqueued_at.present?
        queue = queue_name(event)

        {msg: "Performing job", args: args_info(job), queue:, enqueued_at:}.compact_blank
      end
    end
    subscribe_log_level :perform_start, :info

    def perform(event)
      ex = event.payload[:exception_object]

      if ex
        error({msg: "Error performing job", queue: queue_name(event),
               duration: "#{event.duration.round(2)}ms"}.merge(exception_details(ex)))
      elsif event.payload[:aborted]
        error(
          msg: "Error performing job: a before_perform callback halted the job execution",
          queue: queue_name(event),
          duration: "#{event.duration.round(2)}ms"
        )
      else
        info(
          msg: "Performed job", queue: queue_name(event), duration: "#{event.duration.round(2)}ms"
        )
      end
    end
    subscribe_log_level :perform, :info

    def enqueue_retry(event)
      job = event.payload[:job]
      ex = event.payload[:error]
      wait = event.payload[:wait]

      info do
        if ex
          {
            msg: "Retrying job",
            attempts: job.executions,
            wait: "#{wait.to_i}s"
          }.merge(exception_details(ex))
        else
          {msg: "Retrying job", attempts: job.executions, wait: "#{wait.to_i}s"}
        end
      end
    end
    subscribe_log_level :enqueue_retry, :info

    def retry_stopped(event)
      job = event.payload[:job]
      ex = event.payload[:error]

      error({msg: "Stopped retrying", attempts: job.executions}.merge(exception_details(ex)))
    end
    subscribe_log_level :enqueue_retry, :error

    def discard(event)
      ex = event.payload[:error]

      error({msg: "Discarded job due to error"}.merge(exception_details(ex)))
    end
    subscribe_log_level :discard, :error

    private

    def queue_name(event)
      ::ActiveJob.adapter_name(event.payload[:adapter]) + "(#{event.payload[:job].queue_name})"
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

    def scheduled_at(event)
      return unless event.payload[:job].scheduled_at
      Time.at(event.payload[:job].scheduled_at).utc
    end

    def logger
      ::ActiveJob::Base.logger
    end

    def info(entry = nil, &)
      entry = yield if block_given?
      entry.merge!(log_enqueue_source) if ::ActiveJob.verbose_enqueue_logs
      super
    end

    def error(entry = nil, &)
      entry = yield if block_given?
      entry.merge!(log_enqueue_source) if ::ActiveJob.verbose_enqueue_logs
      super
    end

    def exception_details(exception)
      {
        exception: exception.class,
        error: exception.message,
        location: backtrace_cleaner.clean(exception.backtrace).first
      }
    end

    def log_enqueue_source
      source = backtrace_cleaner.clean(caller.lazy).first
      source ? {source:} : {}
    end
  end
end
