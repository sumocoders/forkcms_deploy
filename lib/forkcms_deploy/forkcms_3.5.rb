require "forkcms_deploy/forkcms_3"
configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
	set :shared_children, %w(files config install)

	after 'deploy:update_code' do
		composer.install_vendors
	end

	# composer specific tasks
	namespace :composer do
		desc 'Install the vendors'
		task :install_vendors do
			composer.install_composer
			run %{
				cd #{latest_release} &&
				php -d 'suhosin.executor.include.whitelist = phar' -d 'date.timezone = UTC' #{shared_path}/composer.phar install -o
			}
		end

		desc 'Install composer'
		task :install_composer do
			run %{
				if [ ! -e #{shared_path}/composer.phar ]; then cd #{shared_path}; curl -ks https://getcomposer.org/installer | php -d 'suhosin.executor.include.whitelist = phar' -d 'date.timezone = UTC'; fi
			}
		end
	end

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
