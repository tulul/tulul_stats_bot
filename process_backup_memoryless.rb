load 'Rakefile'
require 'json'

group = TululStats::Group.find_by(group_id: -1001035585767)
group.users.each do |user|
  user.update_attributes(
    message: 0,
    forwarding: 0,
    forwarded: 0,
    leliing: 0,
    kbbiing: 0,
    slanging: 0,
    getting: 0,
    luing: 0,
    latecomer: 0,
    ch_title: 0,
    ch_photo: 0,
    del_photo: 0,
    left_group: 0,
    join_group: 0,
    text: 0,
    photo: 0,
    keong_caller: 0,
    last_tulul_at: nil
  )
  user.hours.each(&:destroy)
  user.days.each(&:destroy)
end
group.hours.each(&:destroy)
group.days.each(&:destroy)

File.foreach('/home/araishikeiwai/Google Drive/Others/Telegram Backups/json/Lycantulul_Public_Game.jsonl') do |json|
  message = OpenStruct.new(JSON.parse(json))
  user = group.get_user(OpenStruct.new(message.from))

  user.inc_message

  if message.fwd_from
    user.inc_forwarding
    group.get_user(OpenStruct.new(message.fwd_from)).inc_forwarded
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

  if message.text =~ / lu[^A-Za-z]*$/i
    user.inc_luing
  end

  if message.text =~ /\d+k?\+* shitty messages?/i
    user.inc_latecomer
  end

  if message.service && message.action['type'] == 'chat_rename'
    user.inc_ch_title
  end

  if message.service && message.action['type'] == 'chat_change_photo'
    user.inc_ch_photo
  end

  if message.service && message.action['type'] == 'chat_delete_photo'
    user.inc_del_photo
  end

  if message.service && message.action['type'] == 'chat_del_user'
    group.get_user(OpenStruct.new(message.action['user'])).inc_left_group
  end

  if message.service && message.action['type'] == 'chat_add_user'
    group.get_user(OpenStruct.new(message.action['user'])).inc_join_group
  end

  user.inc_text if message.text

  if message.media&.dig('type') == 'photo'
    user.inc_photo
  end

  user.update_attribute(:last_tulul_at, DateTime.strptime(message.date.to_s, "%s"))

  time = Time.at(message.date).utc
  group.add_hour(time.hour)
  group.add_day(time.wday)
  user.add_hour(time.hour)
  user.add_day(time.wday)

  if message.text&.gsub(/[^A-Za-z]/, '') =~ /^h+a+h+$/i
    user.inc_keong_caller
  end
end
