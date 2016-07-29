module TululStats
  module HasTime
    extend ActiveSupport::Concern

    included do
      has_many :hours, class_name: 'TululStats::Hour', dependent: :destroy
      has_many :days, class_name: 'TululStats::Day', dependent: :destroy
    end

    def add_hour(hour)
      self.hours.find_or_create_by(hour: hour).inc(count: 1)
    end

    def add_day(day)
      self.days.find_or_create_by(day: day).inc(count: 1)
    end
  end
end
