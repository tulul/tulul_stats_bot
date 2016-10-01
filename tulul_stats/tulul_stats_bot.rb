class TululStatsBot
  @@bot = nil

  ALLOWED_GROUPS = -> { $redis.lrange('tulul_stats::allowed_groups', 0, -1) }
  ALLOWED_DELAY = -> { (res = $redis.get('tulul_stats::allowed_delay')) ? res.to_i : 20 }

  ATENG_HAH = 102972
  ATENG_ID = 88878925
  QT_DUMP_CHAT = -138536027
  RICK_ID = 78028868
  TULUL_CHAT = -12126542

  def self.start
    Telegram::Bot::Client.run($token) do |bot|
      @@bot = bot
      bot.listen do |message|
        begin
          if message&.from&.username == 'araishikeiwai' && message&.text =~ /\/allow/
            group_id = message&.chat&.id
            group_id && $redis.set("tulul_stats::allowed_groups::#{group_id}", 1)
          end

          if !message
          elsif message.text =~ /\/chat_id/
            send(chat_id: message.chat.id, text: message.chat.id)
          elsif message.from.username == 'araishikeiwai' && message.chat.type == 'private'
            if message.text == '/list'
              list_groups(message.chat.id)
            elsif message.text =~ /\/set_allow/
              group_id = message.text.split(' ')[1]
              group_id && $redis.set("tulul_stats::allowed_groups::#{group_id}", 1)
            elsif message.text =~ /\/set_disallow/
              group_id = message.text.split(' ')[1]
              group_id && $redis.del("tulul_stats::allowed_groups::#{group_id}")
            else
              query, group_id, *options = message.text&.gsub('/', '').split(' ')
              options = Hash[*options.map{ |opt| [opt.to_sym, true] }.flatten]
              options.merge!({ from_id: RICK_ID })
              if valid_query(query) && allowed_group?(group_id)
                group = TululStats::Group.find_by(group_id: group_id.to_i)
                res = group.top(query, options)
                res = 'Belum cukup data' if res&.gsub("\n", '').empty?
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
              res = 'Belum cukup data' if res&.gsub("\n", '').strip.empty?
              send(chat_id: message.chat.id, text: res, reply_to_message_id: message.message_id) if tulul?(message) && allowed_time?(message.date)
            elsif valid_query(query)
              options = queries.split(' ')[1..-1]
              options = Hash[*options.map{ |opt| [opt.to_sym, true] }.flatten]
              options.merge!({ from_id: user.user_id })
              res = group.top(query, options)
              res = 'Belum cukup data' if res&.gsub("\n", '').empty?
              send(chat_id: message.chat.id, text: res, reply_to_message_id: message.message_id) if allowed_time?(message.date)
            else
              user_update = []
              user_update << [user, :message]

              if message.reply_to_message
                user_update << [user, :replying]
                user_update << [group.get_user(message.reply_to_message.from), :replied]

                if message.text =~ /#qt/i
                  user_update << [user, :qting]
                  qted = message.reply_to_message.forward_from || message.reply_to_message.from
                  user_update << [group.get_user(qted), :qted]
                  # dump qt
                  @@bot.api.forward_message(chat_id: QT_DUMP_CHAT, from_chat_id: message.chat.id, message_id: message.reply_to_message.message_id) if tulul?(message)
                end
              end

              if message.forward_from
                user_update << [user, :forwarding]
                user_update << [group.get_user(message.forward_from), :forwarded]
              end

              if message.text =~ /^\/leli/
                user_update << [user, :leliing]
              end

              if message.text =~ /^\/kbbi/
                user_update << [user, :kbbiing]
              end

              if message.text =~ /^\/slang/
                user_update << [user, :slanging]
              end

              if message.text =~ /^\/get/
                user_update << [user, :getting]
              end

              if message.text =~ /<.*blog.*>/i || message.text =~ /%blog/i
                if message.reply_to_message
                  user_update << [group.get_user(message.reply_to_message.from), :blogging]
                else
                  user_update << [user, :blogging]
                end
              end

              if message.text =~ /#?anriya/i
                if message.reply_to_message
                  user_update << [group.get_user(message.reply_to_message.from), :riya]
                else
                  user_update << [user, :riya]
                end
              end

              if message.text =~ / lu[^A-Za-z]*$/i
                user_update << [user, :luing]
              end

              if message.text =~ /#honestquestion/i
                if message.reply_to_message
                  user_update << [group.get_user(message.reply_to_message.from), :honest_asker]
                else
                  user_update << [user, :honest_asker]
                end
              end

              if message.new_chat_title
                old_title, new_title = group.update_title!(message.chat.title)

                old_title&.gsub!(/H-\d+/, '')
                new_title&.gsub!(/H-\d+/, '')
                title_changed = old_title != new_title

                user_update << [user, :ch_title]
                res = '#TululTitle'
                unless group.last_title_change == -1 || !title_changed
                  t = message.date - group.last_title_change
                  mm, ss = t.divmod(60)
                  hh, mm = mm.divmod(60)
                  dd, hh = hh.divmod(24)
                  time = "%dd %dh %dm %ds" % [dd, hh, mm, ss]
                  res += "\nPrevious title lifetime: #{time}"
                end
                send(chat_id: message.chat.id, text: res, reply_to_message_id: message.message_id) if tulul?(message)
                group.update_attribute(:last_title_change, message.date) if title_changed || group.last_title_change == -1
              end

              unless message.new_chat_photo.empty?
                user_update << [user, :ch_photo]
                res = "Hey guys, #{user.username_or_full_name} just fixed the aikon! #TululPhoto"
                unless group.last_photo_change == -1
                  t = message.date - group.last_photo_change
                  mm, ss = t.divmod(60)
                  hh, mm = mm.divmod(60)
                  dd, hh = hh.divmod(24)
                  time = "%dd %dh %dm %ds" % [dd, hh, mm, ss]
                  res += "\nPrevious photo lifetime: #{time}"
                end
                send(chat_id: message.chat.id, text: res, reply_to_message_id: message.message_id) if tulul?(message)
                group.update_attribute(:last_photo_change, message.date)
              end

              if message.delete_chat_photo
                user_update << [user, :del_photo]
                res = "Hey guys, #{user.username_or_full_name} just abolished the aikon! #TululPhoto"
                unless group.last_photo_change == -1
                  t = message.date - group.last_photo_change
                  mm, ss = t.divmod(60)
                  hh, mm = mm.divmod(60)
                  dd, hh = hh.divmod(24)
                  time = "%dd %dh %dm %ds" % [dd, hh, mm, ss]
                  res += "\nPrevious photo lifetime: #{time}"
                end
                send(chat_id: message.chat.id, text: res, reply_to_message_id: message.message_id) if tulul?(message)
                group.update_attribute(:last_photo_change, message.date)
              end

              user_update << [group.get_user(message.left_chat_member), :left_group] if message.left_chat_member
              user_update << [group.get_user(message.new_chat_member), :join_group] if message.new_chat_member

              user_update << [user, :text] if message.text
              user_update << [user, :audio] if message.audio
              user_update << [user, :document] if message.document
              user_update << [user, :photo] unless message.photo.empty?
              user_update << [user, :sticker] if message.sticker
              user_update << [user, :video] if message.video
              user_update << [user, :voice] if message.voice
              user_update << [user, :contact] if message.contact
              user_update << [user, :location] if message.location

              message.entities.each do |entity|
                user_update << [user, :mentioning] if entity.type == 'mention'
                user_update << [user, :hashtagging] if entity.type == 'hashtag'
                user_update << [user, :linking] if entity.type == 'url'
                group.add_entity(message.text, entity) if TululStats::Entity::ENTITY_QUERY.include?(entity.type)
              end

              time = Time.at(message.date).utc
              group.add_hour(time.hour)
              group.add_day(time.wday)
              user.add_hour(time.hour)
              user.add_day(time.wday)

              if tulul?(message) && message.text =~ /mau nge-?blog/i
                user_update << [user, :blogging]
                send(chat_id: message.chat.id, text: "どうぞ #{user.call_name.presence}".strip) if allowed_time?(message.date)
              end

              if tulul?(message) && message.text&.gsub(/[^A-Za-z]/, '') =~ /^h+a+h+$/i && allowed_time?(message.date)
                user_update << [user, :keong_caller]
                user_update << [group.users.find_by(user_id: ATENG_ID), :forwarded]
                @@bot.api.forward_message(chat_id: message.chat.id, from_chat_id: TULUL_CHAT, message_id: ATENG_HAH)
              end

              if tulul?(message) && message.text&.gsub(/[^A-Za-z ]/, '')&.split&.count == 1 && allowed_time?(message.date)
                possible_call_name = message.text.downcase.gsub(/[^a-z]/, '')
                possible_user = TululStats::User.search(possible_call_name, fields: [:call_name], misspellings: false).results.first
                if possible_user
                  user_update << [user, :luing]
                  send(chat_id: message.chat.id, text: "#{possible_user.call_name} lu")
                end
              end

              user_update.uniq.group_by{ |u| u[0] }.map{ |k, v| [k, v.map{ |vv| vv[1] }]}.each do |uu, attrs|
                attrs.each do |att|
                  uu.send("#{att}=", uu.send(att) + 1)
                end
                uu.last_tulul_at = DateTime.strptime(message.date.to_s, "%s") if uu.user_id == user.user_id
                uu.save
              end
            end
          else
            send(chat_id: message.chat.id, text: "You're not allowed to use this bot in your group yet, please message @araishikeiwai to ask for permission. For now, please remove the bot from the group") if allowed_time?(message.date)
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

    if e.message =~ /error_code: .(429|502)./
      sleep(10)
    end
    retry unless e.message =~ /error_code: .(400|403|409)./
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
      retry if e.message !~ /error_code: .(400|403|409)./ && (retry_count += 1) < 20
    end
  end

  def self.valid_query(query)
    query && (TululStats::User.fields.keys.reject{ |field| TululStats::User::EXCEPTION.include?(field) } + TululStats::Entity::ENTITY_QUERY + TululStats::IsTime::TIME_QUERY).include?(query)
  end

  def self.allowed_group?(group_id)
    $redis.get("tulul_stats::allowed_groups::#{group_id}")
  end

  def self.allowed_time?(date)
    Time.now.to_i - date < ALLOWED_DELAY.call
  end

  def self.tulul?(message)
    [TULUL_CHAT, -136614216].include?(message.chat.id)
  end

  def self.list_groups(chat_id)
    check = "\xE2\x9C\x94"
    cross = "\xE2\x9C\x96"
    list = TululStats::Group.all.map{ |gr| "#{allowed_group?(gr.group_id) ? check : cross} #{gr.group_id}: #{gr.title}"}.join("\n")
    send(chat_id: chat_id, text: list)
  end
end
