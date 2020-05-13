module TululStats
  module IsTime
    extend ActiveSupport::Concern

    TIME_QUERY = ['hour', 'day']

    included do
      belongs_to :group, class_name: 'TululStats::Group', foreign_key: 'group_id', optional: true
      belongs_to :user, class_name: 'TululStats::User', foreign_key: 'user_id', optional: true
    end
  end
end
