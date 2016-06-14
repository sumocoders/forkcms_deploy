require "forkcms_deploy/forkcms_3.7"
configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
	# Fork CMS specific tasks
	namespace :forkcms do
		desc 'Link the config files'
		task :link_configs do

			# change the path to current_path
			run "if [ -f #{shared_path}/config/parameters.yml ]; then sed -i 's/#{version_dir}\\/[0-9]*/#{current_dir}/' #{shared_path}/config/parameters.yml; fi"

			# symlink the parameters
			run %{
				ln -sf #{shared_path}/config/parameters.yml #{release_path}/app/config/parameters.yml
			}
		end
	end
end
