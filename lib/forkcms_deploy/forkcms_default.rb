configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
	# define some extra folder to create
	set :shared_children, %w(files config/frontend config/backend config/library)

	# custom events configuration
	after 'deploy:setup' do
		forkcms.link_document_root
	end

	after 'deploy:update_code' do
		forkcms.link_configs
		forkcms.link_files
	end

	# Fork CMS specific tasks
	namespace :forkcms do
		desc 'Link the config files'
		task :link_configs do

			# change the path to current_path
			run "if [ -f #{shared_path}/config/library/globals.php ]; then sed -i 's/#{version_dir}\\/[0-9]*/#{current_dir}/' #{shared_path}/config/library/globals.php; fi"

			# symlink the globals
			run %{
				ln -sf #{shared_path}/config/library/globals.php #{release_path}/library/globals.php
			}
		end

		desc 'link the document root to the current/default_www-folder'
		task :link_document_root do
			# create symlink for document_root if it doesn't exists
			documentRootExists = capture("if [ ! -e #{document_root} ]; then ln -sf #{current_path}/default_www #{document_root}; echo 'no'; fi").chomp

			unless documentRootExists == 'no'
				warn "Warning: Document root (#{document_root}) already exists"
				warn "to link it to the Fork deploy issue the following command:"
				warn "	ln -sf #{current_path}/default_www #{document_root}"
			end
		end

		desc 'Create needed symlinks'
		task :link_files do
			# get the list of folders in /frontend/files
			folders = capture("ls -1 #{release_path}/default_www/userfiles").split(/\r?\n/)

			# loop the folders
			folders.each do |folder|
				# copy them to the shared path, remove them from the release and symlink them
				run %{
					cp -r #{release_path}/default_www/userfiles/#{folder} #{shared_path}/files/#{folder} &&
					rm -rf #{release_path}/default_www/userfiles/#{folder} &&
					ln -s #{shared_path}/files/#{folder} #{release_path}/default_www/userfiles/#{folder}
				}
			end

			# get the list of folders in /frontend/files
			folders = capture("ls -1 #{release_path}/default_www/modulefiles").split(/\r?\n/)

			# loop the folders
			folders.each do |folder|
				# copy them to the shared path, remove them from the release and symlink them
				run %{
					cp -r #{release_path}/default_www/modulefiles/#{folder} #{shared_path}/files/#{folder} &&
					rm -rf #{release_path}/default_www/modulefiles/#{folder} &&
					ln -s #{shared_path}/files/#{folder} #{release_path}/default_www/modulefiles/#{folder}
				}
			end
		end
	end
end