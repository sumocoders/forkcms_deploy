require "forkcms_deploy/forkcms.rb"
begin
	version = ForkCMSDeploy::ForkCMS.determine_version_to_use(File.read("VERSION.md"))
	require "forkcms_deploy/forkcms_#{version}"
rescue SystemCallError
	$stderr.puts "No VERSION file found, Are you sure you're in a FORK project?"
	exit 1
end

require 'forkcms_deploy/overwrites'