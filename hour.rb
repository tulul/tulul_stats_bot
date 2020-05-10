module TululStats
  class Hour < ApplicationRecord
    include IsTime

    default_scope -> { order(hour: :asc) }
  end
end
