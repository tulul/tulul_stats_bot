module TululStats
  class Hour < ActiveRecord::Base
    include IsTime

    default_scope -> { order(hour: :asc) }
  end
end
