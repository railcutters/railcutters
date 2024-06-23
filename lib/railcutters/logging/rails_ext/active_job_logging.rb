# This is a monkey patch to ActiveJob::Logging to support tagging the logger with the job ID as the
# `tid` and passing the job class name as the `job` tag.
#
# It couldn't be done in any other way other than a monkey patch due to the ancestors chain of
# ActiveJob::Logging. It's not possible to remove the `include`'d `ActiveJob::Logging` from the
# `ActiveJob::Base` class.
#
# See: https://github.com/rails/rails/blob/main/activejob/lib/active_job/logging.rb
require "active_job/logging"

module ::ActiveJob::Logging
  def perform_now
    tag_logger({job: self.class.name, job_id: job_id}, *default_tags) { super }
  end

  def tag_logger(*tags, &)
    logger.tagged(*tags, &)
  end

  private

  def default_tags
    log_tags = Rails.configuration.active_job.log_tags
    return [] unless log_tags

    Railcutters::Logging::RailsExt.process_default_tags(self, log_tags)
  end
end
