module TululStats
  class Hour
    include IsTime

    field :hour, type: Integer

    index({ hour: 1 })
  end
end
