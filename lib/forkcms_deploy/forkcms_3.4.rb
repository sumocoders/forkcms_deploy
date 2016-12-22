require "forkcms_deploy/forkcms_3"
configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
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
				#{php_bin} -d 'suhosin.executor.include.whitelist = phar' -d 'date.timezone = UTC' #{shared_path}/composer.phar install -o --no-dev
			}
		end

		desc 'Install composer'
		task :install_composer do
			run %{
				if [ ! -e #{shared_path}/composer.phar ]; then cd #{shared_path}; curl -ks https://getcomposer.org/installer | #{php_bin} -d 'suhosin.executor.include.whitelist = phar' -d 'date.timezone = UTC'; fi
			}
		end
	end
end
