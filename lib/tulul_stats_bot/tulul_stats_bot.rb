class TululStatsBot
  @@bot = nil

  def self.start
    Telegram::Bot::Client.run($token) do |bot|
      @@bot = bot
      bot.listen do |message|
        begin
          group = TululStats::Group.get_group(message)
          user = group.get_user(message.from)

          query = /\/top_(.+)/.match(message.text).captures[0] rescue nil
          query = query.split('@')[0] rescue nil
          if /^\/last_tulul([@].+)?/.match(message.text && message.text.strip)
            res = group.top('last_tulul')
            res = 'Belum cukup data' if res.gsub("\n", '').strip.empty?
            @@bot.api.send_message(chat_id: message.chat.id, text: res, reply_to_message_id: message.message_id, parse_mode: 'HTML') rescue retry
          elsif query && (TululStats::User.fields.keys.reject{ |field| TululStats::User::EXCEPTION.include?(field) } + TululStats::Entity::ENTITY_QUERY + TululStats::IsTime::TIME_QUERY).include?(query)
            res = group.top(query)
            res = 'Belum cukup data' if res.gsub("\n", '').empty?
            @@bot.api.send_message(chat_id: message.chat.id, text: res, reply_to_message_id: message.message_id, parse_mode: 'HTML') rescue retry
          else
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

            if message.text =~ /^\/leli/
              user.inc_leliing
            end

            if message.text =~ /^\/get/
              user.inc_getting
            end

            if message.text =~ /<.*blog.*>/
              user.inc_blogging
            end

            if message.text =~ / lu.?$/
              user.inc_luing
            end

            user.inc_ch_title if message.new_chat_title
            user.inc_ch_photo unless message.new_chat_photo.empty?
            user.inc_del_photo if message.delete_chat_photo

            group.get_user(message.left_chat_member).inc_left_group if message.left_chat_member
            group.get_user(message.new_chat_member).inc_join_group if message.new_chat_member

            user.inc_text if message.text
            user.inc_audio if message.audio
            user.inc_document if message.document
            user.inc_photo unless message.photo.empty?
            user.inc_sticker if message.sticker
            user.inc_video if message.video
            user.inc_voice if message.voice
            user.inc_contact if message.contact
            user.inc_location if message.location
            user.update_attribute(:last_tulul_at, DateTime.now)

            message.entities.each do |entity|
              user.inc_mentioning if entity.type == 'mention'
              user.inc_hashtagging if entity.type == 'hashtag'
              user.inc_linking if entity.type == 'url'
              group.add_entity(message.text, entity) if TululStats::Entity::ENTITY_QUERY.include?(entity.type)
            end

            time = Time.at(message.date).utc
            group.add_hour(time.hour)
            group.add_day(time.wday)
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
