require "forkcms_deploy/forkcms_3"
configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
	set :shared_children, %w(files config)
end