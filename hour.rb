module TululStats
  class Hour
    include IsTime

    field :hour, type: Integer

    index({ hour: 1 })

    default_scope -> { order_by(hour: :asc) }
  end
end
