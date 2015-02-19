require 'yaml'

configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
	# define some extra folder to create
	set :shared_children, %w(files config/frontend config/backend config/library)

	# custom events configuration
	after 'deploy:setup' do
		forkcms.link_document_root
		migrations.prepare
	end

	after 'deploy:update_code' do
		forkcms.link_configs
		forkcms.link_files
	end

	before 'deploy:create_symlink' do
		migrations.execute
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

	namespace :migrations do
		desc 'prepares the server for running fork migrations'
		task :prepare do
			# Check if the migrations file exists.
			migrationsFileExists = capture("if [ -f #{shared_path}/executed_migrations ]; then echo 'yes'; fi").chomp

			# Only create the file if it doesn't exists.
			unless migrationsFileExists == 'yes'
				# Create an empty executed_migrations file
				put '', "#{shared_path}/executed_migrations"
			end

			# Create a maintenance folder containing the index page from our gem
			maintenance_path = File.dirname(__FILE__)
			maintenance_path = "#{maintenance_path}/../maintenance"
			run "mkdir #{shared_path}/maintenance"

			# copy the contents of the index.html file to our shared folder
			indexfile = File.open("#{maintenance_path}/index.html", "rb")
			put indexfile.read, "#{shared_path}/maintenance/index.html"
			indexfile.close

			# copy the contents of the .htaccess file to our shared folder
			htaccessfile = File.open("#{maintenance_path}/.htaccess", "rb")
			put htaccessfile.read, "#{shared_path}/maintenance/.htaccess"
			htaccessfile.close
		end

		desc 'fills in the executed_migrations on first deploy'
		task :first_deploy do
			# Put all items in the migrations folder in the executed_migrations file
			# When doing a deploy:setup, we expect the database to already contain
			# The migrations (so a clean copy of the database should be available
			# when doing a setup)
			folders = capture("if [ -e #{release_path}/migrations ]; then ls -1 #{release_path}/migrations; fi").split(/\r?\n/)

			folders.each do |dirname|
				run "echo #{dirname} | tee -a #{shared_path}/executed_migrations"
			end
		end

		desc 'runs the migrations'
		task :execute do
			# If the current symlink doesn't exist yet, we're on a first deploy
			currentDirectoryExists = capture("if [ ! -e #{current_path} ]; then echo 'yes'; fi").chomp
			if currentDirectoryExists == 'yes'
				migrations.first_deploy
			end

			# Check if there are new migrations found
			folders = capture("if [ -e #{release_path}/migrations ]; then ls -1 #{release_path}/migrations; fi").split(/\r?\n/)

			if folders.length > 0
				executedMigrations = capture("cat #{shared_path}/executed_migrations").chomp.split(/\r?\n/)
				migrationsToExecute = Array.new

				# Fetch all migration directories that aren't executed yet
				folders.each do |dirname|
					migrationsToExecute.push(dirname) if executedMigrations.index(dirname) == nil
				end

				if migrationsToExecute.length > 0
					# This can take a while and can go wrong. let's show a maintenance page
					# and make sure we can put back the database
					migrations.symlink_maintenance
					migrations.backup_database
					on_rollback { migrations.rollback }

					# run all migrations
					migrationsToExecute.each do |dirname|
						migrationpath = "#{release_path}/migrations/#{dirname}"
						migrationFiles = capture("ls -1 #{migrationpath}").split(/\r?\n/)

						migrationFiles.each do |filename|
							puts filename
							# run("cd #{release_path}/tools && php install_locale.php -f #{deltaPath}/#{filename} -o") if filename.index('locale.xml') != nil
							# run("cd #{release_path} && php delta/#{dirname}/#{filename}") if filename.index('update.php') != nil
							if filename.index('update.sql') != nil
								set :mysql_update_file, "#{migrationpath}/#{filename}"
								migrations.mysql_update
							end
						end
					end

					# all migrations where executed successfully, put them in the
					# executed_migrations file
					migrationsToExecute.each do |dirname|
						run "echo #{dirname} | tee -a #{shared_path}/executed_migrations"
					end

					# symlink the root back
					migrations.symlink_root
				end
			end
		end

		desc 'shows a maintenace page'
		task :symlink_maintenance do
			run "rm -rf #{document_root} && ln -sf #{shared_path}/maintenance #{document_root}"
		end

		desc 'Symlink back the document root with the current deployed version.'
		task :symlink_root do
			run "rm -rf #{document_root} && ln -sf #{current_path} #{document_root}"
		end

		desc 'backs up the database'
		task :backup_database do
			parametersContent = capture "cat #{shared_path}/config/parameters.yml"
			yaml = YAML::load(parametersContent.gsub("%", ""))

			run "mysqldump --default-character-set='utf8' --host=#{yaml['parameters']['database.host']} --port=#{yaml['parameters']['database.port']} --user=#{yaml['parameters']['database.user']} --password=#{yaml['parameters']['database.password']} #{yaml['parameters']['database.name']} > #{release_path}/mysql_backup.sql"
		end

		desc 'puts back the database'
		task :rollback do
			set :mysql_update_file, "#{migrationpath}/#{filename}"
			migrations.mysql_update

			migrations.symlink_root
		end

		desc 'updates mysql with a certain (sql) file'
		task :mysql_update do
			parametersContent = capture "cat #{shared_path}/config/parameters.yml"
			yaml = YAML::load(parametersContent.gsub("%", ""))

			run "mysql --default-character-set='utf8' --host=#{yaml['parameters']['database.host']} --port=#{yaml['parameters']['database.port']} --user=#{yaml['parameters']['database.user']} --password=#{yaml['parameters']['database.password']} #{yaml['parameters']['database.name']} < #{mysql_update_file}"
		end
	end
end
