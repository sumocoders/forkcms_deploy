configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
	# don't use sudo, on most shared setups we won't have sudo-access
	set :use_sudo, false

	# we're on a share setup so group_writable isn't allowed
	set :group_writable, false

	# 3 releases should be enough.
	set :keep_releases, 3

	# remote caching will keep a local git repo on the server you're deploying to and simply run a fetch from that 
	# rather than an entire clone. This is probably the best option and will only fetch the differences each deploy
	set :deploy_via, :remote_cache

	# set the value for pseudo terminals in Capistrano
	default_run_options[:pty] = true

	# your computer must be running ssh-agent for the git checkout to work from the server to the git server
	set :ssh_options, { :forward_agent => true }
end