#require File.dirname(__FILE__) + '/../lib/mdp'
#require File.dirname(__FILE__) + '/../lib/slmcqc'
require File.dirname(__FILE__) + '/../lib/slmc'
require 'selenium/rspec/spec_helper'
require 'faker'
require 'oci8'
    

describe "MD PORTAL :: Scenario Testing" do

  attr_reader :selenium_driver, :selenium_driver2, :selenium_driver3
#  alias :mdp :selenium_driver
  alias :slmc :selenium_driver2
  alias :slmc :selenium_driver3

  before(:all) do
  #  @selenium_driver = MDP.new#(:browser => "*iexplore")
  #  @selenium_driver2 = SLMCQC.new#(:browser => "*iexplore")
    @selenium_driver3 = SLMC.new#(:browser => "*iexplore")
#    @selenium_driver.start_new_browser_session
#    @selenium_driver2.start_new_browser_session
    @selenium_driver3.start_new_browser_session
    #@selenium_driver.window_maximize
    @password = "123qweuser"
    @@date_today = Date.today.strftime("%m/%d/%Y")
    @@room_add = "GPR#{AdmissionHelper.numerify("###")}"


  end

  after(:all) do
    slmc.logout
    slmc.close
    slmc.close_current_browser_session
#    mdp.mdp_logout
#    mdp.close
#    mdp.close_current_browser_session
  end

     
    it "MD PORTAL: Discharge Patient with ordered Package w/results and Ancillary Item with results but w/o Optek." do #ok
      patient_data = Admission.generate_data
      slmc.login('adm10', @password).should be_true
      slmc.admission_search(:pin => "1")
      pin = slmc.create_new_patient(patient_data.merge(:last_name => "SELEÑIUM", :birth_day => "12/11/1983"))
      pin.should_not == ""
      puts pin
      slmc.admission_search(:pin => pin)
      org_code = slmc.create_new_admission(:account_class => "INDIVIDUAL",
                                :room_charge => "REGULAR PRIVATE",
                                :rch_code => "RCH08",
                                :org_code => "0287",
                                :room_no => "MDP",
                                :diagnosis => "010012",
                                :packagecode => "true",
                                :doctor => "5920",
                                :guarantor_tel => "7777777")
      slmc.login("exist", "123qweadmin")
      slmc.modify_user_credentials(:user_name => "mike",
                                  :org_code => org_code)


      slmc.login("exist", "123qweadmin")
      slmc.modify_user_credentials(:user_name => "validator",
                                  :org_code => org_code)

      slmc.login('mike','mike').should be_true
      slmc.go_to_general_units_page
      slmc.late_patient_search(:criteria => pin)
      slmc.goto_late_trans_action_page(:action => "Doctor and PF Amount")
      slmc.gu_multiple_doctor(:gu_doc1 => "6095",
                              :gu_doc2 => "0488")
      slmc.go_to_general_units_page
      slmc.late_patient_search(:criteria => pin)
      slmc.goto_late_trans_action_page(:action => "Package Management")
      slmc.package_validation(:packdoc_code => "5920")

      slmc.login('mike','mike').should be_true
      slmc.go_to_general_units_page
      slmc.late_patient_search(:criteria => pin)
      slmc.goto_late_trans_action_page(:action => "Order Page")
      slmc.search_order(:ancillary => true,
                        :code => "010001901").should == ""
      slmc.add_returned_order(:others => true,
                        :ancillary_description => "COLONOSCOPY (PEDIA)",
                        :req_doctor => "5920",
                        :add => true)
      slmc.search_order(:ancillary => true,
                        :code => "010001892").should == ""
      slmc.add_returned_order(:others => true,
                        :ancillary_description => "ANAL ENTEROSCOPY",
                        :req_doctor => "5920",
                        :add => true)
       slmc.submit_added_order
      slmc.order_validate_all_items
      slmc.confirm_validation_all_items.should be_true

      slmc.login("dastech-micros1", @password)
      slmc.go_to_arms_dastect_package
      slmc.dastech_search(:criteria => pin,
                          :more_options => true,
                          #:ci_no => @@ci_no3,
                          :item_code => "010001021")
      slmc.dastech_search_checking.should == true
      slmc.go_to_result_data_entry_page
      slmc.das_tech_landing_page("ARMS Result Data Entry").should == true
       slmc.dasmicro_result_data_entry(:label1 => "Selenium Test",
                                      :unit1 => "1",
                                      :label2 => "Test",
                                      :sig1 => "0228",
                                      :sig2 => "0228")

      slmc.tag_as_official_package
      slmc.go_to_arms_dastect_package
      slmc.dastech_search(:criteria => pin,
                          :more_options => true,
                          #:ci_no => @@ci_no3,
                          :item_code => "010001039")
      slmc.dastech_search_checking.should == true
      slmc.go_to_result_data_entry_page
      slmc.das_tech_landing_page("ARMS Result Data Entry").should == true
      slmc.dasurine_result_data_entry(:field1 => "Selenium Test",
                                      :field2 => "1",
                                      :field3 => "Test",
                                      :sig1 => "0228",
                                      :sig2 => "0228")
      slmc.tag_as_official_package
      slmc.login("dastech-xray1", @password)
      slmc.go_to_arms_dastect_package
      slmc.dastech_search(:criteria => pin,
                          :more_options => true,
                          #:ci_no => @@ci_no4,
                          :item_code => "010001137")
      slmc.dastech_search_checking.should == true
      slmc.go_to_result_data_entry_page
      slmc.das_tech_landing_page("ARMS Result Data Entry").should == true
      slmc.dastech_result_data_entry(:exam_val => "MD PORTAL SELENIUM TEST",
                                      :history2 => "MD PORTAL SELENIUM TEST",
                                      :compare => "MD PORTAL SELENIUM TEST",
                                      :technique => "MD PORTAL SELENIUM TEST",
                                      :findres => "MD PORTAL SELENIUM TEST",
                                      :impress => "MD PORTAL SELENIUM TEST",
                                      :remarks => "MD PORTAL SELENIUM TEST",
                                      :sig1 => "0228",
                                      :sig2 => "0228",
                                      :save => true,
                                      :testno8 => "006600000000001")
      slmc.tag_as_official_package
      slmc.login("dastech-hema1", @password)
      slmc.go_to_arms_dastect_package
      slmc.dastech_search(:criteria => pin,
                          :more_options => true,
                          #:ci_no => @@ci_no1,
                          :item_code => "010000385")
      slmc.dastech_search_checking.should == true
      slmc.go_to_result_data_entry_page
      slmc.das_tech_landing_page("ARMS Result Data Entry").should == true
      slmc.dascbc_result_data_entry(:specimen => "label=BLOOD",
                                    :result1 => "12",
                                    :machine => "label=MANUAL",
                                      :normalval2 => "12",
                                      :sig1 => "0228",
                                      :sig2 => "0228",
                                      :save => true,
                                      :testno9 => "005800000000026",
                                      :testno10 => "005800000000025")
      slmc.tag_as_official_package

      slmc.login("dastech-idd1", @password)
      slmc.go_to_arms_das_technologist
      slmc.dastech_search(:criteria => pin,
                          :more_options => true,
                          #:ci_no => @@ci_no,
                          :item_code => "010001901")
      slmc.dastech_search_checking.should == true
      slmc.go_to_result_data_entry_page
      slmc.das_tech_landing_page("ARMS Result Data Entry").should == true
      slmc.dastech_result_data_entry(:indication => "COLONOSCOPY (PEDIA)",
                                     :history => "MDPORTAL SELENIUM TEST",
                                     :medication => "MDPORTAL SELENIUM TEST",
                                     :endofindings => "MDPORTAL SELENIUM TEST",
                                     :diagnosis => "MDPORTAL SELENIUM TEST",
                                     :recomendation => "MDPORTAL SELENIUM TEST",
                                     :sig1 => "0228",
                                     :sig2 => "0228",
                                     :save => true,
                                     :testno =>"010300000000011")
      slmc.data_entry_tag_as_official
      slmc.go_to_arms_das_technologist
      slmc.dastech_search(:criteria => pin,
                          :more_options => true,
                          #:ci_no => @@ci_no,
                          :item_code => "010001892")
      slmc.dastech_search_checking.should == true
      slmc.go_to_result_data_entry_page
      slmc.das_tech_landing_page("ARMS Result Data Entry").should == true
      slmc.dastech_result_data_entry(:indication => "ANAL ENTEROSCOPY",
                                     :history => "MDPORTAL SELENIUM TEST2",
                                     :medication => "MDPORTAL SELENIUM TEST2",
                                     :endofindings => "MDPORTAL SELENIUM TEST2",
                                     :diagnosis => "MDPORTAL SELENIUM TEST2",
                                     :recomendation => "MDPORTAL SELENIUM TEST2",
                                     :sig1 => "0228",
                                     :sig2 => "0228",
                                     :save => true,
                                     :testno =>"010300000000014")
      slmc.data_entry_tag_as_official
