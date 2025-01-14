module ActiveShipping

  # FedEx carrier implementation.
  #
  class FedExRest < Carrier

    self.retry_safe = true

    cattr_reader :name
    @@name = "FedEx"

    TEST_HOST = 'https://apis-sandbox.fedex.com'
    LIVE_HOST = 'https://apis.fedex.com'

    CARRIER_CODES = {
        "fedex_ground" => "FDXG",
        "fedex_express" => "FDXE"
    }

    DELIVERY_ADDRESS_NODE_NAMES = %w(DestinationAddress ActualDeliveryAddress)
    SHIPPER_ADDRESS_NODE_NAMES  = %w(ShipperAddress)

    SERVICE_TYPES = {
        "PRIORITY_OVERNIGHT" => "FedEx Priority Overnight",
        "PRIORITY_OVERNIGHT_SATURDAY_DELIVERY" => "FedEx Priority Overnight Saturday Delivery",
        "FEDEX_2_DAY" => "FedEx 2 Day",
        "FEDEX_2_DAY_SATURDAY_DELIVERY" => "FedEx 2 Day Saturday Delivery",
        "STANDARD_OVERNIGHT" => "FedEx Standard Overnight",
        "FIRST_OVERNIGHT" => "FedEx First Overnight",
        "FIRST_OVERNIGHT_SATURDAY_DELIVERY" => "FedEx First Overnight Saturday Delivery",
        "FEDEX_EXPRESS_SAVER" => "FedEx Express Saver",
        "FEDEX_1_DAY_FREIGHT" => "FedEx 1 Day Freight",
        "FEDEX_1_DAY_FREIGHT_SATURDAY_DELIVERY" => "FedEx 1 Day Freight Saturday Delivery",
        "FEDEX_2_DAY_FREIGHT" => "FedEx 2 Day Freight",
        "FEDEX_2_DAY_FREIGHT_SATURDAY_DELIVERY" => "FedEx 2 Day Freight Saturday Delivery",
        "FEDEX_3_DAY_FREIGHT" => "FedEx 3 Day Freight",
        "FEDEX_3_DAY_FREIGHT_SATURDAY_DELIVERY" => "FedEx 3 Day Freight Saturday Delivery",
        "INTERNATIONAL_PRIORITY" => "FedEx International Priority",
        "INTERNATIONAL_PRIORITY_SATURDAY_DELIVERY" => "FedEx International Priority Saturday Delivery",
        "INTERNATIONAL_ECONOMY" => "FedEx International Economy",
        "INTERNATIONAL_FIRST" => "FedEx International First",
        "INTERNATIONAL_PRIORITY_FREIGHT" => "FedEx International Priority Freight",
        "INTERNATIONAL_ECONOMY_FREIGHT" => "FedEx International Economy Freight",
        "GROUND_HOME_DELIVERY" => "FedEx Ground Home Delivery",
        "FEDEX_GROUND" => "FedEx Ground",
        "INTERNATIONAL_GROUND" => "FedEx International Ground",
        "SMART_POST" => "FedEx SmartPost",
        "FEDEX_FREIGHT_PRIORITY" => "FedEx Freight Priority",
        "FEDEX_FREIGHT_ECONOMY" => "FedEx Freight Economy"
    }

    PACKAGE_TYPES = {
        "fedex_envelope" => "FEDEX_ENVELOPE",
        "fedex_pak" => "FEDEX_PAK",
        "fedex_box" => "FEDEX_BOX",
        "fedex_tube" => "FEDEX_TUBE",
        "fedex_10_kg_box" => "FEDEX_10KG_BOX",
        "fedex_25_kg_box" => "FEDEX_25KG_BOX",
        "your_packaging" => "YOUR_PACKAGING"
    }

    DROPOFF_TYPES = {
        'regular_pickup' => 'REGULAR_PICKUP',
        'request_courier' => 'REQUEST_COURIER',
        'dropbox' => 'DROP_BOX',
        'business_service_center' => 'BUSINESS_SERVICE_CENTER',
        'station' => 'STATION'
    }

    SIGNATURE_OPTION_CODES = {
        adult: 'ADULT', # 21 years plus
        direct: 'DIRECT', # A person at the delivery address
        indirect: 'INDIRECT', # A person at the delivery address, or a neighbor, or a signed note for fedex on the door
        none_required: 'NO_SIGNATURE_REQUIRED',
        default_for_service: 'SERVICE_DEFAULT'
    }

    PAYMENT_TYPES = {
        'sender' => 'SENDER',
        'recipient' => 'RECIPIENT',
        'third_party' => 'THIRDPARTY',
        'collect' => 'COLLECT'
    }

    PACKAGE_IDENTIFIER_TYPES = {
        'tracking_number' => 'TRACKING_NUMBER_OR_DOORTAG',
        'door_tag' => 'TRACKING_NUMBER_OR_DOORTAG',
        'rma' => 'RMA',
        'ground_shipment_id' => 'GROUND_SHIPMENT_ID',
        'ground_invoice_number' => 'GROUND_INVOICE_NUMBER',
        'ground_customer_reference' => 'GROUND_CUSTOMER_REFERENCE',
        'ground_po' => 'GROUND_PO',
        'express_reference' => 'EXPRESS_REFERENCE',
        'express_mps_master' => 'EXPRESS_MPS_MASTER',
        'shipper_reference' => 'SHIPPER_REFERENCE',
    }

    TRANSIT_TIMES = %w(UNKNOWN ONE_DAY TWO_DAYS THREE_DAYS FOUR_DAYS FIVE_DAYS SIX_DAYS SEVEN_DAYS EIGHT_DAYS NINE_DAYS TEN_DAYS ELEVEN_DAYS TWELVE_DAYS THIRTEEN_DAYS FOURTEEN_DAYS FIFTEEN_DAYS SIXTEEN_DAYS SEVENTEEN_DAYS EIGHTEEN_DAYS)

    # FedEx tracking codes as described in the FedEx Tracking Service WSDL Guide
    # All delays also have been marked as exceptions
    TRACKING_STATUS_CODES = HashWithIndifferentAccess.new(
        'AA' => :at_airport,
        'AD' => :at_delivery,
        'AF' => :at_fedex_facility,
        'AR' => :at_fedex_facility,
        'AP' => :at_pickup,
        'CA' => :canceled,
        'CH' => :location_changed,
        'DE' => :exception,
        'DL' => :delivered,
        'DP' => :departed_fedex_location,
        'DR' => :vehicle_furnished_not_used,
        'DS' => :vehicle_dispatched,
        'DY' => :exception,
        'EA' => :exception,
        'ED' => :enroute_to_delivery,
        'EO' => :enroute_to_origin_airport,
        'EP' => :enroute_to_pickup,
        'FD' => :at_fedex_destination,
        'HL' => :held_at_location,
        'IT' => :in_transit,
        'LO' => :left_origin,
        'OC' => :order_created,
        'OD' => :out_for_delivery,
        'PF' => :plane_in_flight,
        'PL' => :plane_landed,
        'PU' => :picked_up,
        'RS' => :return_to_shipper,
        'SE' => :exception,
        'SF' => :at_sort_facility,
        'SP' => :split_status,
        'TR' => :transfer
    )

    #a list of countries that support electronic trade documents
    ELECTRONIC_TRADE_DOCUMENT_COUNTRIES=['AF','AL','AO','AW','AU','AT','BS','BH','BD','BB','BE','BM','BQ','VG','BN','KH','CA','KY','GB','CN','HR','CW','CY','CZ','DK','DJ','DO','TL','EG','SV','GB','EE','FI','FR','DE','GH','GP','GU','GT','HN','HK','HU','IS','IN','ID','IE','IL','IT','CI','JM','JP','JO','KE','KR','KW','LA','LV','LS','LI','LT','LU','MO','MG','MY','MT','MH','MU','MX','FM','MC','MS','NL','AN','NZ','NI','GB','MP','No','OM','PW','PS','PA','PH','PL','PT','PR','BQ','KN','LC','MF','SM','SA','GB','SX','SG','BQ','SK','SI','ZA','ES','LK','SE','CH','TW','TH','TL','TG','TT','TN','TC','VI','AE','US','VA','GB']

    def self.service_name_for_code(service_code)
      SERVICE_TYPES[service_code] || "FedEx #{service_code.titleize.sub(/Fedex /, '')}"
    end

    def requirements
      []
    end

    def find_rates(origin, destination, packages, options = {})
      options = @options.merge(options)
      packages = Array(packages)

      rate_request = build_rate_request(origin, destination, packages, options)

      response = commit('/rate/v1/rates/quotes', save_request(rate_request), (options[:test] || false))

      parse_rate_response(origin, destination, packages, response, options)
    end


    # Get Shipping labels
    def create_shipment(origin, destination, packages, options = {})
      options = @options.merge(options)
      packages = Array(packages)
      raise Error, "Multiple packages are not supported yet." if packages.length > 1

      request = build_shipment_request(origin, destination, packages, options)
      logger.debug(request) if logger
      response = commit('/ship/v1/shipments', save_request(request), options[:test] || false )
      parse_ship_response(response)
    end

    def maximum_address_field_length
      # See Fedex Developper Guide
      35
    end



    protected

    def build_rate_request(origin, destination, packages, options = {})
      imperial = location_uses_imperial(origin)
      freight = has_freight?(options)
      {
          accountNumber: {
              value: @options[:account]
          },
          rateRequestControlParameters: {
              returnTransitTimes: true,
              variableOptions: 'SATURDAY_DELIVERY'
          },
          requestedShipment: {
              shipper: build_address(options[:shipper] || origin),
              recipient: build_address(destination),
              shipDateStamp: rest_ship_date(options),
              rateRequestType: ['ACCOUNT'],
              pickupType: 'DROPOFF_AT_FEDEX_LOCATION',
              PackagingType: options[:packaging_type] || 'YOUR_PACKAGING',
              smartPostInfoDetail:{
                  indicia: options[:smart_post_indicia] || 'PARCEL_SELECT',
                  hubId: options[:smart_post_hub_id] || 5902
              },
              requestedPackageLineItems: rate_packages_detail(packages, imperial),
              totalPackageCount: packages.size,
              carrierCodes: ['FDXE', 'FDXG']

          }

      }

    end

    def build_shipment_request(origin, destination, packages, options = {})

      imperial = location_uses_imperial(origin)
      options[:international] = origin.country.name != destination.country.name

      label_format = options[:label_format] ? options[:label_format].upcase : 'PNG'
      label_size   = options[:label_size]   ? options[:label_size]          : 'STOCK_4X6'

      {
          accountNumber: {
              value: @options[:account]
          },
          labelResponseOptions: 'URL_ONLY',
          requestedShipment: {

              shipDateStamp: rest_ship_date(options),
              pickupType: 'DROPOFF_AT_FEDEX_LOCATION',
              PackagingType: options[:packaging_type] || 'YOUR_PACKAGING',
              serviceType: options[:service_type] || 'FEDEX_GROUND',
              rateRequestType: ['ACCOUNT'],
              totalPackageCount: packages.size,
              shipper: build_contact_address(options[:shipper] || origin),
              recipients: [build_contact_address(destination)],
              origin: build_contact_address(origin),
              shippingChargesPayment: {
                  paymentType: 'SENDER',
                  payor: {
                      responsibleParty: build_contact_address(options[:shipper] || origin),
                  }.merge(accountNumber: @options[:account])
              },
              labelSpecification: {
                  labelFormatType: 'COMMON2D',
                  imageType: label_format,
                  labelStockType: label_size

              },
              requestedPackageLineItems: shipment_packages_detail(packages, imperial)

          }
      }


    end

    def build_freight_shipment_detail_node(xml, freight_options, packages, imperial)
      xml.FreightShipmentDetail do
        # TODO: case of different freight account numbers?
        xml.FedExFreightAccountNumber(freight_options[:account])
        build_location_node(xml, 'FedExFreightBillingContactAndAddress', freight_options[:billing_location])
        xml.Role(freight_options[:role])

        packages.each do |pkg|
          xml.LineItems do
            xml.FreightClass(freight_options[:freight_class])
            xml.Packaging(freight_options[:packaging])
            build_package_weight_node(xml, pkg, imperial)
            build_package_dimensions_node(xml, pkg, imperial)
          end
        end
      end
    end

    def has_freight?(options)
      options[:freight] && options[:freight].present?
    end


    def parse_rate_response(origin, destination, packages, response, options)

      response = JSON.parse(response)
      # success = response_success?(xml)
      # message = response_message(xml)
      missing_field = false
      rate_estimates = response['output']['rateReplyDetails'].map do |rated_shipment|
        begin

          service_code = rated_shipment['serviceType']
          is_saturday_delivery = rated_shipment['commit']['saturdayDelivery']
          service_type = is_saturday_delivery ? "#{service_code}_SATURDAY_DELIVERY" : service_code

          transit_time = rated_shipment['operationalDetail']['transitTime'] if ["FEDEX_GROUND", "GROUND_HOME_DELIVERY"].include?(service_code)
          max_transit_time = rated_shipment['operationalDetail']['MaximumTransitTime'] if service_code == "FEDEX_GROUND"

          delivery_timestamp = rated_shipment['operationalDetail']['publishedDeliveryTime']
          delivery_range = delivery_range_from(transit_time, max_transit_time, delivery_timestamp, (service_code == "GROUND_HOME_DELIVERY"), options)

          reated_shipment_detail = rated_shipment['ratedShipmentDetails'].first
          currency = reated_shipment_detail['currency']

          RateEstimate.new(origin, destination, @@name,
                           self.class.service_name_for_code(service_type),
                           :service_code => service_code,
                           :total_price => reated_shipment_detail['totalNetCharge'].to_f,
                           :currency => currency,
                           :packages => packages,
                           :delivery_range => delivery_range)

        rescue NoMethodError
          missing_field = true
          nil
        end
      end

      rate_estimates = rate_estimates.compact
      logger.warn("[FedexParseRateError] Some fields where missing in the response: #{response}") if logger && missing_field

      if rate_estimates.empty?
        success = false
        if missing_field
          message = "The response from the carrier contained errors and could not be treated"
        else
          message = "No shipping rates could be found for the destination address" if message.blank?
        end
      end


      RateResponse.new(true, 'message', response, :rates => rate_estimates, :xml => response, :request => last_request, :log_xml => options[:log_xml])

    end

    def delivery_range_from(transit_time, max_transit_time, delivery_timestamp, is_home_delivery, options)
      delivery_range = [delivery_timestamp, delivery_timestamp]

      # if there's no delivery timestamp but we do have a transit time, use it
      if delivery_timestamp.blank? && transit_time.present?
        transit_range  = parse_transit_times([transit_time, max_transit_time.presence || transit_time])
        pickup_date = options[:pickup_date] || ship_date(options[:turn_around_time])

        delivery_range = transit_range.map { |days| business_days_from(pickup_date, days, is_home_delivery) }
      end

      delivery_range
    end

    def parse_ship_response(response)
      tracking_number = nil
      base_64_image = nil
      commercial_invoice = nil
      labels = []
      xml = build_document(response, 'ProcessShipmentReply')
      success = response_success?(xml)
      message = response_message(xml)

      response_info = Hash.from_xml(response)
      if success
        tracking_number = xml.css("CompletedPackageDetails TrackingIds TrackingNumber").last.text
        base_64_image = xml.css("Label Image").text
        labels = [Label.new(tracking_number, Base64.decode64(base_64_image))]
        commercial_invoice = xml.xpath("//ShipmentDocuments[Type='COMMERCIAL_INVOICE']//Image").text
        commercial_invoice = nil if commercial_invoice.blank?
      end

      LabelResponse.new(success, message, response_info, {labels: labels, commercial_invoice: commercial_invoice})
    end

    def business_days_from(date, days, is_home_delivery=false)
      future_date = date
      count       = 0

      while count < days
        future_date += 1.day
        if is_home_delivery
          count += 1 if home_delivery_business_day?(future_date)
        else
          count += 1 if business_day?(future_date)
        end
      end

      future_date
    end

    #Transit times for FedEx® Ground do not include Saturdays, Sundays, or holidays.
    def business_day?(date)
      (1..5).include?(date.wday)
    end

    #Transit times for FedEx® Home Delivery, do not include Sundays, Mondays, or holidays.
    def home_delivery_business_day?(date)
      (2..6).include?(date.wday)
    end

    def parse_tracking_response(response, options)
      xml = build_document(response, 'TrackReply')

      success = response_success?(xml)
      message = response_message(xml)

      if success
        origin = nil
        delivery_signature = nil
        shipment_events = []

        all_tracking_details = xml.root.xpath('CompletedTrackDetails/TrackDetails')
        tracking_details = case all_tracking_details.length
                             when 1
                               all_tracking_details.first
                             when 0
                               raise ActiveShipping::Error, "The response did not contain tracking details"
                             else
                               all_unique_identifiers = xml.root.xpath('CompletedTrackDetails/TrackDetails/TrackingNumberUniqueIdentifier').map(&:text)
                               raise ActiveShipping::Error, "Multiple matches were found. Specify a unqiue identifier: #{all_unique_identifiers.join(', ')}"
                           end


        first_notification = tracking_details.at('Notification')
        if first_notification.at('Severity').text == 'ERROR'
          case first_notification.at('Code').text
            when '9040'
              raise ActiveShipping::ShipmentNotFound, first_notification.at('Message').text
            else
              raise ActiveShipping::ResponseContentError, StandardError.new(first_notification.at('Message').text)
          end
        elsif first_notification.at('Severity').text == 'FAILURE'
          case first_notification.at('Code').text
            when '9045'
              raise ActiveShipping::ResponseContentError, StandardError.new(first_notification.at('Message').text)
          end
        end

        tracking_number = tracking_details.at('TrackingNumber').text
        status_detail = tracking_details.at('StatusDetail')
        if status_detail.nil?
          raise ActiveShipping::Error, "Tracking response does not contain status information"
        end

        status_code = status_detail.at('Code').try(:text)
        if status_code.nil?
          raise ActiveShipping::Error, "Tracking response does not contain status code"
        end

        status_description = (status_detail.at('AncillaryDetails/ReasonDescription') || status_detail.at('Description')).text
        status = TRACKING_STATUS_CODES[status_code]

        if status_code == 'DL' && tracking_details.at('AvailableImages').try(:text) == 'SIGNATURE_PROOF_OF_DELIVERY'
          delivery_signature = tracking_details.at('DeliverySignatureName').text
        end

        if origin_node = tracking_details.at('OriginLocationAddress')
          origin = Location.new(
              :country =>     origin_node.at('CountryCode').text,
              :province =>    origin_node.at('StateOrProvinceCode').text,
              :city =>        origin_node.at('City').text
          )
        end

        destination = extract_address(tracking_details, DELIVERY_ADDRESS_NODE_NAMES)
        shipper_address = extract_address(tracking_details, SHIPPER_ADDRESS_NODE_NAMES)

        ship_time = extract_timestamp(tracking_details, 'ShipTimestamp')
        actual_delivery_time = extract_timestamp(tracking_details, 'ActualDeliveryTimestamp')
        scheduled_delivery_time = extract_timestamp(tracking_details, 'EstimatedDeliveryTimestamp')

        tracking_details.xpath('Events').each do |event|
          address  = event.at('Address')
          next if address.nil? || address.at('CountryCode').nil?

          city     = address.at('City').try(:text)
          state    = address.at('StateOrProvinceCode').try(:text)
          zip_code = address.at('PostalCode').try(:text)
          country  = address.at('CountryCode').try(:text)

          location = Location.new(:city => city, :state => state, :postal_code => zip_code, :country => country)
          description = event.at('EventDescription').text
          type_code = event.at('EventType').text

          time          = Time.parse(event.at('Timestamp').text)
          zoneless_time = time.utc

          shipment_events << ShipmentEvent.new(description, zoneless_time, location, description, type_code)
        end
        shipment_events = shipment_events.sort_by(&:time)

      end

      TrackingResponse.new(success, message, Hash.from_xml(response),
                           :carrier => @@name,
                           :xml => response,
                           :request => last_request,
                           :status => status,
                           :status_code => status_code,
                           :status_description => status_description,
                           :ship_time => ship_time,
                           :scheduled_delivery_date => scheduled_delivery_time,
                           :actual_delivery_date => actual_delivery_time,
                           :delivery_signature => delivery_signature,
                           :shipment_events => shipment_events,
                           :shipper_address => (shipper_address.nil? || shipper_address.unknown?) ? nil : shipper_address,
                           :origin => origin,
                           :destination => destination,
                           :tracking_number => tracking_number
      )
    end

    def parse_delete_shipment_response(response)
      xml = build_document(response, 'ShipmentReply')

      success = response_success?(xml)
      message = response_message(xml)

      if success
        true
      else
        raise ResponseError.new("Delete shipment failed with message: #{message}")
      end
    end

    def ship_timestamp(delay_in_hours)
      delay_in_hours ||= 0
      Time.now + delay_in_hours.hours
    end

    def ship_date(delay_in_hours)
      delay_in_hours ||= 0
      (Time.now + delay_in_hours.hours).to_date
    end

    def response_success?(response)

    end

    def response_message(response)

    end

    def commit(url, request, test = false)

      host = test ? TEST_HOST : LIVE_HOST
      url = "#{host}#{url}"

      headers = {
          'Content-Type' =>  'application/json',
          'Authorization' => "Bearer #{@options[:access_token]}"
      }
      ssl_post(url, request.to_json, headers)
    end

    def parse_transit_times(times)
      results = []
      times.each do |day_count|
        days = TRANSIT_TIMES.index(day_count.to_s.chomp)
        results << days.to_i
      end
      results
    end

    def extract_address(document, possible_node_names)
      node = nil
      args = {}
      possible_node_names.each do |name|
        node = document.at(name)
        break if node
      end

      if node
        args[:country] =
            node.at('CountryCode').try(:text) ||
                ActiveUtils::Country.new(:alpha2 => 'ZZ', :name => 'Unknown or Invalid Territory', :alpha3 => 'ZZZ', :numeric => '999')

        args[:province] = node.at('StateOrProvinceCode').try(:text) || 'unknown'
        args[:city] = node.at('City').try(:text) || 'unknown'
      end

      Location.new(args)
    end

    def extract_timestamp(document, node_name)
      if timestamp_node = document.at(node_name)
        if timestamp_node.text =~ /\A(\d{4}-\d{2}-\d{2})T00:00:00\Z/
          Date.parse($1)
        else
          Time.parse(timestamp_node.text)
        end
      end
    end


    def location_uses_imperial(location)
      %w(US LR MM).include?(location.country_code(:alpha2))
    end

    def build_address(location)
      {
          address: {
              streetLines: street_address(location),
              city: location.city,
              postalCode: location.postal_code,
              countryCode: location.country_code(:alpha2),
              residential: !location.commercial?
          }
      }

    end

    def build_contact_address(location)
      {
          contact: {
              personName: location.name,
              # emailAddress: '',
              # phoneExtension: '',
              phoneNumber: location.phone,
              companyName: location.company
          }
      }.merge(build_address(location))
    end

    def street_address(location)
      [location.address1, location.address2].reject{|i| i.nil? || i.blank? }
    end

    def rest_ship_date(options)
      if options[:pickup_date]
        options[:pickup_date].to_date.iso8601
      else
        ship_timestamp(options[:turn_around_time]).to_date.iso8601
      end
    end

    def rate_packages_detail(packages, imperial)
      packages.collect do |pkg|
        {
            groupPackageCount: 1,
            weight: package_weight(pkg, imperial),
            dimensions: package_dimensions(pkg, imperial)
        }
      end
    end

    def shipment_packages_detail(packages, imperial)
      packages.collect do |pkg|

        detail = {
            groupPackageCount: 1,
            weight: package_weight(pkg, imperial),
            dimensions: package_dimensions(pkg, imperial),
            packageSpecialServices: {
                specialServiceTypes: ['SIGNATURE_OPTION'],
                signatureOptionType: SIGNATURE_OPTION_CODES[pkg.options[:signature_option] || :default_for_service],
                signatureOptionDetail: {
                    optionType: SIGNATURE_OPTION_CODES[pkg.options[:signature_option] || :default_for_service]
                }
            }
        }

        reference_numbers = Array(pkg.options[:reference_numbers])

        if reference_numbers.size > 0
          cus_ref_type = reference_numbers.collect do |ref_no|
            {
                customerReferenceType: ref_no[:type] || "CUSTOMER_REFERENCE",
                value: ref_no[:value]
            }
          end

          detail = detail.merge(customerReferences: cus_ref_type)

        end

      end

    end

    def package_weight(pkg, imperial)
      {
          units: imperial ? 'LB' : 'KG',
          value: [((imperial ? pkg.lbs : pkg.kgs).to_f * 1000).round / 1000.0, 0.1].max
      }
    end

    def package_dimensions(pkg, imperial)
      {
          length: (((imperial ? pkg.inches(:length) : pkg.cm(:length)).to_f * 1000).round / 1000.0).ceil,
          width:  (((imperial ? pkg.inches(:width) : pkg.cm(:width)).to_f * 1000).round / 1000.0).ceil,
          height: (((imperial ? pkg.inches(:height) : pkg.cm(:height)).to_f * 1000).round / 1000.0).ceil,
          units: imperial ? 'IN' : 'CM'
      }
    end


  end
end