begin
	content = File.read("VERSION.md")
	version = content[0, content.index('.')]
rescue SystemCallError
	$stderr.puts "No VERSION file found, Are you sure you're in a FORK project?"
	exit 1
end

require 'forkcms_deploy/overwrites'