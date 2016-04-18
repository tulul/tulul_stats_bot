module TululStats
  class Day
    include IsTime

    field :day, type: Integer

    index({ day: 1 })
  end
end
