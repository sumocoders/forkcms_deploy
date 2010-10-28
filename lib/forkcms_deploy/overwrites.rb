configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
	# Deployment process
	namespace :deploy do
		desc 'Prepares the servers for deployment.'
		task :setup, :except => { :no_release => true } do
			# this method is overwritten because Fork CMS isn't a Rails-application

			# define folders to create
			dirs = [deploy_to, releases_path, shared_path]
			
			# add folder that aren't standard
			dirs += shared_children.map { |d| File.join(shared_path, d) }

			# create the dirs
			run %{
				#{try_sudo} mkdir -p #{dirs.join(' ')} && 
				#{try_sudo} chmod g+w #{dirs.join(' ')}
			}
		end

		task :finalize_update, :except => { :no_release => true } do
			# Fork CMS isn't a Rails-application so don't do Rails specific stuff
			run 'chmod -R g+w #{latest_release}' if fetch(:group_writable, true)
		end

		# overrule restart	
		task :restart do; end
	end
end