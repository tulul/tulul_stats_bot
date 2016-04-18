require 'rake'
require 'redis'
require 'mongoid'
require 'telegram/bot'
require 'sucker_punch'
require 'active_support/inflector'
require 'active_support/concern'

require File.dirname(__FILE__) + '/config/init.rb'
require File.dirname(__FILE__) + '/lib/tulul_stats_bot/tulul_stats/is_time.rb'
Dir[File.dirname(__FILE__) + '/lib/tulul_stats_bot/*/*.rb'].each{ |file| require file }
Dir[File.dirname(__FILE__) + '/lib/tulul_stats_bot/**/*.rb'].each{ |file| require file }

$redis = Redis.new
Mongoid.load!(File.dirname(__FILE__) + '/config/mongoid.yml', :production)

namespace :tulul_stats do
  task :start do
    TululStatsBot.start
  end
end

task default: 'tulul_stats:start'
