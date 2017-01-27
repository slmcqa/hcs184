	#require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'

require 'spec_helper'
require 'yaml'
require 'oci8'
#require 'win32/sound'
#include Win32

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Discount - Inpatient Module" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver
  
  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @pba_patient1 = Admission.generate_data(:senior => true)
    @pba_patient2 = Admission.generate_data(:senior => true)
    @pba_patient3 = Admission.generate_data(:senior => true)
    @pba_patient4 = Admission.generate_data(:not_senior => true)
    @pba_patient5 = Admission.generate_data

   # @user = "update_guarantor_spec_user3"
    @password = "123qweuser"

    @drugs = {"040000357" => 1} #{"040860043" => 1}
    @drugs_mrp = {"040950576" => 1}
    @ancillary = {"010000003" => 1}
    @supplies = {"080100021" => 1}
    @operation = {"060000058" => 1}

    @o1 = {"ORT01" => 1}
    @o2 = {"ORT02" => 1}
    @o3 = {"ORT03" => 1}
    @o7 = {"ORT07" => 1}
#
#    @@employee = "1301028162"  # "1210069067" #"1112100128"
#    @@employee_dependent = "1301028163"# 1210068953" #"1112100129"
#    @@board_member = "1301028168" #"1210068962" # "1112100130"
#    @@board_member_dependent = "1303029082"#1210127715" #1210069090" # "1112100127"
#    @@doctor = "1301028149"# "1210068965"
#    @@doctor_dependent = "1309047657"#"1211069307" # "1112100132"

#1006513839 - Discount Inpatient, Inpatient_Additional_manual_discount
#1501078974 - Discount Inpatient, Inpatient_Additional_manual_discount
#1501078980 - Discount Inpatient, Inpatient_Additional_manual_discount
#1501078984 - Discount Inpatient, Inpatient_Additional_manual_discount
#1501078985 - Discount Inpatient, Inpatient_Additional_manual_discount
#1501078813 - Discount_adjustment_and_cancellation, Discount Inpatient, Inpatient_Additional_manual_discount, Discount Outpatient



    @@employee = "1006513839"
    @@employee_dependent =  "1504081720"  #"1502080612"
    @@board_member =  "1504081734" #"1501078980"
    @@board_member_dependent = "1504081736" #"1501078984"
    @@doctor = "1504081738"   #"1501078985"
    @@doctor_dependent =  "1504081732"  #"1501078813" #conflict with discount outpatient spec
    
    
    
#    @@employee = "1006513839"
#    @@employee_dependent =  "1602026899"  #"1502080612"
#    @@board_member =  "1602026882" #"1501078980"
#    @@board_member_dependent = "1602026883" #"1501078984"
#    @@doctor = "1602026884"   #"1501078985"
#    @@doctor_dependent =  "1202173093"  #"1501078813" #conflict with discount outpatient spec
#    

    @@pf_fee = 1000.0
    @@room_rate = 4762.0 # DE LUXE PRIVATE
    @@adjust_date = 1

    # DISCOUNTS TO BE USED
    @@discount_rate1 = 5000.0 # employee dependent
    @@discount_rate2 = 1000.0 #employee
    @@discount_rate3 = 50
    @@discount_rate4 = 1000.0
    @@discount_rate5 = 5000.0
    @@discount_rate6 = 10

#    @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
#    @gu_user_0287 = "gycapalungan"
#    @password = "123qweuser"
#    @pba_user = "ldcastro" #"sel_pba7"
#    @oss_user = "jtsalang"  #"sel_oss7"
#    @or_user =  "slaquino"     #"or21"

			@password = "123qweuser"
    
    if CONFIG['db_sid'] == "QAFUNC"
            @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
            #@pba_user = "ldcastro" #"sel_pba7"
            @pba_user = "pba1" #"sel_pba7"
            @or_user =  "slaquino"     #"or21"
            @oss_user = "jtsalang"  #"sel_oss7"
            @dr_user = "jpnabong" #"sel_dr4"
            @er_user =  "jtabesamis"   #"sel_er4"
            @wellness_user = "ragarcia-wellness" # "sel_wellness2"
            @gu_user_0287 = "gycapalungan"
            @pharmacy_user =  "cmrongavilla"
    else
            @user = "fcdeleon"  #"billing_spec_user3"  #admission_login#
            @pba_user = "dmgcaubang" #"sel_pba7"
            @or_user =  "amlompad"     #"or21"
            @oss_user = "kjcgangano-pet"  #"sel_oss7"
            @dr_user = "aealmonte" #"sel_dr4"
            @er_user =  "asbaltazar"   #"sel_er4"
            @wellness_user = "emllacson-wellness" # "sel_wellness2"
            @gu_user_0287 = "ajpsolomon"
    end
    
    
    
    

  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end
	
################
################ EMPLOYEE DEPENDENT
####

