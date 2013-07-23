require 'test/unit'
require 'forkcms_deploy/forkcms.rb'

class TestForkCMS < Test::Unit::TestCase
	def	test_versions
		assert_equal "3.5", ForkCMSDeploy::ForkCMS.determine_version_to_use("3.6")			# 3
		assert_equal "3.5", ForkCMSDeploy::ForkCMS.determine_version_to_use("3.5")			# 3
		assert_equal "3", ForkCMSDeploy::ForkCMS.determine_version_to_use("3.3")			# 3
		assert_equal "3", ForkCMSDeploy::ForkCMS.determine_version_to_use("3")				# 3
		assert_equal "2", ForkCMSDeploy::ForkCMS.determine_version_to_use("2")				# 2
		assert_equal "default", ForkCMSDeploy::ForkCMS.determine_version_to_use("1")		# default
		assert_equal "default", ForkCMSDeploy::ForkCMS.determine_version_to_use("1.2.3")	# default
	end
end
