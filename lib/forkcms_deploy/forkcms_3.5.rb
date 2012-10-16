configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
	# define some extra folder to create
	set :shared_children, %w(files config/frontend config/backend config/library)

	# custom events configuration
	after 'deploy:setup' do
		forkcms.link_document_root
	end

	after 'deploy:update_code' do
		composer.install_vendors
		forkcms.link_configs
		forkcms.link_files
	end

	# Fork CMS specific tasks
	namespace :forkcms do
		desc 'Clear the frontend and backend cache-folders'
		task :clear_cached do
			# remove frontend cached data
			run %{
				rm -rf #{current_path}/frontend/cache/cached_templates/* &&
				rm -rf #{current_path}/frontend/cache/locale/* &&
				rm -rf #{current_path}/frontend/cache/minified_css/* &&
				rm -rf #{current_path}/frontend/cache/minified_js/* &&
				rm -rf #{current_path}/frontend/cache/navigation/* &&
				rm -rf #{current_path}/frontend/cache/statistics/* &&
				rm -rf #{current_path}/frontend/cache/templates/*
			}

			# remove backend cached data
			run %{
				rm -rf #{current_path}/backend/cache/analytics/* &&
				rm -rf #{current_path}/backend/cache/cronjobs/* &&
				rm -rf #{current_path}/backend/cache/locale/* &&
				rm -rf #{current_path}/backend/cache/mailmotor/* &&
				rm -rf #{current_path}/backend/cache/templates/*
			}
		end

		desc 'Link the config files'
		task :link_configs do
			# create config files
			path_library = <<-CONFIG
<?php
	// custom constant used by the init classes
	define('INIT_PATH_LIBRARY', '#{current_path}/library');
?>
			CONFIG

			# upload the files
			put path_library, "#{shared_path}/config/frontend/config.php"
			put path_library, "#{shared_path}/config/backend/config.php"

			# change the path to current_path
			run "if [ -f #{shared_path}/config/library/globals.php ]; then sed -i 's/#{version_dir}\\/[0-9]*/#{current_dir}/' #{shared_path}/config/library/globals.php; fi"

			# create dirs
			run %{
				mkdir -p #{release_path}/frontend/cache/config &&
				mkdir -p #{release_path}/backend/cache/config
			}

			# symlink the globals
			run %{
				ln -sf #{shared_path}/config/library/globals_backend.php #{release_path}/library/globals_backend.php &&
				ln -sf #{shared_path}/config/library/globals_frontend.php #{release_path}/library/globals_frontend.php &&
				ln -sf #{shared_path}/config/library/globals.php #{release_path}/library/globals.php &&
				ln -sf #{shared_path}/config/frontend/config.php #{release_path}/frontend/cache/config/config.php &&
				ln -sf #{shared_path}/config/backend/config.php #{release_path}/backend/cache/config/config.php
			}
		end

		desc 'link the document root to the current/default_www-folder'
		task :link_document_root do
			# create symlink for document_root if it doesn't exists
			documentRootExists = capture("if [ ! -e #{document_root} ]; then ln -sf #{current_path} #{document_root}; echo 'no'; fi").chomp

			unless documentRootExists == 'no'
				warn "Warning: Document root (#{document_root}) already exists"
				warn 'to link it to the Fork deploy issue the following command:'
				warn '	ln -sf #{current_path} #{document_root}'
			end
		end

		desc 'Create needed symlinks'
		task :link_files do
			# get the list of folders in /frontend/files
			folders = capture("ls -1 #{release_path}/frontend/files").split(/\r?\n/)

			# loop the folders
			folders.each do |folder|
				# copy them to the shared path, remove them from the release and symlink them
				run %{
				  mkdir -p #{shared_path}/files/#{folder} &&
					cp -r #{release_path}/frontend/files/#{folder} #{shared_path}/files/ &&
					rm -rf #{release_path}/frontend/files/#{folder} &&
					ln -s #{shared_path}/files/#{folder} #{release_path}/frontend/files/#{folder}
				}
			end
		end
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
				if [ ! -e #{shared_path}/composer.phar ]; then cd #{shared_path}; curl -s https://getcomposer.org/installer | php -d 'suhosin.executor.include.whitelist = phar' -d 'date.timezone = UTC'; fi
			}
		end
	end
end