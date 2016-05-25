module TululStats
  class Day
    include IsTime

    field :day, type: Integer

    index({ day: 1 })

    default_scope -> { order_by(day: :asc) }
  end
end
