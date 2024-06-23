require "active_support/log_subscriber"

module Railcutters::Logging::RailsExt::LogSubscriber
  class ActiveStorage < ActiveSupport::LogSubscriber
    def service_upload(event)
      info(event,
        {msg: "Uploaded file", key: key_in(event), checksum: event.payload[:checksum]}.compact_blank)
    end
    subscribe_log_level :service_upload, :info

    def service_download(event)
      info(event, {msg: "Downloaded file", key: key_in(event)})
    end
    subscribe_log_level :service_download, :info

    alias_method :service_streaming_download, :service_download

    def preview(event)
      info(event, {msg: "Previewed file", key: key_in(event)})
    end
    subscribe_log_level :preview, :info

    def service_delete(event)
      info(event, {msg: "Deleted file", key: key_in(event)})
    end
    subscribe_log_level :service_delete, :info

    def service_delete_prefixed(event)
      info(event, {msg: "Deleted files by key prefix", prefix: event.payload[:prefix]})
    end
    subscribe_log_level :service_delete_prefixed, :info

    def service_exist(event)
      debug(event, {msg: "Checked if file exists", key: key_in(event), exist: event.payload[:exist]})
    end
    subscribe_log_level :service_exist, :debug

    def service_url(event)
      debug(event, {msg: "Generated URL for file", key: key_in(event), url: event.payload[:url]})
    end
    subscribe_log_level :service_url, :debug

    def service_mirror(event)
      debug(event,
        {msg: "Mirrored file", key: key_in(event), checksum: event.payload[:checksum]}.compact_blank)
    end
    subscribe_log_level :service_mirror, :debug

    def logger
      ActiveStorage.logger
    end

    private

    def info(event, entry)
      super(prefix_for_service(event).merge(entry))
    end

    def debug(event, entry)
      super(prefix_for_service(event).merge(entry))
    end

    def prefix_for_service(event)
      {activestorage_service: event.payload[:service], duration: "#{event.duration.round}ms"}
    end

    def key_in(event)
      event.payload[:key]
    end
  end
end
