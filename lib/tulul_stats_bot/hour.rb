require 'tulul_stats_bot/is_time'

module TululStatsBot
  class Hour
    include IsTime

    field :hour, type: Integer

    index({ hour: 1 })

    default_scope -> { order_by(hour: :asc) }

    store_in collection: 'tulul_stats_hours'
  end
end
