class TululStatsBot
  @@bot = nil

  ALLOWED_GROUPS = -> { $redis.lrange('tulul_stats::allowed_groups', 0, -1) }
  ALLOWED_DELAY = -> { (res = $redis.get('tulul_stats::allowed_delay')) ? res.to_i : 20 }

  def self.start
    Telegram::Bot::Client.run($token) do |bot|
      @@bot = bot
      bot.listen do |message|
        begin
          if !message
          elsif message.text =~ /\/chat_id/
            send(chat_id: message.chat.id, text: message.chat.id)
          elsif message.from.username == 'araishikeiwai' && message.chat.type == 'private'
            if message.text == '/list'
              list_groups(message.chat.id)
            elsif message.text =~ /\/set_allow/
              group_id = message.text.split(' ')[1]
              group_id && $redis.set("tulul_stats::allowed_groups::#{group_id}", 1)
              list_groups(message.chat.id)
            elsif message.text =~ /\/set_disallow/
              group_id = message.text.split(' ')[1]
              group_id && $redis.del("tulul_stats::allowed_groups::#{group_id}")
              list_groups(message.chat.id)
            else
              query, group_id, *options = message.text.gsub('/', '').split(' ')
              options = Hash[*options.map{ |opt| [opt.to_sym, true] }.flatten]
              options.merge!({ from_id: 78028868 })
              if valid_query(query) && allowed_group?(group_id)
                group = TululStats::Group.find_by(group_id: group_id.to_i)
                res = group.top(query, options)
                res = 'Belum cukup data' if res.gsub("\n", '').empty?
                res = "Stats #{query} for #{group.title}:\n" + res
                send(chat_id: message.chat.id, text: res, reply_to_message_id: message.message_id)
                sleep(0.2)
              end
            end
          elsif allowed_group?(message.chat.id)
            group = TululStats::Group.get_group(message)
            user = group.get_user(message.from)

            queries = /\/top_(.+)/.match(message.text).captures[0] rescue nil
            query = queries.split(' ')[0].split('@')[0] rescue nil
            if /^\/last_tulul([@].+)?/.match(message.text && message.text.strip)
              res = group.top('last_tulul')
              res = 'Belum cukup data' if res.gsub("\n", '').strip.empty?
              send(chat_id: message.chat.id, text: res, reply_to_message_id: message.message_id) if tulul?(message) && Time.now.to_i - message.date < ALLOWED_DELAY.call
            elsif valid_query(query)
              options = queries.split(' ')[1..-1]
              options = Hash[*options.map{ |opt| [opt.to_sym, true] }.flatten]
              options.merge!({ from_id: user.user_id })
              res = group.top(query, options)
              res = 'Belum cukup data' if res.gsub("\n", '').empty?
              send(chat_id: message.chat.id, text: res, reply_to_message_id: message.message_id) if Time.now.to_i - message.date < ALLOWED_DELAY.call
            else
              user.inc_message

              if message.reply_to_message
                user.inc_replying
                group.get_user(message.reply_to_message.from).inc_replied

                if message.text =~ /#qt/i
                  user.inc_qting
                  qted = message.reply_to_message.forward_from || message.reply_to_message.from
                  group.get_user(qted).inc_qted
                end
              end

              if message.forward_from
                user.inc_forwarding
                group.get_user(message.forward_from).inc_forwarded
              end

              if message.text =~ /^\/leli/
                user.inc_leliing
              end

              if message.text =~ /^\/kbbi/
                user.inc_kbbiing
              end

              if message.text =~ /^\/slang/
                user.inc_slanging
              end

              if message.text =~ /^\/get/
                user.inc_getting
              end

              if message.text =~ /<.*blog.*>/i || message.text =~ /%blog/i
                if message.reply_to_message
                  group.get_user(message.reply_to_message.from).inc_blogging
                else
                  user.inc_blogging
                end
              end

              if message.text =~ / lu[^A-Za-z]*$/i
                user.inc_luing
              end

              if message.text =~ /\d+k?\+* shitty messages?/i
                user.inc_latecomer
              end

              if message.text =~ /#honestquestion/i
                if message.reply_to_message
                  group.get_user(message.reply_to_message.from).inc_honest_asker
                else
                  user.inc_honest_asker
                end
              end

              if message.new_chat_title
                old_title, new_title = group.update_title!(message.chat.title)

                old_title.gsub!(/H-\d+/, '')
                new_title.gsub!(/H-\d+/, '')
                title_changed = old_title != new_title

                user.inc_ch_title
                res = '#TululTitle'
                unless group.last_title_change == -1 || !title_changed
                  t = message.date - group.last_title_change
                  mm, ss = t.divmod(60)
                  hh, mm = mm.divmod(60)
                  dd, hh = hh.divmod(24)
                  time = "%dd %dh %dm %ds" % [dd, hh, mm, ss]
                  res += "\nPrevious title lifetime: #{time}"
                end
                send(chat_id: message.chat.id, text: res) if tulul?(message) && Time.now.to_i - message.date < ALLOWED_DELAY.call
                group.update_attribute(:last_title_change, message.date) if title_changed || group.last_title_change == -1
              end

              unless message.new_chat_photo.empty?
                user.inc_ch_photo
                res = "Hey guys, #{user.username_or_full_name} just fixed the aikon! #TululPhoto"
                unless group.last_photo_change == -1
                  t = message.date - group.last_photo_change
                  mm, ss = t.divmod(60)
                  hh, mm = mm.divmod(60)
                  dd, hh = hh.divmod(24)
                  time = "%dd %dh %dm %ds" % [dd, hh, mm, ss]
                  res += "\nPrevious photo lifetime: #{time}"
                end
                send(chat_id: message.chat.id, text: res) if tulul?(message) && Time.now.to_i - message.date < ALLOWED_DELAY.call
                group.update_attribute(:last_photo_change, message.date)
              end

              if message.delete_chat_photo
                user.inc_del_photo
                res = "Hey guys, #{user.username_or_full_name} just abolished the aikon! #TululPhoto"
                unless group.last_photo_change == -1
                  t = message.date - group.last_photo_change
                  mm, ss = t.divmod(60)
                  hh, mm = mm.divmod(60)
                  dd, hh = hh.divmod(24)
                  time = "%dd %dh %dm %ds" % [dd, hh, mm, ss]
                  res += "\nPrevious photo lifetime: #{time}"
                end
                send(chat_id: message.chat.id, text: res) if tulul?(message) && Time.now.to_i - message.date < ALLOWED_DELAY.call
                group.update_attribute(:last_photo_change, message.date)
              end

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
              user.update_attribute(:last_tulul_at, DateTime.strptime(message.date.to_s, "%s"))

              message.entities.each do |entity|
                user.inc_mentioning if entity.type == 'mention'
                user.inc_hashtagging if entity.type == 'hashtag'
                user.inc_linking if entity.type == 'url'
                group.add_entity(message.text, entity) if TululStats::Entity::ENTITY_QUERY.include?(entity.type)
              end

              time = Time.at(message.date).utc
              group.add_hour(time.hour)
              group.add_day(time.wday)
              user.add_hour(time.hour)
              user.add_day(time.wday)

              if tulul?(message) && message.text =~ /mau nge-?blog/i && Time.now.to_i - message.date < ALLOWED_DELAY.call
                send(chat_id: message.chat.id, text: 'どうぞ')
              end

              if tulul?(message) && message.text&.gsub(/[^A-Za-z]/, '') =~ /^h+a+h+$/i && Time.now.to_i - message.date < ALLOWED_DELAY.call
                user.inc_keong_caller
                group.users.find_by(user_id: 88878925).inc_forwarded
                @@bot.api.forward_message(chat_id: message.chat.id, from_chat_id: -12126542, message_id: 102972)
              end
            end
          else
            send(chat_id: message.chat.id, text: "You're not allowed to use this bot in your group yet, please message @araishikeiwai to ask for permission. For now, please remove the bot from the group") if Time.now.to_i - message.date < ALLOWED_DELAY.call
          end
        end
      end
    end
  rescue Faraday::TimeoutError => e
    puts Time.now.utc
    puts 'TIMEOUT'
    sleep(2)
    retry
  rescue Telegram::Bot::Exceptions::ResponseError => e
    puts Time.now.utc
    puts e.message
    puts e.backtrace.select{ |err| err =~ /tulul/ }.join(', ')

    if e.message =~ /429/
      sleep(3)
    elsif e.message =~ /502/
      sleep(10)
    end
    retry unless e.message =~ /error_code: .[400|403|409]./
  rescue StandardError => e
    err = e.message + "\n"
    err += e.backtrace.select{ |err| err =~ /tulul/ }.join(', ') + "\n"
    err += Time.now.utc.to_s
    @@bot.api.send_message(chat_id: TululStats::User.find_by(username: 'araishikeiwai').user_id, text: "EXCEPTION! CHECK SERVER! \n\n#{err}")
    retry
  end

  def self.send(options)
    retry_count = 0
    begin
      options.merge!({
        parse_mode: 'HTML',
        disable_web_page_preview: true
      })
      @@bot.api.send_message(options)
    rescue Faraday::TimeoutError => e
      puts Time.now.utc
      puts 'TIMEOUT'
      sleep(2)
      retry
    rescue Telegram::Bot::Exceptions::ResponseError => e
      puts Time.now.utc
      puts e.message
      puts e.backtrace.select{ |err| err =~ /tulul/ }.join(', ')
      puts "retrying: #{retry_count}"

      if e.message =~ /429/
        sleep(3)
      end
      retry if e.message !~ /error_code: .[400|403|409]./ && (retry_count += 1) < 20
    end
  end

  def self.valid_query(query)
    query && (TululStats::User.fields.keys.reject{ |field| TululStats::User::EXCEPTION.include?(field) } + TululStats::Entity::ENTITY_QUERY + TululStats::IsTime::TIME_QUERY).include?(query)
  end

  def self.allowed_group?(group_id)
    $redis.get("tulul_stats::allowed_groups::#{group_id}")
  end

  def self.tulul?(message)
    [-12126542, -136614216].include?(message.chat.id)
  end

  def self.list_groups(chat_id)
    check = "\xE2\x9C\x94"
    cross = "\xE2\x9C\x96"
    list = TululStats::Group.all.map{ |gr| "#{allowed_group?(gr.group_id) ? check : cross} #{gr.group_id}: #{gr.title}"}.join("\n")
    send(chat_id: chat_id, text: list)
  end
end
