module TululStats
  class Day < ActiveRecord::Base
    include IsTime

    default_scope -> { order(day: :asc) }
  end
end