#    it "EMPLOYEE DEPENDENT - Create Patient" do
#      slmc.login(@gu_user_0287, @password)
#      slmc.nursing_gu_search(:pin => @@employee_dependent)
#      slmc.print_gatepass(:no_result => true, :pin => @@employee_dependent)
#      slmc.login(@user, @password)
#      slmc.admission_search(:pin => @@employee_dependent)
#      sleep 3
#      if (slmc.get_text("//html/body/div[1]/div[2]/div[2]/div[22]/table/tbody/tr/td[4]").gsub(' ', '').include?  @@employee_dependent) && slmc.is_element_present("link=Admit Patient")
#           #("//html/body/div/div[2]/div[2]/div[22]/table/tbody/tr/td[4]")
#           result = slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "EMPLOYEE DEPENDENT", :guarantor_code => "0109092")
#                   if result == "Patient admission details successfully saved." || "Unable to print patient wristband please check your printer."
#                          admission = true
#                  else
#                          admission = false
#                  end
#                  admission.should == true
#      else
#        if slmc.is_text_present("NO PATIENT FOUND")
#          @@employee_dependent = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "Tan", :first_name => "Rachel Mae", :middle_name => "Go", :birth_day => "07/26/1987", :gender => "F"))
#          puts @@employee_dependent
#        else
#          slmc.login(@gu_user_0287, @password)
#          if slmc.verify_gu_patient_status(@@employee_dependent) != "Clinically Discharged"
#            slmc.validate_incomplete_orders(:inpatient => true, :pin => @@employee_dependent, :validate => true, :username => "sel_0287_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
#            slmc.go_to_general_units_page
#            slmc.clinically_discharge_patient(:pin => @@employee_dependent, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#          end
#          slmc.login(@pba_user, @password).should be_true
#          slmc.go_to_patient_billing_accounting_page
#          slmc.pba_search(:with_discharge_notice => true, :pin => @@employee_dependent)
#          slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#          slmc.discharge_patient_either_standard_or_das.should be_true
#  
#          slmc.login(@gu_user_0287, @password).should be_true
#          slmc.nursing_gu_search(:pin => @@employee_dependent)
#         slmc.print_gatepass(:no_result => true, :pin => @@employee_dependent).should be_true
#        end
#          slmc.login(@user, @password).should be_true
#        slmc.admission_search(:pin => @@employee_dependent)
#        slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "EMPLOYEE DEPENDENT", :guarantor_code => "0109092").should == "Patient admission details successfully saved."
#      end
#    end
#    it "EMPLOYEE DEPENDENT - Create Orders" do
#       slmc.login(@gu_user_0287, @password)
#      slmc.nursing_gu_search(:pin => @@employee_dependent)
#      slmc.go_to_gu_page_for_a_given_pin("Order Page", @@employee_dependent)
#      @drugs.each do |drug, q|
#        slmc.search_order(:description => drug, :drugs => true).should be_true
#        slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#      end
#      @ancillary.each do |anc, q|
#        slmc.search_order(:description => anc, :ancillary => true ).should be_true
#        slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
#      end
#      @supplies.each do |supply, q|
#        slmc.search_order(:description => supply, :supplies => true ).should be_true
#        slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#      end
#      sleep 5
#      slmc.verify_ordered_items_count(:drugs => 1).should be_true
#      slmc.verify_ordered_items_count(:supplies => 1).should be_true
#      slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#              slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
#      slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
#      slmc.confirm_validation_all_items.should be_true
#    end
#    it "EMPLOYEE DEPENDENT - Clinical Discharge" do
#      slmc.go_to_general_units_page
#      slmc.clinically_discharge_patient(:pin => @@employee_dependent, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#    end
#    it "EMPLOYEE DEPENDENT - Compute PhilHealth" do
#      sleep 6
#     slmc.login(@pba_user, @password).should be_true
#      slmc.go_to_patient_billing_accounting_page
#      @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@employee_dependent)
#      slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
#  #   Sound.beep(5000, 3000)
#      @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "SENILE CATARACT", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "11444", :compute => true)
#      slmc.ph_save_computation
#    end
#    it "EMPLOYEE DEPENDENT - Manually Encode Discount (Courtesy Discount - Across the Board= 5000k)" do
#      slmc.go_to_patient_billing_accounting_page
#      @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@employee_dependent)
#      slmc.go_to_page_using_visit_number("Discount", @@visit_no)
#      slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :discount_rate => @@discount_rate1, :close_window => true, :save => true)
#    end
#    it "EMPLOYEE DEPENDENT - Goes to Payment Page" do
#      slmc.go_to_patient_billing_accounting_page
#      slmc.pba_search(:with_discharge_notice => true, :pin => @@employee_dependent)
#      slmc.go_to_page_using_visit_number("Payment", @@visit_no)
#    end
#    it "EMPLOYEE DEPENDENT - Checks Order Types of ordered items, Checks Discount Percentage of items" do
#      @@order_type1 = 0
#      @@order_type2 = 0
#      @@order_type3 = 0
#      @@order_type4 = 0
#  
#      @@orders = @ancillary.merge(@drugs).merge(@supplies)
#      @@orders.each do |order,n|
#        item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#        if item[:order_type] == "ORT01"
#          amt = item[:rate].to_f * n
#          @@order_type1 += amt
#        end
#        if item[:order_type] == "ORT02"
#          n_amt = item[:rate].to_f * n 
#          @@order_type2 += n_amt
#        end
#        if item[:order_type] == "ORT03"
#          x_lab_amt = item[:rate].to_f * n
#          @@order_type3 += x_lab_amt
#        end
#      end
#  
#      @@discount_percentage01 = 0
#      @@discount_percentage02 = 0
#      @@discount_percentage03 = 0
#  
#      @@orders =  @o1.merge(@o2).merge(@o3)
#      @@orders.each do |order,n|
#        item = PatientBillingAccountingHelper::Philhealth.get_discount_covered(order)
#        if item[:order_type] == "ORT01"
#          amt = item[:discount_percentage].to_f * n
#          @@discount_percentage01 += amt
#        end
#        if item[:order_type] == "ORT02" and (item[:therapeutic_med_flag] == "Y" or item[:service_category] == "Y")
#          n_amt = item[:discount_percentage].to_f * n
#          @@discount_percentage02 += n_amt
#        end
#        if item[:order_type] == "ORT03"
#          x_lab_amt = item[:discount_percentage].to_f * n
#          @@discount_percentage03 += x_lab_amt
#        end
#      end
#    end
#    it "EMPLOYEE DEPENDENT - Computes Discount for Employee Dependent" do
#      @@ort01 = @@order_type1 * @@discount_percentage01
#      @@ort02 = @@order_type2 * @@discount_percentage02
#      @@ort03 = @@order_type3 * @@discount_percentage03
#      @@class_discount = (@@ort01) + (@@ort02) + (@@ort03)
#  
#      @@gross = 0.0
#      @@orders = @drugs.merge(@ancillary).merge(@supplies)
#      @@orders.each do |order,n|
#        item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#        amt = item[:rate].to_f * n
#        @@gross += amt  # total gross amount
#      end
#      @@gross = (@@gross * 100).round.to_f / 100
#      @@discount = slmc.compute_discounts(:unit_price => @@gross, :promo => true)
#      @@courtesy_discount = slmc.compute_courtesy_discount(:fixed => true, :amount => @@discount_rate1)
#      @@total_discount = (@@discount + @@courtesy_discount)
#      @@total_hospital_bills = @@gross - @@total_discount
#      @@balance_due = @@gross - (slmc.truncate_to(@@discount,2) + slmc.truncate_to(@@courtesy_discount,2))
#    end
#    it "EMPLOYEE DEPENDENT - Checks if Computation of Gross, Discount and Balance Due are correct" do
#      @@summary = slmc.get_billing_details_from_payment_data_entry
#  
#      ((slmc.truncate_to((@@summary[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 0.02
#      ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bills),2).to_f).abs).should <= 0.02
#      ((slmc.truncate_to((@@summary[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#      ((slmc.truncate_to((@@summary[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 0.02
#    end
#    it "EMPLOYEE DEPENDENT - PBA Discharge" do
#      slmc.go_to_patient_billing_accounting_page
#      slmc.pba_search(:with_discharge_notice => true, :pin => @@employee_dependent)
#      slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#      slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#      slmc.discharge_to_payment(:philhealth => true, :diagnosis => "CHOLERA").should be_true
#    end
#    it "EMPLOYEE DEPENDENT - Discharged Patient should not be able to add discount" do
#      slmc.go_to_patient_billing_accounting_page
#      @@visit_number = slmc.pba_search(:discharged => true, :pin => @@employee_dependent)
#  #    slmc.pba_get_select_options(@@visit_number).should == ["Defer Discharge", "Generation of SOA", "PhilHealth", "Print Discharge Clearance", "Payment"] #removed "Generation of Billing Notice" 1.4.1a RC3 r28728 can be found in inhouse
#      slmc.pba_get_select_options(@@visit_number).should == ["Defer Discharge", "Generation of SOA", "PhilHealth", "Print Discharge Clearance", "Payment", "Endorsement Tagging", "View Endorsement History"] #removed "Generation of Billing Notice" 1.4.1a RC3 r28728 can be found in inhouse
#    end
          ### EMPLOYEE########## EMPLOYEE########## EMPLOYEE########## EMPLOYEE########## EMPLOYEE##
    it "EMPLOYEE - Creates patient" do
      sleep 6
      slmc.login(@gu_user_0287, @password)
      slmc.nursing_gu_search(:pin => @@employee)
      slmc.print_gatepass(:no_result => true, :pin => @@employee)
      slmc.login(@user, @password)
      slmc.admission_search(:pin => @@employee)
  
      if (slmc.get_text("//html/body/div/div[2]/div[2]/div[22]/table/tbody/tr/td[4]").gsub(' ', '').include?  @@employee) && slmc.is_element_present("link=Admit Patient")
        slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "EMPLOYEE", :guarantor_code => "0109092").should == "Patient admission details successfully saved."
      else
        if slmc.is_text_present("NO PATIENT FOUND")
          @@employee = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "Tan", :first_name => "Peter Carlo", :middle_name => "Go", :birth_day => "08/01/1986", :gender => "M"))
          @@employee.should be_true
          puts "@@employee #{@@employee}"
        else
        slmc.login(@gu_user_0287, @password)
          if slmc.verify_gu_patient_status(@@employee) != "Clinically Discharged"
            slmc.validate_incomplete_orders(:inpatient => true, :pin => @@employee, :validate => true, :username => "sel_0287_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
            slmc.go_to_general_units_page
            slmc.clinically_discharge_patient(:pin => @@employee, :pf_amount => "1000", :save => true).should be_true
          end
          slmc.login(@pba_user, @password).should be_true
          slmc.go_to_patient_billing_accounting_page
          slmc.pba_search(:with_discharge_notice => true, :pin => @@employee)
          slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
          slmc.discharge_patient_either_standard_or_das.should be_true #HEEI1R1N is 100% coverage
  
          slmc.login(@gu_user_0287, @password).should be_true
          slmc.nursing_gu_search(:pin => @@employee)
          slmc.print_gatepass(:no_result => true, :pin => @@employee).should be_true
        end
          slmc.login(@user, @password).should be_true
        slmc.admission_search(:pin => @@employee)
        slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "EMPLOYEE", :guarantor_code => "0109092").should == "Patient admission details successfully saved."
      end
    end
    it "EMPLOYEE - Order items including special item on drugs" do
      slmc.login(@gu_user_0287, @password).should be_true
      slmc.nursing_gu_search(:pin => @@employee)
      slmc.go_to_gu_page_for_a_given_pin("Order Page", @@employee)
      @drugs.each do |drug, q|
        slmc.search_order(:description => drug, :drugs => true).should be_true
        slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
      end
      @ancillary.each do |anc, q|
        slmc.search_order(:description => anc, :ancillary => true ).should be_true
        slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
      end
      @supplies.each do |supply, q|
        slmc.search_order(:description => supply, :supplies => true ).should be_true
        slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
      end
      sleep 5
      slmc.verify_ordered_items_count(:drugs => 1).should be_true
      slmc.verify_ordered_items_count(:supplies => 1).should be_true
      slmc.verify_ordered_items_count(:ancillary => 1).should be_true
      slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
      slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
      slmc.confirm_validation_all_items.should be_true
    end
    it "EMPLOYEE - Clinical Discharge" do
      slmc.go_to_general_units_page
      slmc.clinically_discharge_patient(:pin => @@employee, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
    end
    it "EMPLOYEE - Compute PhilHealth" do
      sleep 6
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@employee)
      slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
  #    @@ph2 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "SENILE CATARACT", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "66983", :compute => true)
      @@ph2 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "SENILE CATARACT", :medical_case_type => "INTENSIVE CASE", :with_operation => true, :rvu_code => "66982", :compute => true)
      slmc.ph_save_computation
    end
    it "EMPLOYEE - Manually Encode Discount (Courtesy Discount - Across the Board = 5000k)" do
      slmc.go_to_patient_billing_accounting_page
      @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@employee)
      slmc.go_to_page_using_visit_number("Discount", @@visit_no)
      slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :discount_rate => @@discount_rate2, :close_window => true, :save => true).should be_true
    end
    it "EMPLOYEE - Goes to Payment Page" do
      slmc.go_to_patient_billing_accounting_page
      slmc.pba_search(:with_discharge_notice => true, :pin => @@employee)
      slmc.go_to_page_using_visit_number("Payment", @@visit_no)
    end
    it "EMPLOYEE - Checks Order Types of ordered items" do
      @@order_type1 = 0
      @@order_type2 = 0
      @@order_type3 = 0
      @@order_type4 = 0
  
      @@orders =  @ancillary.merge(@drugs).merge(@supplies)
      @@orders.each do |order,n|
        item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
        if item[:order_type] == "ORT01"
          amt = item[:rate].to_f * n
          @@order_type1 += amt
        end
        if item[:order_type] == "ORT02"
          n_amt = item[:rate].to_f * n
          @@order_type2 += n_amt
        end
        if item[:order_type] == "ORT03"
          x_lab_amt = item[:rate].to_f * n
          @@order_type3 += x_lab_amt
        end
      end
    end
    it "EMPLOYEE - Computes Discount for Employee" do
      @@gross = 0.0
      @@orders = @drugs.merge(@ancillary).merge(@supplies)
      @@orders.each do |order,n|
        item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
        amt = item[:rate].to_f * n
        @@gross += amt  # total gross amount
      end
      @@gross = (@@gross * 100).round.to_f / 100
      @@discount = slmc.compute_discounts(:unit_price => @@gross, :promo => true)
      @@courtesy_discount = slmc.compute_courtesy_discount(:fixed => true, :amount => @@discount_rate2)
      @@total_discount = (@@discount + @@courtesy_discount)
      @@total_hospital_bills = @@gross - @@total_discount
      @@balance_due = @@gross - (slmc.truncate_to(@@discount,2) + slmc.truncate_to(@@courtesy_discount,2))
    end
    it "EMPLOYEE - Checks if Computation of Gross, Discount and Balance Due are correct" do
      @@summary = slmc.get_billing_details_from_payment_data_entry
  
      ((slmc.truncate_to((@@summary[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 0.02
      ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bills),2).to_f).abs).should <= 0.02
      ((slmc.truncate_to((@@summary[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
      ((slmc.truncate_to((@@summary[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 0.02
    end
    it "EMPLOYEE - PBA Discharge" do
      #@@employee = "1301028162"
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.pba_search(:with_discharge_notice => true, :pin => @@employee)
      slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
      slmc.select_discharge_patient_type(:type => "DAS").should be_true #HEEI1R1N is 100% coverage
    end
   it "EMPLOYEE - Discharged Patient should not be able to add discount" do
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      #@@visit_number = '5206000956'
      @@visit_number = slmc.pba_search(:discharged => true, :pin => @@employee)
  #    slmc.pba_get_select_options(@@visit_number).should == ["Defer Discharge", "Generation of SOA", "PhilHealth", "Print Discharge Clearance", "Payment"]
      slmc.pba_get_select_options(@@visit_number).should == ["Defer Discharge", "Generation of SOA", "PhilHealth", "Print Discharge Clearance", "Payment", "Endorsement Tagging", "View Endorsement History"]
    end
 ################################################################COMPANY###
#  it "COMPANY - Creates Patient" do
#    sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pba_pin1 = slmc.create_new_patient(@pba_patient1.merge!(:gender => "M"))
#    slmc.login(@user, @password).should be_true
#
#    slmc.admission_search(:pin => @@pba_pin1)
#  result =  slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS", :account_class => "COMPANY", :guarantor_code => "ABSC001")
#                 if result == "Patient admission details successfully saved." || "Unable to print patient wristband please check your printer."
#                        admission = true
#                else
#                        admission = false
#                end
#                admission.should == true    
#    
#  end
#  it "COMPANY - Orders items" do
#    slmc.login(@gu_user_0287, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pba_pin1)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pba_pin1)
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 1).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
#    slmc.validate_orders(:drugs => true, :supplies => true, :ancillary => true, :orders => "multiple").should == 3
#    slmc.confirm_validation_all_items.should be_true
#  end
#  it "COMPANY - Clinical Discharge" do
#    slmc.go_to_general_units_page
#    @@visit_no = slmc.clinically_discharge_patient(:pin => @@pba_pin1, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true
#  end
#  it "COMPANY - Update Patient Information, 100% Percentage for COMPANY class" do
#    sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin1)
#    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
#    slmc.click_guarantor_to_update
#    slmc.pba_update_guarantor(:guarantor_type => "COMPANY", :guarantor_code => "ANDC001", :loa_percent => "100")
#    slmc.click_submit_changes.should be_true
#  end
#  it "COMPANY - Compute PhilHealth" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin1)
#    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
#    @@ph3 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
#    slmc.ph_save_computation
#  end
#  it "COMPANY - Professional fee settlement" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.patient_pin_search(:pin => @@pba_pin1)
#    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
#    @pf_amount = slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f
#    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
#    puts @@pba_pin1
#  end
#  it "COMPANY - Manually Encode Discount (Contractual and Company Discount - Across the Board = 50% for Ancillary)" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin1)
#    slmc.go_to_page_using_visit_number("Discount", slmc.visit_number)
#    slmc.add_discount(:discount => "Contractual And Company Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Percentage", :discount_rate => @@discount_rate3).should be_true
#    slmc.exclude_item(:drugs => true, :supplies => true, :save => true).should be_true
#  end
#  it "COMPANY - Manually Encode Discount (Courtesy Discount - Across the Board = 1000 for Drugs)" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin1)
#    slmc.go_to_page_using_visit_number("Discount", slmc.visit_number)
#    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :discount_rate => @@discount_rate4).should be_true
#    slmc.exclude_item(:ancillary => true, :supplies => true, :save => true).should be_true
#  end
#  it "COMPANY - Goes to Payment Page" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin1)
#    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
#
#   puts @@pba_pin1
#
#  end
#  it "COMPANY - Checks Order Types of ordered items" do
#    @@order_type1 = 0
#    @@order_type2 = 0
#    @@order_type3 = 0
#
#    @@orders =  @ancillary.merge(@drugs).merge(@supplies)
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      if item[:order_type] == "ORT01"
#        amt = item[:rate].to_f * n
#        @@order_type1 += amt
#      end
#      if item[:order_type] == "ORT02"
#        n_amt = item[:rate].to_f * n
#        @@order_type2 += n_amt
#      end
#      if item[:order_type] == "ORT03"
#        x_lab_amt = item[:rate].to_f * n
#        @@order_type3 += x_lab_amt
#      end
#    end
#  end
#  it "COMPANY - Computes Discount for Employee Dependent" do
#    @@gross = 0.0
#    @@orders = @drugs.merge(@ancillary).merge(@supplies)
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@courtesy_discount1 = 0
#    @@courtesy_discount2 = 0
#    @@cd1 = 0
#    @@cd2 = 0
#    @@discount1 = 0
#    @@discount2 = 0
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@discount = slmc.compute_discounts(:unit_price => @@gross, :senior => true)
#
#    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :senior => true)
#    @@cd1 = @@order_type1 - @@discount1
#    @@courtesy_discount1 = slmc.compute_courtesy_discount(:percent => true, :net => @@cd1, :amount => @@discount_rate3)
#
#    @@discount2 = slmc.compute_discounts(:unit_price => @@order_type2, :senior => true)
#    @@cd2 = @@order_type2 - @@discount2
#    @@courtesy_discount2 = slmc.compute_courtesy_discount(:fixed => true, :amount => @@discount_rate4)
#
#    @@total_discount = ((@@discount + @@courtesy_discount1 + @@courtesy_discount2) * 100).round.to_f / 100
#
#
#
#    @@charged_amount = @@gross - @@total_discount
#  end
#  it "COMPANY - Checks if Computation of Gross, Discount and Balance Due are correct" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    puts "@@summary[:discounts].to_f == #{@@summary[:discounts].to_f}"
#    puts "@@total_discount == #{@@total_discount}"
#    ((slmc.truncate_to((@@summary[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:pf_amount].to_f - @@pf_fee),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:charged_amount].to_f - @@charged_amount),2).to_f).abs).should <= 0.02
#  end
#  it "COMPANY - PBA Discharge" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin1)
#    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_false
#    sleep 6
#    slmc.select_discharge_patient_type(:type => "DAS").should be_true
#  end
#  it "COMPANY - Discharged Patient should not be able to add discount" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_number = slmc.pba_search(:discharged => true, :pin => @@pba_pin1)
#    slmc.pba_get_select_options(@@visit_number).should == ["Defer Discharge", "Generation of SOA", "PhilHealth", "Print Discharge Clearance", "Payment", "Endorsement Tagging", "View Endorsement History"]
#    puts @@pba_pin1
#    puts @@visit_number
#  end
#  it "COMPANY - Generate SOA" do
#    slmc.go_to_patient_billing_accounting_page 
#    slmc.pba_search(:discharged => true, :pin => @@pba_pin1)
#    slmc.go_to_page_using_visit_number("Generation of SOA", slmc.visit_number)
#    slmc.click_generate_official_soa.should be_true
#  end
############################################################ BOARD MEMBER DEPENDENT
# it "BOARD MEMBER DEPENDENT - Creates Patient Account Class" do
#        sleep 6
#    slmc.login(@gu_user_0287, @password)
#    slmc.nursing_gu_search(:pin => @@board_member_dependent)
#    slmc.print_gatepass(:no_result => true, :pin => @@board_member_dependent)
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@board_member_dependent)
# #   if (slmc.get_text("//html/body/div/div[2]/div[2]/div[22]/table/tbody").gsub(' ', '').include?  @@board_member_dependent) && slmc.is_element_present("link=Admit Patient")
#    if (slmc.get_text("//html/body/div[1]/div[2]/div[2]/div[22]/table/tbody/tr/td[4]").gsub(' ', '').include?  @@board_member_dependent) && slmc.is_element_present("link=Admit Patient")
#
#     result = slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "BOARD MEMBER DEPENDENT", :guarantor_code => "BMAA001")
#                 if result == "Patient admission details successfully saved." || "Unable to print patient wristband please check your printer."
#                        admission = true
#                else
#                        admission = false
#                end
#                admission.should == true      
#    else
#
#      if slmc.is_text_present("NO PATIENT FOUND")
#        @@board_member_dependent = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "ANCHETA", :first_name => "BELLA", :middle_name => "CARIDAD", :birth_day => "09/25/1933", :gender => "F"))
#        @@board_member_dependent.should be_true
#        puts "@@board_member_dependent #{@@board_member_dependent}"
#
#      else
#        slmc.login(@gu_user_0287, @password).should be_true
#        if slmc.verify_gu_patient_status(@@board_member_dependent) != "Clinically Discharged"
#          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@board_member_dependent, :validate => true, :username => "sel_0287_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
#          slmc.go_to_general_units_page
#          slmc.clinically_discharge_patient(:pin => @@board_member_dependent, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#        end
#        slmc.login(@pba_user, @password).should be_true
#        slmc.go_to_patient_billing_accounting_page
#        slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member_dependent)
#        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#        slmc.discharge_patient_either_standard_or_das.should be_true
#        sleep 6
#       slmc.login(@gu_user_0287, @password).should be_true
#        slmc.nursing_gu_search(:pin => @@board_member_dependent)
#        slmc.print_gatepass(:no_result => true, :pin => @@board_member_dependent).should be_true
#      end
#       slmc.login(@user, @password).should be_true
#      slmc.admission_search(:pin => @@board_member_dependent)
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "BOARD MEMBER DEPENDENT", :guarantor_code => "BMAA001").should == "Patient admission details successfully saved."
#    end
#  end
#  it "BOARD MEMBER DEPENDENT - Orders items" do
#    slmc.login(@gu_user_0287, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@board_member_dependent)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@board_member_dependent)
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 1).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
#    slmc.confirm_validation_all_items.should be_true
#  end
#  it "BOARD MEMBER DEPENDENT - Manipulate Database : Makes Patient stayed for 1 day" do
#    @@visit_no = slmc.get_text("banner.visitNo")
#    @@room_and_bed = slmc.get_text("banner.roomBed").split('-')
#    @discount_type_code = "C02"
#    @discount_amount = (@@room_rate * 0.2)
#    @my_date1 = slmc.adjust_admission_date(:days_to_adjust => @@adjust_date, :pin => @@board_member_dependent, :visit_no => @@visit_no)
#    Database.connect
#    @@adjust_date.times do |i|
#      @rb1 = (slmc.get_last_record_of_rb_trans_no)
#     # @rb1 = @rb1.to_1
#      puts "@rb1  - #{@rb1 }"
#      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no,  :rb_trans_no => @rb1, :date_covered => @my_date1, :created_datetime => @my_date1, :room_rate => @@room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
#      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no, :rb_trans_no => @rb1, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date1)
#      @my_date1 = slmc.increase_date_by_one(@@adjust_date - i)
#    end
#    Database.logoff
#  end
#  it "BOARD MEMBER DEPENDENT - Clinical Discharge after 1 day" do
#    slmc.go_to_general_units_page
#    @@visit_no = slmc.clinically_discharge_patient(:pin => @@board_member_dependent, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true
#  end
#  it "BOARD MEMBER DEPENDENT - Compute PhilHealth " do
#    sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:pin => @@board_member_dependent, :with_discharge_notice => true)
#    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
#    @@ph4 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
#    slmc.ph_save_computation
#  end
#  it "BOARD MEMBER DEPENDENT - Change ADM_DATETIME and CREATED DATETIME in TXN_PBA_PH_HDR" do
#    slmc.adjust_adm_date_and_create_date_on_txn_pba_ph_hdr(:visit_no => @@visit_no, :days_to_adjust => @@adjust_date).should be_true
#  end
#  it "BOARD MEMBER DEPENDENT - Update Patient Information, Fixed 55000 for BOARD MEMBER DEPENDENT class" do
#    sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member_dependent)
#    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
#    slmc.click_guarantor_to_update
#    slmc.pba_update_guarantor(:guarantor_type => "BOARD MEMBER", :guarantor_code => "BMAA001", :loa_max => "55000")
#    slmc.click_submit_changes.should be_true
#  end
#  it "BOARD MEMBER DEPENDENT - Professional fee settlement" do
#        slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member_dependent)
#    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
#    @pf_amount = slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f
#    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
#  end
#  it "BOARD MEMBER DEPENDENT - Manually Encode Discount (Board Member - Across the Board = 5000 for Ancillary)" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member_dependent)
#    slmc.go_to_page_using_visit_number("Discount", slmc.visit_number)
#    slmc.add_discount(:discount => "Board Member", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :discount_rate => @@discount_rate5).should be_true
#    sleep 40
#    slmc.exclude_item(:drugs => true, :supplies => true, :room_and_board => true, :save => true).should be_true
#  end
#  it "BOARD MEMBER DEPENDENT - Goes to Payment Page" do
#        sleep 6
#     slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member_dependent)
#    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
#  end
#  it "BOARD MEMBER DEPENDENT - Checks Order Types of ordered items" do
#    @@order_type1 = 0
#    @@order_type2 = 0
#    @@order_type3 = 0
#
#    @@orders =  @ancillary.merge(@drugs).merge(@supplies)
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      if item[:order_type] == "ORT01"
#        amt = item[:rate].to_f * n
#        @@order_type1 += amt
#      end
#      if item[:order_type] == "ORT02"
#        n_amt = item[:rate].to_f * n
#        @@order_type2 += n_amt
#      end
#      if item[:order_type] == "ORT03"
#        x_lab_amt = item[:rate].to_f * n
#        @@order_type3 += x_lab_amt
#      end
#    end
#  end
#  it "BOARD MEMBER DEPENDENT - Computes Discount for Board Member Dependent" do
#    @@gross = 0.0
#    @@orders = @drugs.merge(@ancillary).merge(@supplies)
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@gross_and_room = @@gross + @@room_rate
#    @@discount = slmc.compute_discounts(:unit_price => @@gross_and_room, :senior => true)
#
#    # guarantor declared LOA is 55000
#
#    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :senior => true)
#    @@courtesy_discount1 = slmc.compute_courtesy_discount(:fixed => true, :amount => @@discount_rate5)
#
##   @@total_discount = ((@@discount) * 100).round.to_f / 100
#    @@total_discount = ((@@discount + @@courtesy_discount1) * 100).round.to_f / 100
#    @@total_hospital_bills = (((@@gross + @@room_rate) - @@total_discount - 55000) * 100).round.to_f / 100
#    @@charged_amount = 55000.0
#    @@balance_due = @@gross_and_room - @@total_discount - @@charged_amount
#  end
#  it "BOARD MEMBER DEPENDENT - Checks if Computation of Gross, Discount and Balance Due are correct" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    ((slmc.truncate_to((@@summary[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:pf_amount].to_f - @@pf_fee),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bills),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#  end
#  it "BOARD MEMBER DEPENDENT - PBA Discharge" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member_dependent)
#    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#    slmc.select_discharge_patient_type(:type => "DAS").should be_true
#  end   
#  it "BOARD MEMBER DEPENDENT - Discharged Patient should not be able to add discount" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_number = slmc.pba_search(:discharged => true, :pin => @@board_member_dependent)
#    slmc.pba_get_select_options(@@visit_number).should == ["Defer Discharge", "Generation of SOA", "PhilHealth", "Print Discharge Clearance", "Payment", "Endorsement Tagging", "View Endorsement History"]
#  end
#        ############################################################# ## BOARD MEMBER
#  it "BOARD MEMBER - Creates Patient" do
#    sleep 6
#    slmc.login(@gu_user_0287, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@board_member)
#    slmc.print_gatepass(:no_result => true, :pin => @@board_member)
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@board_member)
#    if (slmc.get_text("//html/body/div[1]/div[2]/div[2]/div[22]/table/tbody/tr/td[4]").gsub(' ', '').include?  @@board_member) && slmc.is_element_present("link=Admit Patient")
#
#      result = slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS", :account_class => "BOARD MEMBER", :guarantor_code => "BMAA001")
#     if result == "Patient admission details successfully saved." || "Unable to print patient wristband please check your printer."
#            admission = true
#    else
#            admission = false
#    end
#    admission.should == true      
#    else
#      if slmc.is_text_present("NO PATIENT FOUND")
#        @@board_member = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "ANCHETA", :first_name => "ALONZO", :middle_name => "Q", :birth_day => "10/30/1992", :gender => "M"))
#        @@board_member.should be_true
#        puts "@@board_member #{@@board_member}"
#      else
#        slmc.login(@gu_user_0287, @password).should be_true
#        if slmc.verify_gu_patient_status(@@board_member) != "Clinically Discharged"
#          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@board_member, :validate => true, :username => "sel_0287_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
#          slmc.go_to_general_units_page
#          slmc.clinically_discharge_patient(:pin => @@board_member, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#        end
#        slmc.login(@pba_user, @password).should be_true
#        slmc.go_to_patient_billing_accounting_page
#        slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member)
#        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#        slmc.discharge_patient_either_standard_or_das.should be_true
#
#        slmc.login(@gu_user_0287, @password).should be_true
#        slmc.nursing_gu_search(:pin => @@board_member)
#        slmc.print_gatepass(:no_result => true, :pin => @@board_member)
#      end
#      slmc.login(@user, @password).should be_true
#      slmc.admission_search(:pin => @@board_member)
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS", :account_class => "BOARD MEMBER", :guarantor_code => "BMAA001").should == "Patient admission details successfully saved."
#    end
#  end
#  it "BOARD MEMBER - Orders items" do
#    slmc.login(@gu_user_0287, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@board_member)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@board_member)
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
#    slmc.confirm_validation_all_items.should be_true
#  end
#  it "BOARD MEMBER - Manipulate Database : Makes Patient stayed for 1 day" do
#    @@visit_no = slmc.get_text("banner.visitNo")
#    @@room_and_bed = slmc.get_text("banner.roomBed").split('-')
#    @discount_type_code = "C01"
#    @discount_amount = (@@room_rate * 0.16)
#    @my_date2 = slmc.adjust_admission_date(:days_to_adjust => @@adjust_date, :pin => @@board_member, :visit_no => @@visit_no)
#    Database.connect
#    @@adjust_date.times do |i|
#      @rb2 = (slmc.get_last_record_of_rb_trans_no)
#      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no,  :rb_trans_no => @rb2, :date_covered => @my_date2, :created_datetime => @my_date2, :room_rate => @@room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
#       slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no, :rb_trans_no => @rb2, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date2)
#
#      @my_date2 = slmc.increase_date_by_one(@@adjust_date - i)
#    end
#    Database.logoff
#  end
#  it "BOARD MEMBER - Clinical Discharge after 1 day" do
#    slmc.go_to_general_units_page
#    @@visit_no = slmc.clinically_discharge_patient(:pin => @@board_member, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true
#  end
#  it "BOARD MEMBER - Compute PhilHealth" do
#    sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:pin => @@board_member, :with_discharge_notice => true)
#    sleep 3
#    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
#    @@ph5 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
#    slmc.ph_save_computation
#  end
#  it "BOARD MEMBER - Change ADM_DATETIME and CREATED DATETIME in TXN_PBA_PH_HDR" do
#    slmc.adjust_adm_date_and_create_date_on_txn_pba_ph_hdr(:visit_no => @@visit_no, :days_to_adjust => @@adjust_date).should be_true
#  end
#  it "BOARD MEMBER - Professional fee settlement" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member)
#    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
#    @pf_amount = slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f
#    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
#  end
#  it "BOARD MEMBER - Manually Encode Discount (Courtesy Discount - Across the Board = 50% for Ancillary)" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member)
#    slmc.go_to_page_using_visit_number("Discount", slmc.visit_number)
#    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Percent", :discount_rate => @@discount_rate3).should be_true
#    sleep 40
#    slmc.exclude_item(:drugs => true, :supplies => true, :room_and_board => true, :save => true).should be_true
#  end
#  it "BOARD MEMBER - Manually Encode Discount (Courtesy Discount - Across the Board = 10% for Drugs)" do
#      slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member)
#    slmc.go_to_page_using_visit_number("Discount", slmc.visit_number)
#    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Percent", :discount_rate => @@discount_rate6).should be_true
#        sleep 40
#    slmc.exclude_item(:ancillary => true, :supplies => true, :room_and_board => true, :save => true).should be_true
#  end
#  it "BOARD MEMBER - Goes to Payment Page" do
#    sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member)
#    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
#  end
#  it "BOARD MEMBER - Checks Order Types of ordered items" do
#    @@order_type1 = 0
#    @@order_type2 = 0
#    @@order_type3 = 0
#
#    @@orders =  @ancillary.merge(@drugs).merge(@supplies)
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      if item[:order_type] == "ORT01"
#        amt = item[:rate].to_f * n
#        @@order_type1 += amt
#      end
#      if item[:order_type] == "ORT02"
#        n_amt = item[:rate].to_f * n
#        @@order_type2 += n_amt
#      end
#      if item[:order_type] == "ORT03"
#        x_lab_amt = item[:rate].to_f * n
#        @@order_type3 += x_lab_amt
#      end
#    end
#  end
#  it "BOARD MEMBER - Computes Discount for Board Member Dependent" do
#    @@gross = 0.0
#    @@orders = @drugs.merge(@ancillary).merge(@supplies)
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@gross_and_room = @@gross + @@room_rate
#    @@board_member_discount = slmc.compute_discounts(:unit_price => @@gross_and_room, :promo => true)
#
#    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :promo => true)
#    @@cd1 = @@order_type1 - @@discount1
#    @@courtesy_discount1 = slmc.compute_courtesy_discount(:percent => true, :net => @@cd1, :amount => @@discount_rate3)
#
#    @@discount2 = slmc.compute_discounts(:unit_price => @@order_type2, :promo => true)
#    @@cd2 = @@order_type2 - @@discount2
#    @@courtesy_discount2 = slmc.compute_courtesy_discount(:percent => true, :net => @@cd2, :amount => @@discount_rate6)
#
#    #@@total_discount = ((@@board_member_discount) * 100).round.to_f / 100
#    @@total_discount = ((@@board_member_discount + @@courtesy_discount1 + @@courtesy_discount2) * 100).round.to_f / 100
#    @@total_hospital_bills = (((@@gross + @@room_rate) - @@total_discount) * 100).round.to_f / 100
#    @@balance_due = @@gross_and_room - @@total_discount
#  end
#  it "BOARD MEMBER - Checks if Computation of Gross, Discount and Balance Due are correct" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    ((slmc.truncate_to((@@summary[:room_charges].to_f - @@room_rate),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:pf_amount].to_f - @@pf_fee),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bills),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:balance_due].to_f - @@balance_due),2).to_f).abs).should <= 0.02
#  end
#  it "BOARD MEMBER - PBA Discharge" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member)
#    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#    slmc.select_discharge_patient_type(:type => "DAS").should be_true
#  end
#  it "BOARD MEMBER - Discharged Patient should not be able to add discount" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_number = slmc.pba_search(:discharged => true, :pin => @@board_member)
#    slmc.pba_get_select_options(@@visit_number).should == ["Defer Discharge", "Generation of SOA", "PhilHealth", "Print Discharge Clearance", "Payment", "Endorsement Tagging", "View Endorsement History"]
#  end
#  it "BOARD MEMBER - Generate SOA for Patient" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:discharged => true, :pin => @@board_member)
#    slmc.go_to_page_using_visit_number("Generation of SOA", slmc.visit_number)
#    slmc.click_generate_official_soa.should be_true
#  end
################################################################# Patient is Senior and Foreigner
#  it "SENIOR FOREIGNER - Creates Senior Citizen Patient and Foreigner" do
#    sleep 9
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pba_pin3 = slmc.create_new_patient(@pba_patient3.merge!(:citizenship => "AMERICAN"))
#     #   slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pba_pin3)
#    result = slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS", :account_class => "INDIVIDUAL")
#     if result == "Patient admission details successfully saved." || "Unable to print patient wristband please check your printer."
#            admission = true
#    else
#            admission = false
#    end
#    admission.should == true    
#  end
#  it "SENIOR FOREIGNER - Orders items" do
#     slmc.login(@gu_user_0287, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pba_pin3)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pba_pin3)
#    @drugs_mrp.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 1).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
#    slmc.confirm_validation_all_items.should be_true
#  end
#  it "SENIOR FOREIGNER - Manipulate Database : Makes Patient stayed for 1 day" do
#    @@visit_no = slmc.get_text("banner.visitNo")
#    @@room_and_bed = slmc.get_text("banner.roomBed").split('-')
#    @discount_type_code = "C02"
#    @discount_amount = (@@room_rate * 0.16)
#    @my_date3 = slmc.adjust_admission_date(:days_to_adjust => @@adjust_date, :pin => @@pba_pin3, :visit_no => @@visit_no)
#    Database.connect
#    @@adjust_date.times do |i|
#      @rb3 = (slmc.get_last_record_of_rb_trans_no)
#      slmc.insert_new_record_on_txn_pba_room_bed_trans(:visit_no => @@visit_no,  :rb_trans_no => @rb3, :date_covered => @my_date3, :created_datetime => @my_date3, :room_rate => @@room_rate, :nursing_unit => "0287", :room_charge => "RCH08", :room_no => @@room_and_bed[0], :bed_no => @@room_and_bed[1], :created_by => @user)
#      slmc.insert_new_record_on_txn_pba_disc_dtl(:visit_no => @@visit_no, :rb_trans_no => @rb3, :created_by => @user, :discount_type_code => @discount_type_code, :discount_amount => @discount_amount, :created_datetime => @my_date3)
#      @my_date3 = slmc.increase_date_by_one(@@adjust_date - i)
#    end
#    Database.logoff
#  end
#  it "SENIOR FOREIGNER - Clinical Discharge Patient after 1 day" do
#    slmc.go_to_general_units_page
#    slmc.clinically_discharge_patient(:pin => @@pba_pin3, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :save => true).should be_true
#  end
#  it "SENIOR FOREIGNER - Compute PhilHealth" do
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:pin => @@pba_pin3, :with_discharge_notice => true)
#    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
#    @@ph6 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
#    slmc.ph_save_computation
#  end
#  it "SENIOR FOREIGNER - Change ADM_DATETIME and CREATED DATETIME in TXN_PBA_PH_HDR" do
#    slmc.adjust_adm_date_and_create_date_on_txn_pba_ph_hdr(:visit_no => @@visit_no, :days_to_adjust => @@adjust_date).should be_true
#  end
#  it "SENIOR FOREIGNER - Professional fee settlement" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:pin => @@pba_pin3, :with_discharge_notice => true)
#    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
#    @pf_amount = slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f
#    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
#  end
#  it "SENIOR FOREIGNER - Goes to Payment Page" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin3)
#    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
#  end
#  it "SENIOR FOREIGNER - Checks Order Types of ordered items" do
#    @@order_type1 = 0
#    @@order_type2 = 0
#    @@order_type3 = 0
#    @@order_type_mrp = 0
#
#    @@orders = @ancillary.merge(@drugs_mrp).merge(@supplies)
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      if item[:order_type] == "ORT01"
#        amt = item[:rate].to_f * n
#        @@order_type1 += amt
#      end
#      if item[:order_type] == "ORT02" and item[:mrp_tag] == "Y"
#        mrp_amt = item[:rate].to_f * n
#        @@order_type_mrp += mrp_amt
#      end
#      if item[:order_type] == "ORT02" and item[:mrp_tag] == "N"
#        n_amt = item[:rate].to_f * n
#        @@order_type2 += n_amt
#      end
#      if item[:order_type] == "ORT03"
#        x_lab_amt = item[:rate].to_f * n
#        @@order_type3 += x_lab_amt
#      end
#    end
#  end
#  it "SENIOR FOREIGNER - Computes Discount for Senior Foreigner" do
#    @@gross = 0.0
#    @@orders = @drugs_mrp.merge(@ancillary).merge(@supplies)
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    # mrp items do not apply to foreigner
#    # working as of January 16, 2012
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @@room_rate
#    @@to_be_deducted = @@total_gross - @@order_type_mrp
#    @@discount = slmc.compute_discounts(:unit_price => @@to_be_deducted, :promo => true) #promo since 16% discount only for senior foreigner
#    @@total_discount = ((@@discount) * 100).round.to_f / 100
#    @@total_hospital_bills = @@to_be_deducted - @@total_discount + @@order_type_mrp  #promo since 16% discount only for senior foreigner
#  end
#  it "SENIOR FOREIGNER - Checks if Computation of Gross, Discount and Balance Due are correct" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    ((slmc.truncate_to((@@summary[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:pf_amount].to_f - @@pf_fee),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bills),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 0.02
#  end
#  it "SENIOR FOREIGNER - PBA Discharge" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin3)
#    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#    slmc.discharge_to_payment.should be_true
#  end
#  it "SENIOR FOREIGNER - Discharged Patient should not be able to add discount" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_number = slmc.pba_search(:discharged => true, :pin => @@pba_pin3)
#    slmc.pba_get_select_options(@@visit_number).should == ["Defer Discharge", "Generation of SOA", "PhilHealth", "Print Discharge Clearance", "Payment", "Endorsement Tagging", "View Endorsement History"]
#  end
#  it "SENIOR FOREIGNER - Generate SOA" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:discharged => true, :pin => @@pba_pin3)
#    slmc.go_to_page_using_visit_number("Generation of SOA", slmc.visit_number)
#    slmc.click_generate_official_soa.should be_true
#  end
#################################### Doctor Dependent
  it "DOCTOR DEPENDENT - Creates Patient" do
    sleep 6
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@doctor_dependent)
    slmc.print_gatepass(:no_result => true, :pin => @@doctor_dependent)
    slmc.login(@user, @password).should be_true

    slmc.admission_search(:pin => @@doctor_dependent)
    if (slmc.get_text("//html/body/div[1]/div[2]/div[2]/div[22]/table/tbody/tr/td[4]").gsub(' ', '').include?  @@doctor_dependent) && slmc.is_element_present("link=Admit Patient")
    result = slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "DOCTOR DEPENDENT", :guarantor_code => "3325")
     if result == "Patient admission details successfully saved." || "Unable to print patient wristband please check your printer."
            admission = true
    else
            admission = false
    end
    admission.should == true    
    else
      if slmc.is_text_present("NO PATIENT FOUND")
        @@doctor_dependent = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "CARINO", :first_name => "GRACE", :middle_name => "L", :birth_day => "12/17/1956", :gender => "F"))
        puts "@@doctor_dependent  - #{@@doctor_dependent }"
      else
        slmc.login(@gu_user_0287, @password).should be_true
        if slmc.verify_gu_patient_status(@@doctor_dependent) != "Clinically Discharged"
          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@doctor_dependent, :validate => true, :username => "sel_0287_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
          slmc.go_to_general_units_page
          slmc.clinically_discharge_patient(:pin => @@doctor_dependent, :pf_amount => "1000", :no_pending_order => true, :save => true)
        end
        sleep 6
        slmc.login(@pba_user, @password).should be_true
        slmc.go_to_patient_billing_accounting_page
        slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
        slmc.discharge_patient_either_standard_or_das.should be_true

       slmc.login(@gu_user_0287, @password).should be_true
        slmc.nursing_gu_search(:pin => @@doctor_dependent)
        slmc.print_gatepass(:no_result => true, :pin => @@doctor_dependent).should be_true
      end
      slmc.login(@user, @password).should be_true
      slmc.admission_search(:pin => @@doctor_dependent)
      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "DOCTOR DEPENDENT", :guarantor_code => "3325").should == "Patient admission details successfully saved."
    end
  end
  it "DOCTOR DEPENDENT - Orders items" do
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@doctor_dependent)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@doctor_dependent)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
    end
    @supplies.each do |supply, q|
      slmc.search_order(:description => supply, :supplies => true ).should be_true
      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end
  it "DOCTOR DEPENDENT - Clinical Discharge" do
    slmc.go_to_general_units_page
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@doctor_dependent, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true
  end
  it "DOCTOR DEPENDENT - Compute PhilHealth" do
    sleep 6
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:pin => @@doctor_dependent, :with_discharge_notice => true)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    @@ph7 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
  end
  it "DOCTOR DEPENDENT - Professional fee settlement" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:pin => @@doctor_dependent, :with_discharge_notice => true)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
    @pf_amount = slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f
    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
  end
  it "DOCTOR DEPENDENT - Update Patient Information, for DOCTOR DEPENDENT class" do
    sleep 10
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
    slmc.go_to_page_using_visit_number("Update Patient Information", @@visit_no)
    slmc.click_guarantor_to_update
    slmc.pba_update_guarantor(:guarantor_type => "DOCTOR", :guarantor_code => "3325")
    slmc.click_submit_changes.should be_true
  end
  it "DOCTOR DEPENDENT - Manually Encode Discount (Courtesy Discount - Across the Board = 5k)" do
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
    slmc.go_to_page_using_visit_number("Discount", slmc.visit_number)
    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :discount_rate => @@discount_rate1, :close_window => true, :save => true).should be_true
  end
  it "DOCTOR DEPENDENT - Goes to Payment Page" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
  end
  it "DOCTOR DEPENDENT - Checks Order Types of ordered items" do
    @@order_type1 = 0
    @@order_type2 = 0
    @@order_type3 = 0
    @@order_type_mrp = 0

    @@orders =  @ancillary.merge(@drugs).merge(@supplies)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      if item[:order_type] == "ORT01"
        amt = item[:rate].to_f * n
        @@order_type1 += amt
      end
      if item[:order_type] == "ORT02" and item[:mrp_tag] == "Y"
        mrp_amt = item[:rate].to_f * n
        @@order_type_mrp += mrp_amt
      end
      if item[:order_type] == "ORT02"
        n_amt = item[:rate].to_f * n
        @@order_type2 += n_amt
      end
      if item[:order_type] == "ORT03"
        x_lab_amt = item[:rate].to_f * n
        @@order_type3 += x_lab_amt
      end
    end
  end
  it "DOCTOR DEPENDENT - Computes Discount for Doctor Dependent" do
    @@gross = 0.0
    @@orders = @drugs.merge(@ancillary).merge(@supplies)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end

    @@gross = (@@gross * 100).round.to_f / 100
    @@discount = slmc.compute_discounts(:unit_price => @@gross, :promo =>  true)

    @@total_discount = ((@@discount + @@discount_rate1) * 100).round.to_f / 100
    @@total_hospital_bills = @@gross - @@total_discount
  end
  it "DOCTOR DEPENDENT - Checks if Computation of Gross, Discount and Balance Due are correct" do
    @@summary = slmc.get_billing_details_from_payment_data_entry

    ((slmc.truncate_to((@@summary[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:pf_amount].to_f - @@pf_fee),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bills),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 0.02
  end
  it "DOCTOR DEPENDENT - PBA Discharge" do
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
  end
  it "DOCTOR DEPENDENT - Discharged Patient should not be able to add discount" do
    slmc.go_to_patient_billing_accounting_page
    @@visit_number = slmc.pba_search(:discharged => true, :pin => @@doctor_dependent)
    slmc.pba_get_select_options(@@visit_number).should == ["Defer Discharge", "Generation of SOA", "PhilHealth", "Print Discharge Clearance", "Payment", "Endorsement Tagging", "View Endorsement History"]
  end
  it "DOCTOR DEPENDENT - Generate SOA" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@doctor_dependent)
    slmc.go_to_page_using_visit_number("Generation of SOA", slmc.visit_number)
    slmc.click_generate_official_soa.should be_true
  end
############################### DOCTOR
#  it "DOCTOR - Creates Patient" do
#    sleep 6
#    slmc.login(@gu_user_0287, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@doctor)
#    slmc.print_gatepass(:no_result => true, :pin => @@doctor)
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@doctor)
#    if (slmc.get_text("//html/body/div[1]/div[2]/div[2]/div[22]/table/tbody/tr/td[4]").gsub(' ', '').include?  @@doctor) && slmc.is_element_present("link=Admit Patient")
#      result = slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :diagnosis => "GASTRITIS", :account_class => "DOCTOR", :guarantor_code => "6055")
#       if result == "Patient admission details successfully saved." || "Unable to print patient wristband please check your printer."
#              admission = true
#      else
#              admission = false
#      end
#      admission.should == true      
#    else
#      if slmc.is_text_present("NO PATIENT FOUND")
#        @@doctor = slmc.create_new_patient(@pba_patient5.merge!(:last_name => "CARLOS", :first_name => "MARIE ARLENE", :middle_name => "DUMANDAN", :birth_day => "06/27/1973", :gender => "F"))
#        @@doctor.should be_true
#        puts "@@doctor #{@@doctor}"
#      else
#        slmc.login(@gu_user_0287, @password).should be_true
#        if slmc.verify_gu_patient_status(@@doctor) != "Clinically Discharged"
#          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@doctor, :validate => true, :username => "sel_0287_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
#          slmc.go_to_general_units_page
#          slmc.clinically_discharge_patient(:pin => @@doctor, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#        end
#        slmc.login(@pba_user, @password).should be_true
#        slmc.go_to_patient_billing_accounting_page
#        slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor)
#        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#        slmc.discharge_patient_either_standard_or_das.should be_true
#
#        slmc.login(@gu_user_0287, @password).should be_true
#        slmc.nursing_gu_search(:pin => @@doctor)
#        slmc.print_gatepass(:no_result => true, :pin => @@doctor).should be_true
#      end
#        slmc.login(@user, @password).should be_true
#      slmc.admission_search(:pin => @@doctor)
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS", :account_class => "DOCTOR", :guarantor_code => "6055").should == "Patient admission details successfully saved."
#    end
#  end
#  it "DOCTOR - Orders items" do
#        slmc.login(@gu_user_0287, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@doctor)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@doctor)
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true)
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true )
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true )
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 1).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator").should be_true
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
#    slmc.confirm_validation_all_items.should be_true
#  end
#  it "DOCTOR - Orders Procedures" do
#    sleep 6
#    slmc.login(@or_user, @password).should be_true
#    slmc.go_to_occupancy_list_page
#    slmc.patient_pin_search(:pin => @@doctor)
#    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@doctor)
#    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
#    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
#    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "5979")
#    slmc.validate_orders(:orders => "multiple", :procedures => true).should == 1
#    slmc.confirm_validation_all_items.should be_true
#  end
#  it "DOCTOR - Clinical Discharge" do
#    sleep 6
#    slmc.login(@gu_user_0287, @password).should be_true
#    slmc.go_to_general_units_page
#    @@visit_no = slmc.clinically_discharge_patient(:pin => @@doctor, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true
#  end
#  it "DOCTOR - Compute PhilHealth" do
#    sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:pin => @@doctor, :with_discharge_notice => true)
#    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
#    @@ph8 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
#    slmc.ph_save_computation
#  end
#  it "DOCTOR - Professional fee settlement" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:pin => @@doctor, :with_discharge_notice => true)
#    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
#    @pf_amount = slmc.get_text('//*[@id="pfAmount"]').split(".")[0].gsub(",", "").split(".")[0].to_f
#    slmc.pba_pf_payment(:pf_amount => @pf_amount).should be_true
#  end
#  it "DOCTOR - Update Patient Information, for DOCTOR class" do
#    sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor)
#    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
#    slmc.click_guarantor_to_update
#    slmc.pba_update_guarantor(:guarantor_type => "DOCTOR", :guarantor_code => "6055")
#    slmc.click_submit_changes.should be_true
#  end
#  it "DOCTOR - Goes to Payment Page" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor)
#    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
#  end
#  it "DOCTOR - Checks Order Types of ordered items" do
#    @@order_type1 = 0
#    @@order_type2 = 0
#    @@order_type3 = 0
#    @@order_type_mrp = 0
#    @@operation = 0
#
#    @@orders =  @ancillary.merge(@drugs).merge(@supplies).merge(@operation)
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      if item[:order_type] == "ORT01"
#        amt = item[:rate].to_f * n
#        @@order_type1 += amt
#      end
#      if item[:order_type] == "ORT02" and item[:mrp_tag] == "Y"
#        mrp_amt = item[:rate].to_f * n
#        @@order_type_mrp += mrp_amt
#      end
#      if item[:order_type] == "ORT02"
#        n_amt = item[:rate].to_f * n
#        @@order_type2 += n_amt
#      end
#      if item[:order_type] == "ORT03"
#        x_lab_amt = item[:rate].to_f * n
#        @@order_type3 += x_lab_amt
#      end
#      if item[:ph_code] == "PHS03"
#        n_op = item[:rate].to_f * n
#        @@operation += n_op
#      end
#    end
#  end
#  it "DOCTOR - Computes Discount for Doctor" do
#    @@gross = 0.0
#    @@orders = @drugs.merge(@ancillary).merge(@supplies).merge(@operation)
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@discount = slmc.compute_discounts(:unit_price => @@gross, :promo =>  true)
#
#    @@total_discount = ((@@discount) * 100).round.to_f / 100
#    @@total_hospital_bills = @@gross - @@total_discount
#  end
#  it "DOCTOR - Checks if Computation of Gross, Discount and Balance Due are correct" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    ((slmc.truncate_to((@@summary[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:pf_amount].to_f - @@pf_fee),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bills),2).to_f).abs).should <= 0.02
#    ((slmc.truncate_to((@@summary[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 0.02
#  end
#  it "DOCTOR - PBA Discharge" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor)
#    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#    slmc.discharge_to_payment.should be_true
#  end
#  it "DOCTOR - Discharged Patient should not be able to add discount" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_number = slmc.pba_search(:discharged => true, :pin => @@doctor)
#    slmc.pba_get_select_options(@@visit_number).should == ["Defer Discharge", "Generation of SOA", "PhilHealth", "Print Discharge Clearance", "Payment", "Endorsement Tagging", "View Endorsement History"]
#  end
#  it "DOCTOR - Generate SOA" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:discharged => true, :pin => @@doctor)
#    slmc.go_to_page_using_visit_number("Generation of SOA", slmc.visit_number)
#    slmc.click_generate_official_soa.should be_true
#  end
end