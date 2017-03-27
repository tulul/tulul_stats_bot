class TululStats::MessageSender
  include SuckerPunch::Job
  workers 5

  DEFAULT_MESSAGE_OPTIONS = {
    parse_mode: 'HTML',
    disable_web_page_preview: true
  }.freeze

  def perform(bot, options)
    options.reverse_merge!(DEFAULT_MESSAGE_OPTIONS)
    return unless options[:chat_id] && options[:text]

    options[:text].scan(/.{1,4000}/m) do |text|
      begin
        options[:text] = text
        # uncomment to log outgoing messages
        # $namespace_class.constantize.log("OUTGOING #{options.inspect}")
        bot.api.send_message(options)
        sleep(0.05)
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        $namespace_class.constantize.log('TIMEOUT')
        sleep(1.3)
        retry
      rescue Telegram::Bot::Exceptions::ResponseError => e
        $namespace_class.constantize.log(e.inspect)
        if e.message =~ /error_code: .429./
          sleep(3)
        end
        retry unless e.message =~ /error_code: .(400|403|409)./
      end
    end
  end
end
