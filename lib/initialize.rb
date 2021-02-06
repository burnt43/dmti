# Gem/Bundler
require 'rubygems'
require 'bundler/setup'

# Gem Requires
require 'sqlite3'
require 'ruby-lazy-const'
require 'ruby-lazy-config'

LazyConst::Config.base_dir = './lib'
LazyConfig::Config.base_dir = "/home/#{`whoami`.strip}"
