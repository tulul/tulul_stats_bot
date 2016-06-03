load 'Rakefile'
TululStats::User.where(username: /bot$/i).each(&:destroy)
