# = test_identifiedresource_attributescontainer.rb
#
# Unit Test of AttributesContainer and InstanciatedresourceMethod
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

require 'test/unit'
require 'active_rdf'
require 'node_factory'
require 'active_rdf/test/common'

class TestAttributesContainer < Test::Unit::TestCase

	def setup
		setup_any
    require 'active_rdf/test/node_factory/person'
	end
	
	def teardown
		delete_any
	end
	
	def test_A_create_person_and_save_without_attributes
		person = Person.create('http://m3pe.org/activerdf/test/new_person')
		assert_not_nil(person)
		assert_instance_of(Person, person)
		person.save
		assert(Resource.exists?(person))
	end
	
	def test_B_create_person_and_save_with_attributes
		person = Person.create('http://m3pe.org/activerdf/test/new_person_2')
		assert_not_nil(person)
		assert_instance_of(Person, person)

		person2 = Person.create('http://m3pe.org/activerdf/test/new_person_3')
		assert_not_nil(person2)
		assert_instance_of(Person, person2)
		person2.name = 'person 3'		

		person.name = 'person 2'
		person.age = 42
		person.knows = person2
		person.save
		
		assert(Resource.exists?(person))
	end
	
	def test_C_attribute_accessors
		person = Person.create('http://m3pe.org/activerdf/test/new_person_2')
		person2 = Person.create('http://m3pe.org/activerdf/test/new_person_3')
		
		person.name = 'person 2'
		person.age = 42
		person.knows = person2
		person.save
		person2.name = 'person 3'
		person2.save
		
		assert_not_nil(person)
		assert_instance_of(Person, person)
		assert_equal('42', person.age)
		assert_equal('person 2', person.name)
		assert_equal('person 3', person.knows.name)
		assert_equal('42', person[:age].value)
		assert_equal('person 2', person[:name].value)
		assert_equal('person 3', person[:knows].name)
		assert_equal('42', person['age'].value)
		assert_equal('person 2', person['name'].value)
		assert_equal('person 3', person['knows'].name)
	end
	
	def test_D_update_attributes_with_symbol
		person = Person.create('http://m3pe.org/activerdf/test/new_person_2')
		assert_not_nil(person)
		assert_instance_of(Person, person)
		person2 = Person.create('http://m3pe.org/activerdf/test/new_person_3')
		assert_not_nil(person2)
		assert_instance_of(Person, person2)
		person2.name = 'person 3'
		
		attributes = { :age => 23, :name => 'person two', :knows => person2 }
		assert_nothing_raised(ResourceUpdateError) {person.update_attributes(attributes)}
		
		assert_equal('23', person.age)
		assert_equal('person two', person.name)
		assert_equal(person2.object_id, person.knows.object_id)
		assert_equal('23', person[:age].value)
		assert_equal('person two', person[:name].value)
		assert_equal(person2.object_id, person[:knows].object_id)
		assert_equal('23', person['age'].value)
		assert_equal('person two', person['name'].value)
		assert_equal(person2.object_id, person['knows'].object_id)
	end
	
	def test_E_update_attributes_with_string
		person = Person.create('http://m3pe.org/activerdf/test/new_person_2')
		assert_not_nil(person)
		assert_instance_of(Person, person)
		person2 = Person.create('http://m3pe.org/activerdf/test/new_person_3')
		assert_not_nil(person2)
		assert_instance_of(Person, person2)
		person2.name = 'person 3'
		
		attributes = { 'age' => 42, 'name' => 'person 2', 'knows' => person2 }
		assert_nothing_raised(ResourceUpdateError) {
			person.update_attributes(attributes)
		}
		
		assert_equal('42', person.age)
		assert_equal('person 2', person.name)
		assert_equal(person2.object_id, person.knows.object_id)
		assert_equal('42', person[:age].value)
		assert_equal('person 2', person[:name].value)
		assert_equal(person2.object_id, person[:knows].object_id)
		assert_equal('42', person['age'].value)
		assert_equal('person 2', person['name'].value)
		assert_equal(person2.object_id, person['knows'].object_id)
	end
	
	def test_F_write_multiple_resource_attributes
		person = Person.create('http://m3pe.org/activerdf/test/new_person_2')

		person2 = Person.create('http://m3pe.org/activerdf/test/new_person_3')
		person3 = Person.create('http://m3pe.org/activerdf/test/new_person_4')
		
		person.knows = [person2, person3]

		assert_instance_of(Array, person.knows)
		for p in person.knows
			assert_block("person doesn't knows other person") {
				if p.object_id == person2.object_id or p.object_id == person3.object_id
					return true
				else
					return false
				end
			}
		end
	end
	
	def test_G_update_multiple_resource_attributes
		person = Person.create('http://m3pe.org/activerdf/test/new_person_2')

		person2 = Person.create('http://m3pe.org/activerdf/test/new_person_3')
		person3 = Person.create('http://m3pe.org/activerdf/test/new_person_4')
		
		attributes = { :knows => [person2, person3] }
		assert_nothing_raised(ResourceUpdateError) {
			person.update_attributes(attributes)
		}

		assert_instance_of(Array, person.knows)
		for p in person.knows
			assert_block("person doesn't knows other person") {
				if p.object_id == person2.object_id or p.object_id == person3.object_id
					return true
				else
					return false
				end
			}
		end
	end
	
	def test_H_remove_value_of_attribute
		person = Person.create('http://m3pe.org/activerdf/test/new_person_2')
		assert_not_nil(person)
		assert_instance_of(Person, person)
		person.age = nil
		person.name = nil
		person.knows = nil
		
		assert_equal(nil, person.age)
		assert_equal(nil, person.name)
		assert_equal(nil, person.knows)
		assert_equal(nil, person[:age])
		assert_equal(nil, person[:name])
		assert_equal(nil, person[:knows])
		assert_equal(nil, person['age'])
		assert_equal(nil, person['name'])
		assert_equal(nil, person['knows'])		
	end
	
	def test_I_remove_value_of_attribute_with_update
		person = Person.create('http://m3pe.org/activerdf/test/new_person_2')
		assert_not_nil(person)
		assert_instance_of(Person, person)
		attributes = { :age => nil, :name => nil, :knows => nil }
		assert_nothing_raised(ResourceUpdateError) {
			person.update_attributes(attributes)
		}
		
		assert_equal(nil, person.age)
		assert_equal(nil, person.name)
		assert_equal(nil, person.knows)
		assert_equal(nil, person[:age])
		assert_equal(nil, person[:name])
		assert_equal(nil, person[:knows])
		assert_equal(nil, person['age'])
		assert_equal(nil, person['name'])
		assert_equal(nil, person['knows'])			
	end
	
	def test_J_query_attribute
		person = Person.create('http://m3pe.org/activerdf/test/new_person_2')
		
    assert !person.name?
    assert !person.age?
    assert !person.knows?
    
		person.name = ""
		person.age = 0
		
		assert person.name?
		assert person.age?
    assert !person.knows?
		
    # TODO: when we have implemented literal datatypes, person.age shoud be a boolean
    assert_kind_of String, person.name
    assert_kind_of String, person.age
	end
	
	def test_K_update_attribute_error_with_unknown_attribute
		person = Person.create('http://m3pe.org/activerdf/test/new_person_2')
	
		attributes = { :unknown_attribute => 'test unknown attribute' }
		assert_raise(ResourceUpdateError) {
			person.update_attributes(attributes)
		}
	end
	
	def test_L_update_attributes_with_empty_string
		person = Person.create('http://m3pe.org/activerdf/test/new_person')
		assert_not_nil(person)
		assert_instance_of(Person, person)
		
		attributes = { 'age' => 42, 'name' => '' }
		assert_nothing_raised(ResourceUpdateError) {
			person.update_attributes(attributes)
		}
		
		assert_equal('42', person.age)
		assert_equal('', person.name)
		assert_equal('42', person[:age].value)
		assert_equal('', person[:name].value)
		assert_equal('42', person['age'].value)
		assert_equal('', person['name'].value)
	end

end
