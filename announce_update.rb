load 'Rakefile'

updates = "latest updates:\n"
updates += "- updated gem to Telegram Bot API 2.0 and adapted changes\n"
updates += "- /top_mentioning and /top_mention\n"
updates += "- /top_hashtagging and /top_hashtag\n"
updates += "- /top_linking and /top_url"
groups = TululStats::Group.all.map(&:group_id).uniq
Telegram::Bot::Client.run($token) do |bot|
  groups.each do |g|
    bot.api.send_message(chat_id: g, text: updates) rescue nil
  end
end
