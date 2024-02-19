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
    tag_logger(job: self.class.name, tid: job_id, job_id: job_id) { super }
  end

  def tag_logger(*tags, &)
    logger.tagged(*tags, &)
  end
end
