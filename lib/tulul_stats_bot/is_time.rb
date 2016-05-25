module TululStatsBot
  module IsTime
    extend ActiveSupport::Concern

    TIME_QUERY = ['hour', 'day']

    included do
      include Mongoid::Document

      field :count, type: Integer, default: 0

      belongs_to :group, class_name: 'TululStatsBot::Group', index: true
    end
  end
end