#      mdp.mdp_login("mflim", "mflim").should == true
#      mdp.mdp_menu(:mdp_pin => pin)
#      puts pin
#      mdp.mdp_menu_checking(pin).should == true
#      mdp.mdp_check_package_visit_record(:procedure_pckge => true,
#                                         :labtest_pckge => true).should == true
#      mdp.mdp_check_package_procedure_testlist(:procedure_pckge2 => true,
#                                         :labtest_pckge2 => true).should == true

      slmc.login('mike','mike').should be_true
      slmc.go_to_general_units_page
      slmc.late_patient_search(:criteria => pin)
      slmc.goto_late_trans_action_page(:action => "regexp:Discharge Instructions\\s")
      slmc.multiple_diagnosis(:discharge_dispo => "RECOVERED")
      slmc.go_to_general_units_page
      slmc.late_patient_search(:criteria => pin)
      slmc.goto_late_trans_action_page(:action => "Doctor and PF Amount")
      slmc.gu_multiple_doctor(:doc_pf1 => "5000",
                              :doc_pf2 => "5000",
                              :doc_pf3 => "5000",
                              :discharge => true)
#      slmc.login('pba10', @password).should be_true
#      slmc.go_to_patient_billing_accounting_page
#      v_number = slmc.pba_search(:pin => pin)
#      slmc.go_to_page_using_visit_number("Discharge Patient", v_number)
#      slmc.select_discharge_patient_type(:type => "STANDARD",
#                                         :full_payment => true)
#
#      slmc.login('mike','mike').should be_true
#      slmc.go_to_general_units_page
#      slmc.late_patient_search(:criteria => pin)
#      slmc.gu_physically_out(:roombedstat => "label=GENERAL CLEANING")

