module TululStats
  class Group
    include Mongoid::Document

    field :group_id, type: Integer
    field :title, type: String

    index({ group_id: 1 }, { unique: true })

    has_many :users, class_name: 'TululStats::User'
    has_many :entities, class_name: 'TululStats::Entity'
    has_many :hours, class_name: 'TululStats::Hour'
    has_many :days, class_name: 'TululStats::Day'

    def self.get_group(message)
      group = self.find_or_create_by(group_id: message.chat.id)
      group.update_attribute(:title, message.chat.title)
      group
    end

    def get_user(user)
      self.users.get(user, self.id)
    end

    def add_entity(message, entity)
      self.entities.add_new(message[entity.offset...entity.offset + entity.length], entity.type, self.id)
    end

    def add_hour(hour)
      self.hours.find_or_create_by(hour: hour).inc(count: 1)
    end

    def add_day(day)
      self.days.find_or_create_by(day: day).inc(count: 1)
    end

    def top(field, verbose: true, ratio: false)
      if TululStats::IsTime::TIME_QUERY.include?(field)
        count =
          case field
          when 'hour'
            24
          when 'day'
            7
          end

        res = []
        (0...count).each do |i|
          res << (self.send(field.pluralize).find_by(field => i).count rescue 0)
        end

        sum = 0
        max = -1
        res.each do |resi|
          sum += resi
          max = resi if resi > max
        end

        max_perc = (max * 100.0 / sum).ceil rescue 0
        norm = 10.0

        arr = []
        res.each do |resi|
          cur_perc = ((resi * 100.0 / sum) * norm / max_perc).ceil rescue 0
          arr << ['.'] * (norm - cur_perc) + ['|'] * cur_perc
        end

        arr = arr.transpose

        ret = '<pre>'
        arr.each do |arri|
          ret += arri.join
          ret += "\n"
        end

        ret +=
          case field
          when 'hour'
            '0a UTC 7a     2p     9p '
          when 'day'
            'SMTWTFS'
          end

        ret += '</pre>'
        ret
      elsif field.downcase == 'last_tulul'
        rank = 0
        self.users.reject{ |b| b.last_tulul_at.nil? }.sort_by{ |b| b.last_tulul_at }.reverse.map do |cur|
          rank += 1
          last_tulul_at = cur.last_tulul_at.utc.strftime("%y-%m-%d %H:%M UTC")
          "#{rank}. #{last_tulul_at} | #{cur.full_name}"
        end.join("\n")[0...4000]
      else
        res =
          if TululStats::Entity::ENTITY_QUERY.include?(field)
            self.entities.where(type: field).map(&:content).group_by{ |content| content.downcase rescue '' }.map{ |k, v| [k, v.count, nil] }.sort_by{ |k| k[1] }.reverse
          else
            self.users.sort_by{ |b| b.send("#{field}") }.reverse.map do |user|
              sum = user.send("#{field}")
              ratio_lo = field != 'message' && sum * 1.0 / user.message
              [user.full_name, sum, ratio_lo] if sum > 0
            end.compact
          end

        total = res.inject(0){ |b, c| b + c[1] }.to_f

        rank = 0
        prev_sum = -1
        prev_count = 1

        max_perc = (res[0][1] * 100.0 / total).ceil rescue 0
        norm = 10.0

        arr = []
        24.times do |i|
          cur_perc = ((res[i][1] * 100.0 / total) * norm / max_perc).ceil rescue 0
          ll = res[i][0][0].downcase rescue ' '
          ll = res[i][0][1].downcase if ['#', '@'].include?(ll)
          arr << ['.'] * (norm - cur_perc) + ['|'] * cur_perc + [ll]
        end

        arr = arr.transpose

        graph = "\n\n<pre>"
        arr.each do |arri|
          graph += arri.join
          graph += "\n"
        end
        graph += '</pre>'

        res = res.sort_by{ |re| [re[2] || 0, re[1]] }.reverse if ratio
        res.map! do |entry|
          name = entry[0]
          sum = entry[1]

          if sum == prev_sum
            prev_count += 1
          else
            rank += prev_count
            prev_count = 1
            prev_sum = sum
          end

          percentage = "%.2f" % (sum * 100 / total) rescue 0

          rt = "#{rank}. #{name}: <b>#{sum}</b> (#{percentage}%)"
          entry[2] && rt += " -- #{"%.3f" % entry[2]}"
          rt
        end

        res.compact!
        res = res[0...10] unless verbose
        res = res.join("\n")
        field = field.gsub('ch', 'change').gsub('del', 'delete').humanize(capitalize: false).pluralize
        res = "Total #{field}: <b>#{total.to_i}</b>\n" + res unless res.empty?
        res = res[0...3700]
        res += graph unless res.empty?
        res
      end
    end

    def convert_hour(hour)
      suf = hour >= 12 ? ' PM' : ' AM'
      suf += ' UTC'
      hour %= 12 unless hour == 12
      hour.to_s + suf
    end

    def convert_day(day)
      Date::DAYNAMES[day]
    end
  end
end
