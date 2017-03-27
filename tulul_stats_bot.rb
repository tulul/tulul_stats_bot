class TululStats::TululStatsBot
  def self.start
    Telegram::Bot::Client.run($token) do |bot|
      bot.listen do |message|
        TululStats::InputProcessor.perform_async(message, bot)
      end
    end
  rescue StandardError => e
    log(e.inspect)
    retry
  end

  def self.log(message)
    puts message
    #{$namespace_class}::Log.perform_async(message)
  end
end
