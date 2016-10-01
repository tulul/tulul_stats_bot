module TululStats
  module HasTime
    extend ActiveSupport::Concern

    included do
      has_many :hours, class_name: 'TululStats::Hour', dependent: :destroy
      has_many :days, class_name: 'TululStats::Day', dependent: :destroy
    end

    def add_hour(hour)
      TululStats::Hour.transaction(requires_new: true) do
        hour = self.hours.find_or_create_by(hour: hour)
        hour.count += 1
        hour.save!
      end
    end

    def add_day(day)
      TululStats::Day.transaction(requires_new: true) do
        day = self.days.find_or_create_by(day: day)
        day.count += 1
        day.save!
      end
    end
  end
end
