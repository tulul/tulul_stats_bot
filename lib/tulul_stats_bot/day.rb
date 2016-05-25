require 'tulul_stats_bot/is_time'

module TululStatsBot
  class Day
    include IsTime

    field :day, type: Integer

    index({ day: 1 })

    default_scope -> { order_by(day: :asc) }

    store_in collection: 'tulul_stats_days'
  end
end
