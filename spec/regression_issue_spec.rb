#!/bin/env ruby
# encoding: utf-8


#require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
require 'spec_helper'

describe "SLMC ::  Regression Issue" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
          @selenium_driver =  SLMC.new
          @selenium_driver.start_new_browser_session
          @password = "123qweuser"
          @or_patient = Admission.generate_data
          @individual_patient = Admission.generate_data
          @inpatient = Admission.generate_data
          @user = "gu_spec_user6"
          @or_user =  "slaquino"     #"or21"

          @drugs =  {"049000075" => 1}
          @supplies = {"082400049" => 1}
          @ancillary = {"010003440" => 1}
          @oxygen = {"089500009" => 1}
          @others = {"060000676" => 1}
          @ancillary1 = {"010003440" => 1}
          @ancillary2= {"010003440" => 1}
          @ancillary_dup = {"010003440" => 1}
      #    @or_patient = Admission.generate_data
      #    @or_patient1 = Admission.generate_data
      #    @oss_patient = Admission.generate_data
      #    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@or_patient[:age])
            Database.connect
                      a =  "UPDATE SLMC.CTRL_APP_USER SET ORGSTRUCTURE ='0287' WHERE USERNAME ='#{@user}'"
                      Database.update_statement a
                      b =  "SELECT ORGSTRUCTURE FROM SLMC.CTRL_APP_USER WHERE USERNAME ='#{@user}'"
                      aa = Database.select_statement b
                      puts "ORGSTRUCTURE = #{aa}"
            Database.logoff
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

        it "Bug#41063 - Checklist order: Re-include UOM" do
               ################### #OR SCENARIO
                slmc.login(@or_user, @password).should be_true
                @@or_pin = slmc.or_create_patient_record(@or_patient.merge(:admit => true)).gsub(' ', '')
                slmc.go_to_occupancy_list_page
                slmc.patient_pin_search(:pin => @@or_pin)
                slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@or_pin)
                slmc.click "id=nonProcedureFlag"
                slmc.type "id=oif_entity_finder_key", "04400678"
                slmc.click "name=search"
                sleep 3
                slmc.is_element_present('//*[@id="uom"]')
                slmc.click "//input[@value='Add']", :wait_for =>:page
                slmc.is_element_present('//*[@id="uom"]')
                slmc.type "id=aQuantity", "1"
                slmc.type "id=sQuantity", "1"
                slmc.click "//input[@value='Add']", :wait_for =>:page
                order = slmc.get_text('//html/body/div/div[2]/div[2]/form/div[4]/div[2]/div[4]/table/tbody/tr/td/a')
                (order).should_not == nil
                sleep 3
                slmc.click(('//html/body/div/div[2]/div[2]/form/div[4]/div[2]/div[4]/table/tbody/tr/td/a'), :wait_for =>:page)
                sleep 3
                slmc.click "name=delete",:wait_for =>:page
                slmc.is_text_present("deleted successfully.")
                puts @@or_pin
                sleep 6
               ########### #ER SCENARIO
               sleep 20
               slmc.click "link=Home", :wait_for => :page
                slmc.login("er1", @password).should be_true
                slmc.click "link=E.R. Landing Page",:wait_for =>:page
                mycount = slmc.get_xpath_count('//html/body/div/div[2]/div[2]/table/tbody')
                puts "mycount = #{mycount}"
                sleep 30
                x= 1
                while x != mycount
                        if x == 1
                              status = slmc.get_text("//html/body/div[1]/div[2]/div[2]/table/tbody/tr[1]/td[8]")
                                                             
                            else
                               status = slmc.get_text("//html/body/div[1]/div[2]/div[2]/table/tbody/tr[#{x}]/td[8]")

                        end
                        if status == "" || "Outpatient Registration"
                              if x== 1
                                #get pin
                                  pin =  slmc.get_text("//html/body/div[1]/div[2]/div[2]/table/tbody/tr[1]/td[3]")
                               
                                  
                                  pin = pin.gsub(' ', '')
                                  x = mycount
                              else
                                   pin=  slmc.get_text("//html/body/div[1]/div[2]/div[2]/table/tbody/tr[#{x}]/td[3]")
                                  pin = pin.gsub(' ', '')
                                   x = mycount
                              end

                         else
                               if x == 20
                                    slmc.click("link=Next ›") 
                                    sleep 8
                                    x =1
                               else
                                  x = x + 1
                              end
                        end

                end
                slmc.patient_pin_search(:pin => pin)
                slmc.go_to_su_page_for_a_given_pin("Checklist Order", pin)
                slmc.click "id=nonProcedureFlag"
                slmc.type "id=oif_entity_finder_key", "04400678"
                slmc.click "name=search"
                sleep 3
                slmc.is_element_present('//*[@id="uom"]')
                slmc.click "//input[@value='Add']", :wait_for =>:page
                slmc.is_element_present('//*[@id="uom"]')
                slmc.type "id=aQuantity", "1"
                slmc.type "id=sQuantity", "1"
                slmc.click "//input[@value='Add']", :wait_for =>:page
                sleep 3
                order = slmc.get_text('//html/body/div/div[2]/div[2]/form/div[4]/div[2]/div[4]/table/tbody/tr/td/a')
                sleep 3
                (order).should_not == nil
                slmc.click "name=validateOrder", :wait_for =>:page
                slmc.click "name=orderCartDetailNumber"
                slmc.click "id=delete"
                slmc.click "//input[@value='Proceed']", :wait_for =>:page
                slmc.is_text_present("deleted successfully.")
               ############################ #DR SCENARIO
               sleep 20
                      slmc.click "link=Home", :wait_for => :page
                slmc.login("dr1", @password).should be_true
                slmc.click "link=Nursing Special Units Landing Page",:wait_for =>:page
                slmc.click "link=Occupancy List",:wait_for =>:page
                mycount = slmc.get_xpath_count('//html/body/div/div[2]/div[2]/table/tbody')
                x= 1
                while x != mycount
                        if x == 1
                              status = slmc.get_text("//html/body/div/div[2]/div[2]/table/tbody/tr/td[8]")

                            else
                               status = slmc.get_text("//html/body/div/div[2]/div[2]/table/tbody/tr[#{x}]/td[8]")
                        end
                        if status == ""
                              if x== 1
                                #get pin
                                  pin =  slmc.get_text("//html/body/div/div[2]/div[2]/table/tbody/tr/td[3]")
                                  pin = pin.gsub(' ', '')
                                  x = mycount
                              else
                                  pin=    slmc.get_text("//html/body/div/div[2]/div[2]/table/tbody/tr[#{x}]/td[3]")
                                  pin = pin.gsub(' ', '')
                                  x = mycount
                              end

                         else
                              if x == 20
                                  slmc.click "link=Next ›", :wait_for =>:page
                                  x = 1
                              else
                                  x = x + 1
                              end

                        end
                end
                slmc.patient_pin_search(:pin => pin)
                slmc.go_to_su_page_for_a_given_pin("Checklist Order", pin)
                slmc.click "id=nonProcedureFlag"
                slmc.type "id=oif_entity_finder_key", "04400678"
                slmc.click "name=search"
                sleep 3
                slmc.is_element_present('//*[@id="uom"]')
                slmc.click "//input[@value='Add']", :wait_for =>:page
                slmc.is_element_present('//*[@id="uom"]')
                slmc.type "id=aQuantity", "1"
                slmc.type "id=sQuantity", "1"
                slmc.click "//input[@value='Add']", :wait_for =>:page
                sleep 3
                order = slmc.get_text('//html/body/div/div[2]/div[2]/form/div[4]/div[2]/div[4]/table/tbody/tr/td/a')
                sleep 3
                (order).should_not == nil
                slmc.click "name=validateOrder", :wait_for =>:page
                slmc.click "name=orderCartDetailNumber"
                slmc.click "id=delete"
                slmc.click "//input[@value='Proceed']", :wait_for =>:page
                slmc.is_text_present("deleted successfully.")

        end
        it "Feature #59377 - Order List modifications" do
               ##################### #General Units - Order List
               sleep 10
           #          slmc.click "link=Home", :wait_for => :page
            slmc.login(@user, @password).should be_true
            slmc.admission_search(:pin => "Test")
            pin = slmc.create_new_patient(@inpatient.merge!(:gender => 'F')).gsub(' ', '')

            sleep 6
            slmc.click "link=Home", :wait_for => :page
            slmc.login(@user, @password).should be_true
            slmc.admission_search(:pin => pin).should be_true
            slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
              :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726",:package => "PLAN A FEMALE").should == "Patient admission details successfully saved."
           sleep 20
            slmc.login(@user, @password).should be_true
            slmc.go_to_general_units_page
            slmc.nursing_gu_search(:pin => pin)
            slmc.go_to_gu_page_for_a_given_pin("Order Page", pin)
            @drugs.each do |item, q|
              slmc.search_order(:description => item, :drugs => true).should be_true
              slmc.add_returned_order(:drugs => true, :description => item,
                :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true

            end
            @ancillary.each do |item, q|
              slmc.search_order(:description => item, :ancillary => true).should be_true
              slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
            end
            @supplies.each do |item, q|
              slmc.search_order(:description => item, :supplies => true).should be_true
              slmc.add_returned_order(:supplies => true, :description => item, :add => true).should be_true
            end
          #  slmc.beep
            @oxygen.each do |item, q|
              slmc.search_order(:description => item, :medical_gases => true).should be_true
              slmc.add_returned_order(:medical_gases => true, :description => item, :device => "NASAL CANNULA", :lpm => 1,:add => true).should be_true
            end

              @others.each do |item, q|
              slmc.search_order(:description => item, :others => true).should be_true
              slmc.add_returned_order(:others => true, :description => item, :add => true).should be_true
            end

            sleep 8
            slmc.verify_ordered_items_count(:drugs => 1).should be_true
            slmc.verify_ordered_items_count(:ancillary => 1).should be_true
            slmc.verify_ordered_items_count(:supplies => 1).should be_true
            slmc.verify_ordered_items_count(:oxygen => 1).should be_true
            slmc.verify_ordered_items_count(:others => 1).should be_true
            slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
            slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple", :oxygen => true, :others => true).should == 5
            slmc.confirm_validation_all_items.should be_true
            sleep 6
            slmc.go_to_general_units_page
            slmc.nursing_gu_search(:pin => pin)
            slmc.go_to_gu_page_for_a_given_pin("Order List", pin)
            (slmc.get_text("//html/body/div/div[2]/div[2]/div[5]/ul/li/a/span")).should == "ORDERS"
            (slmc.get_text("//html/body/div/div[2]/div[2]/div[5]/ul/li[2]/a/span")).should == "CHECKLIST"
            (slmc.get_text("//html/body/div/div[2]/div[2]/div[5]/ul/li[3]/a/span")).should == "PACKAGE"


          end
        it "Issue # 56018 - Newborn Admission: Add’l Patient Suffix field" do
                  slmc.login(@user, @password).should be_true
                  suffix  = ["II","III","IV","IX","JR","SR","V","VI","VII","VIII"]
                  selected_suffix = suffix.rand
                  pin = []
                  sleep 6
                  slmc.click "link=Home", :wait_for => :page
                  slmc.login("dr1","123qweuser")
                  Database.connect
                  q = "SELECT A.PIN FROM SLMC.TXN_ADM_ENCOUNTER A JOIN  SLMC.TXN_PATMAS B ON A.PIN = B.PIN WHERE B.GENDER = 'F' AND A.ADM_FLAG = 'Y' ORDER BY PIN DESC  "
                  pin = Database.select_statement q
                  Database.logoff                  
                  motherpin = pin
                  
                  slmc.click("link=Nursing Special Units Landing Page",:wait_for => :page);
                  slmc.click("link=Newborn Admission", :wait_for => :page);
                  slmc.click("xpath=(//input[@value='Search'])[6]");
                  slmc.type("id=af_entity_finder_key", motherpin);
                  slmc.click("css=input[type=\"button\"]");
                  sleep 3
                  slmc.click("link=#{motherpin}");
                  slmc.click("id=genderFemale");
                  slmc.select("id=inPatientAdmission.patient.suffix.code", "label=#{selected_suffix}");
                  slmc.type("id=birthDate", "06/03/2013");
                  slmc.select("id=birthHour", "label=1");
                  slmc.select("id=birthMinute", "label=0");
                  slmc.select("id=birthSecond", "label=1");
                  slmc.select("id=birthAMPM", "label=AM");
                  slmc.select("id=birthType.code", "label=SINGLE");
                  slmc.select("id=birthOrder.code", "label=FIRST");
                  slmc.click("css=option[value=\"BOR01\"]");
                  slmc.click("id=aog");
                  slmc.type("id=aog", "1");
                  slmc.type("id=weight", "14");
                  slmc.select("id=apgarScore", "label=2");
                  slmc.click("css=#apgarScore > option[value=\"2\"]");
                  slmc.type("id=length", "15");
                  slmc.type("id=length", "15");
                  slmc.type("id=admissionDate", "07/04/2013");
                  slmc.click("xpath=(//input[@type='button'])[18]");
                  slmc.type("id=entity_finder_key", "6726");
                  slmc.click("css=#doctorFinderForm > div.finderFormContents > div > input[type=\"button\"]");
                  slmc.select("id=roomChargeCode", "label=REGULAR PRIVATE");
                  slmc.click("id=searchNursingUnitBtn");
                  slmc.click("css=div.searchArea > input[type=\"button\"]");
                  slmc.type("id=osf_entity_finder_key", "0285");
                  slmc.click("css=div.searchArea > input[type=\"button\"]");
               #   slmc.click("link=0285");
                  slmc.click("css=div.searchArea > input[type=\"button\"]");
                  slmc.click("id=nursingUnitCode");
                  slmc.click("id=searchRoomBedBtn");
                  slmc.click("css=#roomBedFinderForm > div.finderFormContents > div.searchArea > input[type=\"button\"]");
                  sleep 3
                  #slmc.click"//html/body/div/div[2]/div[2]/div[9]/div[2]/div[2]/div[2]/table/tbody/tr/td"
                  slmc.click"//html/body/div/div[2]/div[2]/div[9]/div[2]/div[2]/div[2]/table/tbody/tr/td/a"
                  slmc.type("id=inPatientAdmission.patient.patientRelation.er.firstName", "sadsad");
                  slmc.type("id=inPatientAdmission.patient.patientRelation.er.middleName", "dasdas");
                  slmc.type("id=inPatientAdmission.patient.patientRelation.er.lastName", "gggg");
                  slmc.select("id=inPatientAdmission.patient.patientRelation.erRelation", "label=SELF");
                  slmc.type("id=inPatientAdmission.patient.patientAddresses.streetNumber", "sadsdsa");
                  slmc.type("id=inPatientAdmission.patient.patientAddresses.buildingName", "sdasdds");
                  slmc.select("id=inPatientAdmission.patient.patientContacts.contactType.code", "label=HOME");
                  slmc.type("id=inPatientAdmission.patient.patientContacts.contactDetails", "21321321");
                  sleep 3
               #   slmc.click("id=.save", :wait_for => :page);
                  slmc.click("xpath=(//input[@name='action'])[2]", :wait_for => :page);
                  slmc.click("xpath=(//input[@name='action'])[2]",:wait_for => :page);
                  slmc.is_text_present("Patient admission details successfully saved.").should be_true
                 if selected_suffix == "JR"
                      selected_suffix ="Jr"
                  end
                  if selected_suffix == "SR"
                      selected_suffix ="Sr"
                  end
                    Database.connect
                    t = "SELECT MAX(PIN) FROM SLMC.TXN_PATMAS WHERE  FIRSTNAME = 'Baby Girl' AND LASTNAME = (SELECT LASTNAME FROM SLMC.TXN_PATMAS WHERE PIN = '#{motherpin}')"
                    babypin = Database.select_all_statement t
                    Database.logoff
                    babypin = babypin[0]
                    sleep 6
                    puts "babypin - #{babypin}"
                    slmc.click "link=Home", :wait_for => :page
                    slmc.login("adm1","123qweuser")
                    slmc.admission_search(:pin =>babypin)
                    #slmc.get_text("//html/body/div/div[2]/div[2]/div[21]/table/tbody/tr/td[5]").include?(selected_suffix).should be_true
				 slmc.get_text("//html/body/div[1]/div[2]/div[2]/div[22]/table/tbody/tr/td[4]").include?(selected_suffix).should be_true
                    sleep 6
                    slmc.click "link=Home", :wait_for => :page
                    slmc.login("dcabad","welcome123")
                    slmc.go_to_general_units_page
                    slmc.nursing_gu_search(:pin => babypin)
                    #slmc.get_tex("//html/body/div/div[2]/div[2]/table/tbody/tr/td[4]").include?(selected_suffix).should be_true
				slmc.get_text("//html/body/div[1]/div[2]/div[2]/table/tbody/tr/td[4]").include?(selected_suffix).should be_true
                  slmc.go_to_gu_page_for_a_given_pin("Order Page", babypin)
                   slmc.get_text('//*[@id="banner.fullName"]').include?(selected_suffix).should be_true
          end
        it "55430 - Nonecu Package Preview: Sorting" do
              @patient = Admission::generate_data
              slmc.login("wellness1", @password).should be_true
              slmc.go_to_wellness_package_ordering_page
              slmc.patient_pin_search(:pin => "1")
              @@wellness_pin = slmc.create_new_patient(@patient.merge!(:gender => "M"))
			puts"@@wellness_pin = #{@@wellness_pin}"
              slmc.go_to_wellness_package_ordering_page
              slmc.patient_pin_search(:pin => @@wellness_pin)
              slmc.click_outpatient_package_management
              slmc.add_wellness_package(:package => "CANCER PACKAGE - ADVANCE A MALE", :doctor => "0269").should be_true
              slmc.validate_wellness_package
              slmc.wellness_allocate_doctor_pf(:pf_type => "PF INCLUSIVE OF PACKAGE", :pf_amount => 16800)
              slmc.wellness_update_guarantor(:guarantor => "INDIVIDUAL")
              sleep 6
              slmc.go_to_wellness_package_billing_page   
              sleep 2
              slmc.patient_pin_search(:pin => @@wellness_pin)
              sleep 2							
              slmc.wellness_payment(:cash => true).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
        end
        it "53079	BIR Requirement: VAT computation on certain misc. types" do
           # slmc.login("sel_misc1", @password).should be_true
            slmc.login("pba1", @password).should be_true
            slmc.go_to_miscellaneous_payment_page
            myamount  = [1000, 500, 250,273,111,123,124]
            @amount  =   myamount.rand
            puts "@amount = #{@amount}"
            vat = ((@amount - (@amount / 1.12)) * 10**2).round.to_f / 10**2
            mymisc_type = ["INTEREST RECEIVABLES","DIVIDEND INCOME"]
            misc_type = mymisc_type.rand
            slmc.miscellaneous_payment_data_entry(:vat => true,:misc => true, :misc_type=> misc_type,:pin => "Selenium Test Patient",:received_from => "Selenium Test Patient", :submit => true, :cash => true, :amount => @amount).should be_true
            slmc.click"//input[@type='submit' and @value='Print OR']"
            slmc.click("popup_ok", :wait_for => :page) if slmc.is_element_present"popup_ok"
            Database.connect
            t = "SELECT to_char(vat_amount) FROM ( SELECT * FROM SLMC.TXN_PBA_PAYMENT_HDR WHERE RECEIVED_FROM = 'Selenium Test Patient' ORDER BY CREATED_DATETIME DESC)WHERE ROWNUM <= 1 ORDER BY ROWNUM"
            vat_from_db = Database.select_last_statement t
            Database.logoff
            puts "vat_from_db - #{vat_from_db}"
            vat_from_db = (vat_from_db).to_f
            avat_from_db =  ((vat_from_db)* 10**2).round.to_f / 10**2
            avat_from_db.should == vat

        end
        it "54220	OSS: Missing Button:Create a New Line for the order" do
              @ph_patient =  Admission.generate_data
              slmc.login("dastech1", @password).should be_true
              slmc.go_to_das_oss
              slmc.patient_pin_search(:pin => "test")
              slmc.click_outpatient_registration.should be_true
              @@oss_pin = slmc.oss_outpatient_registration(@ph_patient).should be_true
              @@oss_pin.should be_true
              @@pin = @@oss_pin.gsub(' ', '')
              slmc.go_to_das_oss
              slmc.patient_pin_search(:pin => @@pin)
              slmc.click_outpatient_order(:pin => @@pin).should be_true
              @@orders1 =  @ancillary1.merge(@ancillary2)
              @@orders1.each do |item, q|
              slmc.oss_verify_new(:order_add => true, :item_code => item, :quantity => q, :doctor => '0126',:new_line => true)
              end
          end
        it "63710	Philhealth:PF of Case Rate will be computed by Amount" do
                  #added in "philhealth_inpatient_case_rate_spec" spec
                  #from line 277 to 290
        end
        it "53066	Philhealth: Non-Case Rate Multiple Session" do
        end
        it "53057	Philhealth: Adjust regular items’ compensability class" do
        end
        it "55297	BIR Requirement: Change “CI No” to “Order No” (HCS-wide)" do
        end
        it "55143	BIR Requirement: Amount due location based on citizenship for PIN-related Misc. Payment Transactions" do
        end
        it "58466	Philhealth: Compute case rate benefit for less than 24 hours confinement" do
        end
        it "55282	BIR Requirement: Change “POS” to “Outpatient Sales”" do
        end
        it "63711	Disregard computation of Manual Discount for Late Orders" do
        end
        it "62966	Unified admission functionality for wellness role" do

        end
        it "1965 Enhancement FM - PACKAGE - PF amount should be available in Package rate" do
                slmc.login("abhernandez", @password).should be_true
                sleep 3
                slmc.click("link=File Maintenance");
                sleep 3
                slmc.click "link=Package", :wait_for => :page
                sleep 5
               #  package_description = "PLNTST#{(Time.now).strftime("%m%d%Y%H%M%S")}" + AdmissionHelper.range_rand(10,99).to_s
                 package_description = "PLNTST" + AdmissionHelper.range_rand(1000,9999).to_s + AdmissionHelper.range_rand(1000,9999).to_s
                package_short_des = "PLNTST#{(Time.now).strftime("%m%d%Y%H%M%S")}"
                slmc.type("id=txtQuery", package_description);
                slmc.click "css=input[type=\"submit\"]", :wait_for => :page
                sleep 5
                 slmc.is_text_present("Nothing found to display").should be_true
                slmc.click("id=btnPkg_add");
                package_code = (package_description).gsub("PLNTST",'')
                slmc.type"id=txtPkg_code", package_code
                slmc.type "id=txtPkg_desc",package_description
                slmc.type "id=txtPkg_shortName",package_short_des
                slmc.click "id=btnPkg_ok", :wait_for => :page
                sleep 5
                slmc.type("id=txtQuery", package_description);
                slmc.click "css=input[type=\"submit\"]", :wait_for => :page
                sleep 5
                slmc.get_text("//html/body/div/div[2]/div[2]/div[2]/form[2]/table/tbody/tr/td[2]").should == package_description
                sleep 5
                slmc.click("css=img[alt=\"Package Rate\"]", :wait_for => :page);
                slmc.package_rate(:add => true,:package_amount => 5000, :pf_amount =>500, :charge_code =>"PRESIDENTIAL",:package_code =>package_code).should be_true
                slmc.type("id=txtQuery", package_description);
                slmc.click "css=input[type=\"submit\"]", :wait_for => :page
                slmc.click("css=img[alt=\"Package Rate\"]", :wait_for => :page);
                slmc.click("css=img[alt=\"Edit\"]");
                sleep 5
                slmc.get_value('//*[@id="txtPkgRate_packageAmount"]').should == "5000.0"
                slmc.get_value('//*[@id="txtPkgRate_pfAmount"]').should == "500.0"
                slmc.click("id=btnPkgRate_cancel");
        end
        it "2057 FM: Service - Include NOW especially for items that are URGENT for updates. (eg. Consignment items)"do
                slmc.login("abhernandez", @password).should be_true
                sleep 3
                slmc.click("link=Service File Maintenance Landing Page");
                sleep 4
                slmc.click("id=btnSvcfNew");
                sleep 6
                slmc.click("id=radio_SvcfNow");
                slmc.select("id=selSvcfDept", "label=Pharmacy (04)");
                pharma_code = "P" + AdmissionHelper.range_rand(100000,999999).to_s
                slmc.type("id=txtSvcfCode", pharma_code);
                slmc.type("id=txtSvcfDesc", "selenium test");
                slmc.click("css=#aSvcfDept > img");
                slmc.type("id=txtNuQuery", "0004");
                slmc.click("id=btnNuFindSearch");
                sleep 3
                slmc.click("id=tdNuCode-0");
                slmc.click("css=#aSvcfType > img");
                slmc.type("id=txtNliQuery", "ORT02");
                slmc.click("id=btnNliFindSearch");
                sleep 3
                slmc.click("id=tdNliCode-0");
                sleep 3
                slmc.select("id=selSvcfClTag", "label=DRUG");
                slmc.click("css=option[value=\"D\"]");
                slmc.click("id=aSvcfDeptsAdd");
                sleep 6
                slmc.add_selection("id=lstNumsOrgUnitsLeft", "label=PHARMACY");
                slmc.click("id=btnNumsRight");
                slmc.click("id=btnNumsOk");
                sleep 3
                slmc.click("id=aSvcfDeptPriceOpd-0004");
                rate = "100"
                slmc.type("id=txtSvcfDeptPriceOpd-0004", rate);
                sleep 3
                slmc.click("id=txtSvcfDesc")
                slmc.click("id=radio_SvcfNow");
                slmc.click("id=btnSvcfOk")  #:wait_for =>:page)
               sleep 10
                pharma_code = "04" + pharma_code
                Database.connect
                              t = "SELECT SUM(RATE) FROM SLMC.REF_PC_SERVICE_RATE WHERE STATUS = 'A' AND SERVICE_CODE IN
                                      (SELECT SERVICE_CODE FROM SLMC.REF_PC_SERVICE WHERE STATUS = 'A' AND MSERVICE_CODE IN
                                    (SELECT MSERVICE_CODE FROM SLMC.REF_PC_MASTER_SERVICE WHERE OWN_DEPT = '0004' AND STATUS = 'A' AND MSERVICE_CODE = '#{pharma_code}'))###"
                               service_rate = Database.select_last_statement t
                Database.logoff
                service_rate = service_rate.to_f
                service_rate = (service_rate).round
                puts service_rate
                overall_rate = rate.to_f * 5
                overall_rate = overall_rate.round
                puts overall_rate
                overall_rate = overall_rate.to_s
                (overall_rate).should ==   service_rate.to_s
        end
        it "17032 - ER: Zero Amount When Selecting Update quantity of existing order " do
                slmc.login(@user, @password).should be_true
                slmc.admission_search(:pin => "1")
                @@individual = slmc.create_new_patient(@individual_patient)
                slmc.login(@user, @password).should be_true
                slmc.admission_search(:pin => @@individual)
                slmc.create_new_admission(:room_charge => "DELUXE PRIVATE", :rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
                puts @@individual

                slmc.nursing_gu_search(:pin => @@individual)
                slmc.go_to_gu_page_for_a_given_pin("Order Page", @@individual)
                @ancillary_dup.each do |item, q|
                    slmc.search_order(:description => item, :ancillary => true).should be_true
                    slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
                end
                @ancillary_dup.each do |item, q|
                    slmc.search_order(:description => item, :ancillary => true).should be_true
                    slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126", :update_qty => true).should be_true
                    Database.connect
                        d = "SELECT SUM(RATE) FROM SLMC.REF_PC_MASTER_SERVICE A JOIN SLMC.REF_PC_SERVICE B ON A.MSERVICE_CODE = B.MSERVICE_CODE JOIN SLMC.REF_PC_SERVICE_RATE C ON B.SERVICE_CODE = C.SERVICE_CODE WHERE A.MSERVICE_CODE = '#{item}' AND C.ROOM_CLASS = 'RCL02'"
                        puts d
                    @dd = Database.select_last_statement  d
                    @dd = @dd.to_f
                    puts @dd                    
                    Database.logoff                      
                end    
                
                slmc.verify_ordered_items_count(:ancillary => 1).should be_true
                slmc.submit_added_order.should be_true
                unit_price = slmc.get_text("//html/body/div[1]/div[2]/div[2]/form/ul[3]/table/tbody/tr/td[9]")
                unit_price = unit_price.gsub(",","") 
                unit_price = unit_price.to_f
                unit_price = unit_price.round
                puts "unit_price #{unit_price}"
               # dd = dd.to_f

                @dd = (@dd * 2).round
                puts "dd = #{@dd}"                
                price =  (unit_price - @dd).round
                price = price.to_f
                puts "price = #{price}"
                price.should <= 0.5 
               slmc.validate_orders(:ancillary => true,:orders => "single").should == 1                
                slmc.confirm_validation_all_items.should be_true    

        end
#        
  
#it "2519 Senior Citizen ID - Mandatory in the computation of Senior Citizen Discount"do
##ER
##OR
##DR
##Special Nursing
#
##Wellness,
##OSS,
##Special Ancillary
##Outpatient Sales
##@or_patient
##        slmc.login(@or_user, @password).should be_true
##        @@or_pin = slmc.or_create_patient_record(@or_patient.merge(:admit => true)).gsub(' ', '')
#end
#it "2521 Include notification in the Patient Registration page for the entry of Senior Citizen ID" do
#
#end
#it "2618 DAS OSS: Additional LOA# field for COHESS" do
#
#end
#it "2536 Pharmacy, CSS, FND Outpatient Sales: Make the Patient Name field mand" do
#
#end

end



  