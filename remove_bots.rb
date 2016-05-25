load 'Rakefile'
TululStatsBot::User.where(username: /bot$/).each(&:destroy)
