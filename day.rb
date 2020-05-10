module TululStats
  class Day < ApplicationRecord
    include IsTime

    default_scope -> { order(day: :asc) }
  end
end
