require 'test_helper'

class LocationTest < Minitest::Test
  include ActiveShipping::Test::Fixtures

  def test_countries
    assert_instance_of ActiveUtils::Country, location_fixtures[:ottawa].country
    assert_equal 'CA', location_fixtures[:ottawa].country_code(:alpha2)
  end

  def test_location_from_strange_hash
    hash = {  :country => 'CA',
              :zip => '90210',
              :territory_code => 'QC',
              :town => 'Perth',
              :address => '66 Gregory Ave.',
              :phone => '515-555-1212',
              :fax_number => 'none to speak of',
              :address_type => :commercial
            }
    location = Location.from(hash)

    assert_equal hash[:country], location.country_code(:alpha2)
    assert_equal hash[:zip], location.zip
    assert_equal hash[:territory_code], location.province
    assert_equal hash[:town], location.city
    assert_equal hash[:address], location.address1
    assert_equal hash[:phone], location.phone
    assert_equal hash[:fax_number], location.fax
    assert_equal hash[:address_type].to_s, location.address_type
  end

  def test_pretty_print
    expected = "110 Laurier Avenue West\nOttawa, ON, K1P 1J1\nCanada"
    assert_equal expected, location_fixtures[:ottawa].prettyprint
  end

  def test_to_s
    expected = "110 Laurier Avenue West Ottawa, ON, K1P 1J1 Canada"
    assert_equal expected, location_fixtures[:ottawa].to_s
  end

  def test_inspect
    expected = "110 Laurier Avenue West\nOttawa, ON, K1P 1J1\nCanada\nPhone: 1-613-580-2400\nFax: 1-613-580-2495"
    assert_equal expected, location_fixtures[:ottawa].inspect
  end

  def test_includes_name
    location = Location.from(:name => "Bob Bobsen")
    assert_equal "Bob Bobsen", location.name
  end

  def test_name_is_nil_if_not_provided
    location = Location.from({})
    assert_nil location.name
  end

  def test_location_with_company_name
    location = Location.from(:company => "Mine")
    assert_equal "Mine", location.company_name

    location = Location.from(:company_name => "Mine")
    assert_equal "Mine", location.company_name
  end

  def test_set_address_type
    location = location_fixtures[:ottawa]
    assert !location.commercial?

    location.address_type = :commercial
    assert location.commercial?
  end

  def test_set_address_type_invalid
    location = location_fixtures[:ottawa]

    assert_raises(ArgumentError) do
      location.address_type = :new_address_type
    end

    refute_equal "new_address_type", location.address_type
  end

  def test_to_hash_attributes
    assert_equal %w(address1 address2 address3 address_type city company_name country fax name phone postal_code province), location_fixtures[:ottawa].to_hash.stringify_keys.keys.sort
  end

  def test_to_json
    location_json = location_fixtures[:ottawa].to_json
    assert_equal location_fixtures[:ottawa].to_hash, JSON.parse(location_json).symbolize_keys
  end

  def test_zip_plus_4_with_no_dash
    zip = "33333"
    plus_4 = "1234"
    zip_plus_4 = "#{zip}-#{plus_4}"
    location = Location.from(:zip => "#{zip}#{plus_4}")
    assert_equal zip_plus_4, location.zip_plus_4
  end

  def test_zip_plus_4_with_dash
    zip = "33333"
    plus_4 = "1234"
    zip_plus_4 = "#{zip}-#{plus_4}"
    location = Location.from(:zip => zip_plus_4)
    assert_equal zip_plus_4, location.zip_plus_4
  end

  def test_address2_and_3_is_nil
    location = location_fixtures[:ottawa]
    assert_nil location.address2
    assert_nil location.address3
    assert location.address2_and_3.blank?
  end

  def test_address2_and_3
    address2 = 'Apt 613'
    address3 = 'Victory Lane'
    location = Location.from(:address2 => address2)
    assert_equal 'Apt 613', location.address2_and_3

    location = Location.from(:address2 => address2, :address3 => address3)
    assert_equal 'Apt 613, Victory Lane', location.address2_and_3

    location = Location.from(:address3 => address3)
    assert_equal 'Victory Lane', location.address2_and_3
  end

  def test_equality
    location_1 = location_fixtures[:ottawa]
    location_2 = Location.from(location_1.to_hash)

    assert_equal location_1, location_2
  end
end
