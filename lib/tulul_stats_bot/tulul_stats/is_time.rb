module TululStats
  module IsTime
    extend ActiveSupport::Concern

    TIME_QUERY = ['hour', 'day']

    included do
      include Mongoid::Document

      field :count, type: Integer, default: 0

      default_scope -> { order_by(count: :desc) }

      belongs_to :group, class_name: 'TululStats::Group', index: true
    end
  end
end
