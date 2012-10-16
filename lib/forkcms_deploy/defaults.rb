configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
  def _cset(name, *args, &block)
    unless exists?(name)
      set(name, *args, &block)
    end
  end

  # don't use sudo, on most shared setups we won't have sudo-access
  _cset(:use_sudo) { false }

  # we're on a share setup so group_writable isn't allowed
  _cset(:group_writable) { false }

  # 3 releases should be enough.
  _cset(:keep_releases) { 3 }

  # remote caching will keep a local git repo on the server you're deploying to and simply run a fetch from that
  # rather than an entire clone. This is probably the best option and will only fetch the differences each deploy
  _cset(:deploy_via) { remote_cache }

  # set the value for pseudo terminals in Capistrano
  default_run_options[:pty] = true

  # your computer must be running ssh-agent for the git checkout to work from the server to the git server
  set :ssh_options, { :forward_agent => true }

  # set version control type and copy strategy
  set :scm, :git
  set :copy_strategy, :checkout
end