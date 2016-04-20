load 'Rakefile'
TululStats::User.where(username: /bot$/).each(&:destroy)
