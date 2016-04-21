module TululStats
  class Group
    include Mongoid::Document

    field :group_id, type: Integer

    index({ group_id: 1 }, { unique: true })

    has_many :users, class_name: 'TululStats::User'
    has_many :entities, class_name: 'TululStats::Entity'
    has_many :hours, class_name: 'TululStats::Hour'
    has_many :days, class_name: 'TululStats::Day'

    def self.get_group(message)
      self.find_or_create_by(group_id: message.chat.id)
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

    def top(field)
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
      else
        res =
          if TululStats::Entity::ENTITY_QUERY.include?(field)
            self.entities.where(type: field).map(&:content).group_by{ |content| content }.map{ |k, v| [k, v.count] }.sort_by{ |k| k[1] }.reverse
          else
            self.users.sort_by{ |b| b.send("#{field}") }.reverse.map do |user|
              sum = user.send("#{field}")
              [user.full_name, sum] if sum > 0
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

          "#{rank}. #{name}: <b>#{sum}</b> (#{percentage}%)"
        end

        field = field.gsub('ch', 'change').gsub('del', 'delete').humanize(capitalize: false).pluralize
        res = res.compact.join("\n")
        res = "Total #{field}: <b>#{total.to_i}</b>\n" + res unless res.empty?
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
