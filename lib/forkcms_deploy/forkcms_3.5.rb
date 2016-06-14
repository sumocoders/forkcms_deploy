require "forkcms_deploy/forkcms_3.4"
configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
	set :shared_children, %w(files config install)

	# Fork CMS specific tasks
	namespace :forkcms do
		desc 'Link the config files'
		task :link_configs do

			# change the path to current_path
			run "if [ -f #{shared_path}/config/parameters.yml ]; then sed -i 's/#{version_dir}\\/[0-9]*/#{current_dir}/' #{shared_path}/config/parameters.yml; fi"
			run "if [ ! -f #{shared_path}/install/installed.txt ]; then touch #{shared_path}/install/installed.txt; fi"

			# symlink the parameters
			run %{
				ln -sf #{shared_path}/config/parameters.yml #{release_path}/app/config/parameters.yml &&
				ln -sf #{shared_path}/install/installed.txt #{release_path}/install/cache/installed.txt
			}
		end
	end
end
