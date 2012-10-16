module ForkCMSDeploy
	class ForkCMS
		def self.determine_version_to_use(version)
			until version.empty?
				if File.exists?(File.dirname(__FILE__) + "/../forkcms_deploy/forkcms_#{version}.rb")
					return version
				end
				version = version.sub(/\.?[^\.]+$/, '')
			end
			return "default"
		end
	end
end