#      mdp.mdp_login("mflim", "mflim").should == true
#      mdp.mdp_discharge(:discharge_pin => pin)
#      puts pin
#      mdp.mdp_discharge_checking(pin).should == true
#      mdp.mdp_discharge_print_this_page
#      mdp.mdp_discharge_print_all_list
#      mdp.mdp_multiple_diag_checking.should == true
#      mdp.mdp_discharge_visitlist.should == true
#      mdp.mdp_check_discharge_visit_record(:discharge_procedure => true,
#                                           :discharge_labtest => true).should == true
#      mdp.mdp_discharge_patient_procedure_testlist(:discharge_procedure2 => true,
#                                               :discharge_labtest2 => true).should == true
#
#      mdp.mdp_login("pvsantosestrella", "pvsantosestrella").should == true
#      mdp.mdp_discharge(:discharge_pin => pin)
#      puts pin
#      mdp.mdp_discharge_checking(pin).should == true
#      mdp.mdp_discharge_print_this_page
#      mdp.mdp_discharge_print_all_list
#      mdp.mdp_multiple_diag_checking.should == true
#      mdp.mdp_discharge_visitlist.should == true
#      mdp.mdp_check_discharge_visit_record(:discharge_procedure => true,
#                                           :discharge_labtest => true).should == true
#      mdp.mdp_discharge_patient_procedure_testlist(:discharge_procedure2 => true,
#                                               :discharge_labtest2 => true).should == true
#
#      mdp.mdp_login("mrver", "mrver").should == true
#      mdp.mdp_discharge(:discharge_pin => pin)
#      puts pin
#      mdp.mdp_discharge_checking(pin).should == true
#      mdp.mdp_discharge_print_this_page
#      mdp.mdp_discharge_print_all_list
#      mdp.mdp_multiple_diag_checking.should == true
#      mdp.mdp_discharge_visitlist.should == true
#      mdp.mdp_check_discharge_visit_record(:discharge_procedure => true,
#                                           :discharge_labtest => true).should == true
#      mdp.mdp_discharge_patient_procedure_testlist(:discharge_procedure2 => true,
#                                               :discharge_labtest2 => true).should == true
    end
  
      it "MD PORTAL: Patient with Room Transfer" do #ok
      patient_data = Admission.generate_data
      slmc.login('adm10', @password).should be_true
      slmc.admission_search(:pin => "1")
      pin = slmc.create_new_patient(patient_data.merge(:last_name => "SELEÑIUM", :birth_day => "12/11/1983"))
      pin.should_not == ""
      puts pin
      slmc.admission_search(:pin => pin)
      org_code = slmc.create_new_admission(:account_class => "INDIVIDUAL",
                                :room_charge => "REGULAR PRIVATE",
                                :rch_code => "RCH08",
                                :org_code => "0287",
                                :room_no => "MDP",
                                :diagnosis => "010012",
                                :doctor => "5920",
                                :guarantor_tel => "7777777")

        slmc.login('adm10', @password).should be_true
        slmc.admission_search(:pin => pin)
        slmc.mdp_update_admission_link

       @room = ""
        room = slmc.adm_roomgc
        if(room == "")
          room.should == true
        end

      @bed = ""
        bed = slmc.adm_bedgc
        if(bed == "")
          bed.should == true
        end

        mdp.mdp_login("mflim", "mflim").should == true
        mdp.mdp_menu(:mdp_pin => pin)
        puts pin
        mdp.mdp_roombed_checking

       @mdproom = ""
       mdproom = mdp.mdp_roomgc
       if(mdproom == "")
         mdproom.should == @room
        end
       @mdpbed = ""
       mdpbed = mdp.mdp_bedgc
       if(mdpbed == "")
         mdpbed.should == @bed
       end

      slmc.login("exist", "123qweadmin")
      slmc.modify_user_credentials(:user_name => "mike",
                                  :org_code => org_code)

      slmc.login('mike','mike').should be_true
      slmc.go_to_general_units_page
      slmc.late_patient_search(:criteria => pin)
      slmc.goto_late_trans_action_page(:action => "label=Request for Room Transfer")
      slmc.gu_roombed_trans(:gu_roomtrans1 => true)

      slmc.login('adm10', @password).should be_true
      slmc.admission_search(:pin => pin)
      slmc.adm_roombed_trans(:adm_roomtrans1 => true, :pin => pin)

      slmc.login('mike','mike').should be_true
      slmc.go_to_general_units_page
      slmc.gu_roombed_trans(:gu_roomtrans2 => true, :pin => pin)

      slmc.login('adm10', @password).should be_true
      slmc.admission_search(:pin => pin)
      slmc.adm_roombed_trans(:adm_roomtrans2 => true,:pin => pin)


      slmc.login('adm10', @password).should be_true
      slmc.admission_search(:pin => pin)
      slmc.mdp_update_admission_link

       @room = ""
        room = slmc.adm_roomgc
        if(room == "")
          room.should == true
        end

      @bed = ""
        bed = slmc.adm_bedgc
        if(bed == "")
          bed.should == true
        end

        mdp.mdp_login("mflim", "mflim").should == true
        mdp.mdp_menu(:mdp_pin => pin)
        puts pin
        mdp.mdp_roombed_checking

       @mdproom = ""
       mdproom = mdp.mdp_roomgc
       if(mdproom == "")
         mdproom.should == @room
        end
       @mdpbed = ""
       mdpbed = mdp.mdp_bedgc
       if(mdpbed == "")
         mdpbed.should == @bed
       end
  end
end