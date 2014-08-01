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
				php -d 'suhosin.executor.include.whitelist = phar' -d 'date.timezone = UTC' #{shared_path}/composer.phar install
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
				ln -sf #{shared_path}/install/installed.txt #{release_path}/src/Install/Cache/installed.txt
			}
		end
    
		desc 'Clear the frontend and backend cache-folders'
		task :clear_cached do
			# remove frontend cached data
			run %{
				rm -rf #{current_path}/src/Frontend/Cache/CachedTemplates/* &&
				rm -rf #{current_path}/src/Frontend/Cache/CompiledTemplates/* &&
				rm -rf #{current_path}/src/Frontend/Cache/Locale/* &&
				rm -rf #{current_path}/src/Frontend/Cache/MinifiedCss/* &&
				rm -rf #{current_path}/src/Frontend/Cache/MinifiedJs/* &&
				rm -rf #{current_path}/src/Frontend/Cache/Navigation/* &&
				rm -rf #{current_path}/src/Frontend/Cache/Search/*
			}

			# remove backend cached data
			run %{
				rm -rf #{current_path}/src/Backend/Cache/Analytics/* &&
				rm -rf #{current_path}/src/Backend/Cache/Cronjobs/* &&
				rm -rf #{current_path}/src/Backend/Cache/Locale/* &&
				rm -rf #{current_path}/src/Backend/Cache/Mailmotor/* &&
				rm -rf #{current_path}/src/Backend/Cache/MinifiedCss/* &&
				rm -rf #{current_path}/src/Backend/Cache/MinifiedJs/* &&
				rm -rf #{current_path}/src/Backend/Cache/CompiledTemplates/*
			}
		end
    
		desc 'Create needed symlinks'
		task :link_files do
			# get the list of folders in /frontend/files
			folders = capture("ls -1 #{release_path}/src/Frontend/Files").split(/\r?\n/)

			# loop the folders
			folders.each do |folder|
				# copy them to the shared path, remove them from the release and symlink them
				run %{
				  mkdir -p #{shared_path}/files/#{folder} &&
					cp -r #{release_path}/src/Frontend/Files/#{folder} #{shared_path}/files/ &&
					rm -rf #{release_path}/src/Frontend/Files/#{folder} &&
					ln -s #{shared_path}/files/#{folder} #{release_path}/src/Frontend/Files/#{folder}
				}
			end
		end	
	end
end