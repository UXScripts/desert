require "active_support"
require "active_record"
require "action_controller"
require "action_mailer"

dir = File.dirname(__FILE__)
require "#{dir}/desert/plugin"
require "#{dir}/desert/manager"
Desert::RAILS_VERSION = Rails.const_defined?(:Plugin) ? 2 : 1

if Desert::RAILS_VERSION == 2
  require "#{dir}/desert/rails/2.x/plugin"
else
  require "#{dir}/desert/rails/1.x/initializer"
end
require "#{dir}/desert/rails/dependencies"
require "#{dir}/desert/rails/migration"
require "#{dir}/desert/rails/migrator"
require "#{dir}/desert/ruby/object"

require "#{dir}/desert/rails/route_set"

require "#{dir}/desert/plugin_migrations/migrator"
require "#{dir}/desert/plugin_migrations/extensions/schema_statements"

require "#{dir}/desert/plugin_templates/action_controller"
if Desert::RAILS_VERSION == 2
  require "#{dir}/desert/plugin_templates/2.x/action_mailer"
else
  require "#{dir}/desert/plugin_templates/1.x/action_mailer"
end
require "#{dir}/desert/plugin_templates/action_view"