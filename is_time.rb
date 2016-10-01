module TululStats
  module IsTime
    extend ActiveSupport::Concern

    TIME_QUERY = ['hour', 'day']

    included do
      include Mongoid::Document

      field :count, type: Integer, default: 0

      belongs_to :group, class_name: 'TululStats::Group', index: true
      belongs_to :user, class_name: 'TululStats::User', index: true
    end
  end
end
