class TululStatsBot
  @@bot = nil

  def self.start
    Telegram::Bot::Client.run($token) do |bot|
      @@bot = bot
      bot.listen do |message|
        begin
          group = TululStats::Group.get_group(message)
          user = group.get_user(message.from)

          user.inc_message

          if message.reply_to_message
            user.inc_replying
            group.get_user(message.reply_to_message.from).inc_replied

            if message.text =~ /#qt/i
              user.inc_qting
              group.get_user(message.reply_to_message.from).inc_qted
            end
          end

          if message.forward_from
            user.inc_forwarding
            group.get_user(message.forward_from).inc_forwarded
          end

          user.inc_ch_title if message.new_chat_title
          user.inc_ch_photo unless message.new_chat_photo.empty?
          user.inc_del_photo if message.delete_chat_photo

          group.get_user(message.left_chat_participant).inc_left_group if message.left_chat_participant
          group.get_user(message.new_chat_participant).inc_join_group if message.new_chat_participant

          user.inc_text if message.text
          user.inc_audio if message.audio
          user.inc_document if message.document
          user.inc_photo unless message.photo.empty?
          user.inc_sticker if message.sticker
          user.inc_video if message.video
          user.inc_voice if message.voice
          user.inc_contact if message.contact
          user.inc_location if message.location

          query = /\/top_(.+)/.match(message.text).captures[0] rescue nil
          query = query.split('@')[0] rescue nil
          if query && TululStats::User.fields.except(TululStats::User::EXCEPTION).keys.include?(query)
            res = group.top(query)
            res = 'Belum cukup data' if res.gsub("\n", '').empty?
            @@bot.api.send_message(chat_id: message.chat.id, text: res, reply_to_message_id: message.message_id) rescue retry
          end
        rescue StandardError => e
          puts e.message
          puts e.backtrace.select{ |err| err =~ /tulul/ }.join(',')
        end
      end
    end
  rescue StandardError => e
    puts e.message
    puts e.backtrace.select{ |err| err =~ /tulul/ }.join(',')
    retry
  end
end
