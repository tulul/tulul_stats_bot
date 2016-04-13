module TululStats
  class Group
    include Mongoid::Document

    field :group_id, type: Integer

    index({ group_id: 1 }, { unique: true })

    has_many :users, class_name: 'TululStats::User'
    has_many :entities, class_name: 'TululStats::Entity'

    def self.get_group(message)
      self.find_or_create_by(group_id: message.chat.id)
    end

    def get_user(user)
      self.users.get(user, self.id)
    end

    def add_entity(message, entity)
      self.entities.add_new(message[entity.offset...entity.offset + entity.length], entity.type, self.id)
    end

    def top(field)
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
      res
    end
  end
end
