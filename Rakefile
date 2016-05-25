require 'rake'

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require File.expand_path('../config/init', __FILE__)
require 'tulul_stats_bot'

namespace :tulul_stats do
  task :start do
    TululStatsBot.start
  end
end

task default: 'tulul_stats:start'
