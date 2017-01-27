#require 'oci8'
#!/bin/env ruby
# encoding: utf-8
module PatientBillingAccountingHelper
  module Philhealth
      #@@test_data = "CSV"
      @@test_data = "DB"
    def self.calculate_promo_discount_based_on_age(age)
      if age < 60
        return 0.16
      else
        return 0.20
      end
    end
    def self.get_order_details_based_on_order_number(num)
          #@@test_data = "DB"
           puts "in class"
          if @@test_data  == "CSV"
                  puts "in csv"
                    i = 0
                    t = ""
                    while !(t.match num)  do
                            t = read_ordered_items.readlines[i]
                            i += 1
                    end
                    i -= 1
                    d =  read_ordered_items.readlines[i].split','
          else
                puts "in db"
                Database.connect
                          t = "SELECT * FROM SLMC.MY_SERVICE_ITEMS  WHERE MSERVICE_CODE = '#{num}'"
                          d = Database.select_all_statement t
                Database.logoff

          end
          
          {
            :order_no => d[0],
            :rate => d[1],
            :mrp_tag => d[2],
            :ph_code => d[3],
            :order_type => d[4],
            :description => d[5]
            #:qualified => d[7]
          }

    end
    def self.get_or_order_details_based_on_order_number(num)
         puts "in class"
          if @@test_data  == "CSV"
                    i = 0
                    t = ""
                    while !(t.match num)  do
                      t = read_or_ordered_items.readlines[i]
                      i += 1
                    end
                    i -= 1
                    d =  read_or_ordered_items.readlines[i].split','
           else
                    puts "in db"
                    Database.connect
                              t = "SELECT * FROM SLMC.MY_SERVICE_ITEMS  WHERE MSERVICE_CODE = '#{num}'"
                              d = Database.select_all_statement t
                    Database.logoff

          end

      {
        :order_no => d[0],
        :rate => d[1],
        :mrp_tag => d[2],
        :ph_code => d[3],
        :order_type => d[4],
        :description => d[5]
        #:qualified => d[7]
      }
    end
    def self.get_inpatient_order_details_based_on_order_number(num)
            if @@test_data  == "CSV"
                    i = 0
                    t = ""
                    while !(t.match num)  do
                              t = read_inpatient_ordered_items.readlines[i]
                              i += 1
                    end
                    i -= 1
                    d =  read_inpatient_ordered_items.readlines[i].split','
            else
                    puts "in db"
                    Database.connect
                           t = "SELECT * FROM SLMC.MY_SERVICE_ITEMS  WHERE MSERVICE_CODE = '#{num}'"
                           d = Database.select_all_statement t
                    Database.logoff
            end
            {
              :order_no => d[0],
              :rate => d[1],
              :mrp_tag => d[2],
              :ph_code => d[3],
              :order_type => d[4],
              :description => d[5]
              #:qualified => d[7]
            }
    end
    def self.get_discount_covered(num)
      i = 0
      t = ""
      while !(t.match num)  do
        t = read_discount_covered.readlines[i]
        i += 1
      end
      i -= 1
      d =  read_discount_covered.readlines[i].split','
      {
        :order_type => d[0],
        :service_category => d[1],
        :therapeutic_med_flag => d[2],
        :discount_percentage => d[3],
      }
    end
    def self.get_rvu_value(rvu)
      i = 0
      t = ""
      while !(t.match rvu)  do
        t = read_rvu_codes.readlines[i]
        i += 1
      end
      i -= 1
      d =  read_rvu_codes.readlines[i].split','
      {
        :code => d[0],
        :value => d[1]
      }
    end
    def self.get_ordinary_ph_benefit_using_code(ph_benefit)
      i = 0
      t = ""
      while !(t.match ph_benefit)  do
        t = read_ordinary_ref_ph_benefit.readlines[i]
        i += 1
      end
      i -= 1
      d = read_ordinary_ref_ph_benefit.readlines[i].split','
      {
        :ph_benefit => d[0],
        :remarks => d[1],
        :max_days => d[2],
        :daily_amt => d[3],
        :max_amt => d[4],
        :ph_pcf => d[5]
      }
    end
    def self.get_ref_ph_benefit_using_code(ph_case_type,ph_benefit)
      i = 0
      t = ""
      while !((t.match ph_case_type) && (t.match ph_benefit))  do
        t = read_ref_ph_benefit.readlines[i]
        i += 1
      end
      i -= 1
      d = read_ref_ph_benefit.readlines[i].split','
      {
        :ph_case_type => d[0],
        :ph_benefit => d[1],
        :remarks => d[2],
        :max_days => d[3],
        :daily_amt => d[4],
        :min_amt => d[5],
        :max_amt => d[6],
        :ph_pcf => d[7]
      }
    end
    def self.read_ordered_items
      File.new(File.dirname(__FILE__) +  '/../../../csv/ordered_items.csv')
    end
    def self.read_or_ordered_items
      File.new(File.dirname(__FILE__) + '/../../../csv/or_ordered_items.csv')
    end
    def self.read_inpatient_ordered_items
      File.new(File.dirname(__FILE__) + '/../../../csv/inpatient_ordered_items.csv')
    end
    def self.read_discount_covered
      File.new(File.dirname(__FILE__) + '/../../../csv/discount_covered.csv')
    end
    def self.read_rvu_codes
      File.new(File.dirname(__FILE__) +  '/../../../csv/rvu_codes.csv')
    end
    def self.read_ordinary_ref_ph_benefit
      File.new(File.dirname(__FILE__) +  '/../../../csv/ordinary_case_ref_ph_benefit.csv')
    end
    def self.read_ref_ph_benefit
      File.new(File.dirname(__FILE__) +  '/../../../csv/ref_ph_benefit.csv')
    end
    def self.read_fm_package_scenario
      File.new(File.dirname(__FILE__) +  '/../../../csv/fmpackage.csv')
    end
    def self.read_fm_priceupdate_scenario
      File.new(File.dirname(__FILE__) +  '/../../../csv/priceupdatescenario.csv')
    end
    def self.get_read_fm_package_scenario(row)
     d =  read_fm_package_scenario.readlines[row].split','
          {
            :package_type => d[0],
            :patient_type => d[1],
            :no_of_days => d[2],
            :status => d[3]
          }
   end
    def self.get_read_fm_priceupdate_scenario(row)
      d =  read_fm_priceupdate_scenario.readlines[row].split','
          {
            :inclusion => d[0],
            :specific_item => d[1],
            :with_exclusion => d[2]

          }
  end
    def self.fm_add_service_scenario(row)
     d =  fm_add_service_scene.readlines[row].split','
          {
            :depcode => d[0],
            :mservice => d[1],
            :order_type => d[2],
            :ph_code => d[3],
            :uom => d[4],
            :ph_benefits => d[5],
            :owning => d[6],
            :using =>d[7],
            :rate => d[8]
          }
   end
    def self.fm_add_service_scene
      File.new(File.dirname(__FILE__) +  '/../../../csv/fm_service_scenario.csv')
end
    def self.get_mserrate(num)
          Database.connect
                t = "SELECT * FROM SLMC.MY_SERVICE_ITEMS  WHERE MSERVICE_CODE = '#{num}'"
               d = Database.select_all_statement t
           Database.logoff 
            {
              :order_no => d[0],
              :rate => d[1],
              :mrp_tag => d[2],
              :ph_code => d[3],
              :order_type => d[4],
              :description => d[5]
              #:qualified => d[7]
            }
    end
  end
end