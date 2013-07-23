module ForkCMSDeploy
	class ForkCMS
		ForkLibPath = File.dirname(__FILE__) + '/../forkcms_deploy'

		def self.determine_version_to_use(version)
			versions = version.split('.')
			until versions.empty?
				# Exact version match
				if File.exists?(ForkLibPath + "/forkcms_#{versions.join('.')}.rb")
					return versions.join('.')
				else
					level_version = versions.pop
					
					# Find a version that might match on the same level
					matching_level = Dir.glob(ForkLibPath + "/forkcms_#{versions.join('.')}.[0-9]*.rb")
					matching_level.sort.reverse.each do |file|
						# Extract the file's level-version from the path
						file_version = file[/(\d+).rb$/, 1]
						
						# Return this version if the file's version is lower then the Fork version
						# (such that, for Fork 3.6, 3.5 is loaded, but not for Fork 3.4
						return (versions + [file_version]).join('.') if file_version < level_version
					end
				end
			end

			return "default"
		end
	end
end
