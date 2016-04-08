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
      count = 0
      self.users.sort_by{ |b| eval("b.#{field}") }.reverse.map do |user|
        sum = eval("user.#{field}")
        "#{count += 1}. #{user.full_name}: #{sum}" if sum > 0
      end.join("\n")
    end
  end
end
