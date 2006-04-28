# = ts_all.rb
#
# Test Suite of all the Test Unit.
#
# == Project
#
# * ActiveRDF
# <http://m3pe.org/activerdf/>
#
# == Authors
# 
# * Eyal Oren <first dot last at deri dot org>
# * Renaud Delbru <first dot last at deri dot org>
#
# == Copyright
#
# (c) 2005-2006 by Eyal Oren and Renaud Delbru - All Rights Reserved
#

require 'active_rdf'
require 'node_factory'

require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'

# Constant definition

DB_HOST = 'opteron'
DB = :yars

# Unit test include

# NodeFactory Tests
require 'test/node_factory/test_connection'
require 'test/node_factory/test_initialisation_connection'
require 'test/node_factory/test_create_literal'
require 'test/node_factory/test_create_basic_resource'
require 'test/node_factory/test_create_identified_resource_with_unknown_type'
require 'test/node_factory/test_create_identified_resource_on_person_type'
require 'test/node_factory/test_person_methods'
require 'test/node_factory/test_equals'

# Yars adapter Tests
require 'test/adapter/yars/test_yars_adapter'
require 'test/adapter/yars/test_yars_adapter_add'
require 'test/adapter/yars/test_yars_adapter_remove'
require 'test/adapter/yars/test_yars_basic_query'
require 'test/adapter/yars/test_yars_joint_query'

# Core Tests
require 'test/core/resource/test_resource'
require 'test/core/resource/test_resource_get'
require 'test/core/resource/test_resource_find'
require 'test/core/resource/test_identified_resource'
require 'test/core/resource/test_identifiedresource_get'
require 'test/core/resource/test_identifiedresource_find'
require 'test/core/resource/test_identifiedresource_create'
require 'test/core/resource/test_identifiedresource_attributescontainer'

# NamespaceFactory Test
require 'test/namespace_factory/test_namespace_factory'

class TestSuite_AllTests
	def self.test_adapter suite
		# Yars Adapter Tests
		suite << TestYarsAdapter.suite
		suite << TestYarsAdapterAdd.suite
		suite << TestYarsAdapterRemove.suite
		suite << TestYarsAdapterBasicQuery.suite
		suite << TestYarsAdapterJointQuery.suite
	end

	def self.test_resource suite
		# Resource Tests
		suite << TestResource.suite
		suite << TestResourceGet.suite
		suite << TestResourceFind.suite
		suite << TestIdentifiedResource.suite
		suite << TestIdentifiedResourceGet.suite
		suite << TestIdentifiedResourceFind.suite
		suite << TestIdentifiedResourceCreate.suite
		suite << TestAttributesContainer.suite
	end
		
	def self.test_namespace suite
		# NamespaceFactory Tests
		suite << TestNamespaceFactory.suite    
	end

	def self.test_nodefactory suite
		# NodeFactory Tests
		#suite << TestNodeFactoryInitialisationConnection.suite
		#suite << TestNodeFactoryLiteral.suite
		#suite << TestNodeFactoryBasicResource.suite
		#suite << TestResourceEquality.suite
		#suite << TestNodeFactoryUnknownIdentifiedResource.suite
		#suite << TestNodeFactoryIdentifiedResource.suite
		#suite << TestNodeFactoryPerson.suite
		suite << TestConnection.suite
	end

	def self.suite
		suite = Test::Unit::TestSuite.new("ActiveRDF Tests")
		
		#test_nodefactory suite
		#test_adapter suite
		#test_resource suite
		#test_namespace suite
					 
		return suite
	end
end

Test::Unit::UI::Console::TestRunner.run(TestSuite_AllTests)
