require "forkcms_deploy/forkcms_3.5"
configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
	# Fork CMS specific tasks
	namespace :forkcms do
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
