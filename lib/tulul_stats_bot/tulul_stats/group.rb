module TululStats
  class Group
    include Mongoid::Document

    field :group_id, type: Integer

    index({ group_id: 1 }, { unique: true })

    has_many :users, class_name: 'TululStats::User'

    def self.get_group(message)
      self.find_or_create_by(group_id: message.chat.id)
    end

    def get_user(user)
      self.users.get(user, self.id)
    end

    def top(field)
      res = self.users.sort_by{ |b| eval("b.#{field}") }.reverse.map do |user|
        sum = eval("user.#{field}")
        [user.full_name, sum] if sum > 0
      end.compact

      total = res.inject(0){ |b, c| b + c[1] }.to_f

      rank = 0
      prev_sum = -1
      prev_count = 1

      res.map do |entry|
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

        "#{rank}. #{name}: #{sum} (#{percentage}%)"
      end.join("\n")
    end
  end
end
