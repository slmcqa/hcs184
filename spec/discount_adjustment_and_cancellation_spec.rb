#require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'

require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Discount - Adjustment and Cancellation Module" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    @pba_patient1 = Admission.generate_data
    @pba_patient2 = Admission.generate_data(:not_senior => true)
    @pba_patient3 = Admission.generate_data

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
         #@@doctor_dependent =  "1504081732"  #"1501078813" #conflict with discount outpatient spec            
    else
            @user = "fcdeleon"  #"billing_spec_user3"  #admission_login#
            @pba_user = "dmgcaubang" #"sel_pba7"
            @or_user =  "amlompad"     #"or21"
            @oss_user = "kjcgangano-pet"  #"sel_oss7"
            @dr_user = "aealmonte" #"sel_dr4"
            @er_user =  "asbaltazar"   #"sel_er4"
            @wellness_user = "emllacson-wellness" # "sel_wellness2"
            @gu_user_0287 = "ajpsolomon"
          @@doctor_dependent =  "1504081732"            
    end
 @@doctor_dependent =  "1504081732"            
    
@password = "123qweuser"

    #@@doctor_dependent = "1301028135" #"1112100138"




    @drugs = {"040000357" => 1}
    @drugs_mrp = {"040950576" => 1}
    @ancillary = {"010000003" => 1}
    @supplies = {"080100021" => 1}

    @o1 = {"ORT01" => 1}
    @o2 = {"ORT02" => 1}
    @o3 = {"ORT03" => 1}
    @o7 = {"ORT07" => 1}

    @@discount_rate1 = 5000.0
    @@discount_rate2 = 50
    @@discount_rate3 = 10000.0
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

#  it "Patient1 - Creates and Admit Patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pba_pin1 = slmc.create_new_patient(@pba_patient1.merge!(:gender => "M"))
#    puts @@pba_pin1
#    #slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pba_pin1)
#    slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0287', :diagnosis => "GASTRITIS", :account_class => "INDIVIDUAL").should == "Patient admission details successfully saved."
#  end
#  it "Patient1 - Orders items" do
#     slmc.login(@gu_user_0287, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pba_pin1)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pba_pin1)
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 1).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
#    slmc.confirm_validation_all_items.should be_true
#  end
#  it "Patient1 - Clinical Discharge" do
#    slmc.go_to_general_units_page
#    slmc.clinically_discharge_patient(:pin => @@pba_pin1, :no_pending_order => true, :pf_type => "COLLECT", :pf_amount => "1000", :type => "standard", :save => true).should be_true
#  end
#  it "Patient1 - Manually Encode Discount (Contractual and Company Discount - Across the Board = 5k for Ancillary)" do
#    sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin1)
#    slmc.go_to_page_using_visit_number("Discount", slmc.visit_number)
#    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :discount_rate => @@discount_rate1).should be_true
#    slmc.exclude_item(:drugs => true, :supplies => true, :save => true).should be_true
#  end
#  it "Patient1 - Cancel Manual Discount - Automatic Discount should remain" do
#    slmc.pba_adjustment_and_cancellation(:doc_type => "DISCOUNT", :search_option => "VISIT NUMBER", :entry => @@visit_no)
#    count = slmc.get_css_count("css=#processedDiscountsBody>tr") 
#    @@discount_number1 = (slmc.get_discount_number_using_visit_number(:visit_no => @@visit_no, :discount_rate => @@discount_rate1)).gsub(' ', '')
#    slmc.click_display_details(:visit_no => @@visit_no, :discount_no => @@discount_number1, :inpatient => true)
#    slmc.cancel_discount.should be_true
#    slmc.pba_adjustment_and_cancellation(:doc_type => "DISCOUNT", :search_option => "VISIT NUMBER", :entry => @@visit_no)
#    count -= 1
#    count.should == slmc.get_css_count("css=#processedDiscountsBody>tr")
#  end
#  it "Patient2 - Creates and Admit Patient" do
#    sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pba_pin2 = slmc.create_new_patient(@pba_patient2.merge!(:gender => "M"))
#    puts @@pba_pin2
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pba_pin2)
#    slmc.create_new_admission(:rch_code => 'RCH07', :org_code => '0287', :diagnosis => "GASTRITIS", :account_class => "INDIVIDUAL").should == "Patient admission details successfully saved."
#  end
#  it "Patient2 - Orders items" do
#    slmc.login(@gu_user_0287, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pba_pin2)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pba_pin2)
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 1).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
#    slmc.confirm_validation_all_items.should be_true
#  end
#  it "Patient2 - DAS search by date" do
#
#    slmc.login(@oss_user, @password).should be_true
#    @@visit_no = slmc.get_visit_number_using_pin(@@pba_pin2)
#    slmc.go_to_order_adjustment_and_cancellation
#    slmc.ci_search(:request_unit => "0287")
#   # slmc.ci_search(:request_unit => "0278")
#sleep 6
#puts "@@visit_no - #{@@visit_no}"
#    @data1 = slmc.get_ord_grp_no_and_ci_no(@@visit_no, "0036") #0036 for oss1 user performing unit
#    puts @data1
#    
#    count = slmc.get_css_count("//html/body/div[1]/div[2]/div[2]/div[9]/div[2]/table/tbody/tr")
#      puts "body count= #{count}"
#      
#    slmc.oss_click_cancel_order(:ci_no => @data1[1]).should be_true
#    slmc.oss_click_proceed_cancel.should == "The CM was successfully updated with printTag = 'Y'." #cancels ADRENOMEDULLARY IMAGING-M-IBG item SR010000003
#  end
#  it "Patient2 - Clinical Discharge patient in general units" do
#        sleep 6
#    slmc.login(@gu_user_0287, @password).should be_true
#    slmc.go_to_general_units_page
#    sleep 3
#    slmc.clinically_discharge_patient(:pin => @@pba_pin2, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
#  end
#  it "Patient2 - Add Doctors Discount" do
#     sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin2)
#    slmc.go_to_page_using_visit_number("Discount", @@visit_no)
#    slmc.add_discount(:discount => "Doctor Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Percent", :discount_rate => 50).should be_true
#    slmc.exclude_item(:supplies => true, :save => true).should be_true
#  end
#  it "Patient2 - Goes to Payment Page" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin2)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no)
#  end
#  it "Patient2 - Checks Order Types of ordered items, Checks Discount Percentage of items" do
#    @@order_type1 = 0
#    @@order_type2 = 0
#    @@order_type3 = 0
#    @@order_type4 = 0
#
#    #@@orders =  @ancillary.merge(@drugs).merge(@supplies)
#    @@orders =  (@drugs).merge(@supplies)
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
#
#    @@discount_percentage01 = 0
#    @@discount_percentage02 = 0
#    @@discount_percentage03 = 0
#
#    @@orders =  @o1.merge(@o2).merge(@o3)
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_discount_covered(order)
#      if item[:order_type] == "ORT01"
#        amt = item[:discount_percentage].to_f * n
#        @@discount_percentage01 += amt
#      end
#      if item[:order_type] == "ORT02" and (item[:therapeutic_med_flag] == "Y" or item[:service_category] == "Y")
#        n_amt = item[:discount_percentage].to_f * n
#        @@discount_percentage02 += n_amt
#      end
#      if item[:order_type] == "ORT03"
#        x_lab_amt = item[:discount_percentage].to_f * n
#        @@discount_percentage03 += x_lab_amt
#      end
#    end
#  end
#  it "Patient2 - Computes Discount" do
#    #@@ort01 = @@order_type1 * @@discount_percentage01
#    @@ort02 = @@order_type2 * @@discount_percentage02
#    @@ort03 = @@order_type3 * @@discount_percentage03
#
#    @@gross = 0.0
#    @@orders = (@drugs).merge(@supplies) #ancillary not included since it was cancelled
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#    @@gross = (@@gross * 100).round.to_f / 100
#
#    @@discount1 = slmc.compute_discounts(:unit_price => @@gross, :promo => true)
#    @@discount2 = slmc.compute_discounts(:unit_price => @@order_type2, :promo => true)
#    @@cd1 = @@order_type2 - @@discount2 #net amount for ordertype 2
#    @@courtesy_discount1 = slmc.compute_courtesy_discount(:percent => true, :net => @@cd1, :amount => @@discount_rate2)
#
#    @@total_discount = ((@@courtesy_discount1 + @@discount1) * 100).round.to_f / 100
#    @@total_hospital_bills = @@gross - @@total_discount
#  end
#  it "Patient2 - Checks if Computation of Gross and Discount are correct" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#   # @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    (@@summary[:hospital_bill].to_f - ("%0.2f" %(@@gross)).to_f).should <= 0.03
#
#    (@@summary[:discounts].to_f - ("%0.2f" %(@@total_discount)).to_f).should  <= 0.03
#
#    (@@summary[:total_hospital_bills].to_f - ("%0.2f" %(@@total_hospital_bills)).to_f).should  <= 0.03
#
#  end
#  it "Patient2 - PBA Discharge patient" do
#    slmc.go_to_patient_billing_accounting_page
#    @@visit_no2 = slmc.pba_search(:with_discharge_notice => true, :pin => @@pba_pin2)
#    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no2)
#    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#    slmc.discharge_to_payment.should be_true
#  end
#  it "Patient2 - Generate SOA" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:discharged => true, :pin => @@pba_pin2)
#    slmc.go_to_page_using_visit_number("Generation of SOA", @@visit_no2)
#    slmc.click_generate_official_soa.should be_true
#  end
  it "Patient3 - Creates Patient - Doctor Dependent" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_outpatient_nursing_page
    slmc.patient_pin_search(:pin => @@doctor_dependent)
    if (slmc.get_text("results").gsub(' ', '').include? @@doctor_dependent) && slmc.is_element_present("link=Register Patient")
    elsif (slmc.get_text("results").gsub(' ', '').include? @@doctor_dependent) && slmc.is_element_present("link=Notice of Death")
              slmc.go_to_occupancy_list_page
              slmc.patient_pin_search(:pin => @@doctor_dependent)
              slmc.click"//input[@type='button' and @name='physout']"
              slmc.login(@or_user,  @password).should be_true
    elsif (slmc.get_text("results").gsub(' ', '').include? @@doctor_dependent) && slmc.is_element_present("link=Cancel Registration")
              slmc.go_to_occupancy_list_page
              slmc.validate_incomplete_orders(:outpatient => true, :pin => @@doctor_dependent, :validate => true, :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
              slmc.go_to_occupancy_list_page
              slmc.clinically_discharge_patient(:outpatient => true, :pin => @@doctor_dependent, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
    elsif slmc.verify_su_patient_status(@@doctor_dependent) != "Clinically Discharged"
              slmc.click("physout", :wait_for => :page) if slmc.is_element_present("physout")
    else
              slmc.login(@pba_user, @password).should be_true
              slmc.go_to_patient_billing_accounting_page
              @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
              slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
              slmc.discharge_patient_either_standard_or_das.should be_true
              slmc.login(@or_user, @password).should be_true
              slmc.or_print_gatepass(:pin => @@doctor_dependent, :visit_no => @@visit_no)
    end
    #slmc.or_register_patient(:pin => @@doctor_dependent, :org_code => "0164", :account_class => "DOCTOR DEPENDENT", :guarantor_code => "7071")
    slmc.or_register_patient(:pin => @@doctor_dependent, :org_code => "0164", :account_class => "DOCTOR DEPENDENT", :guarantor_code => "3325")

  end
  it "Patient3 - Orders items" do
    slmc.login(@or_user, @password).should be_true
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@doctor_dependent)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@doctor_dependent)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
    end
    @supplies.each do |supply, q|
      slmc.search_order(:description => supply, :supplies => true).should be_true
      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 1).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.er_submit_added_order(:validate => true)
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 3
    slmc.confirm_validation_all_items.should be_true
  end
  it "Patient3 - Orders Procedure" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@doctor_dependent)
    slmc.go_to_su_page_for_a_given_pin("Checklist Order", @@doctor_dependent)
    @@item_code = slmc.search_service(:procedure => true, :description => "GASTRIC SURGERY")
    slmc.add_returned_service(:item_code => @@item_code, :description => "GASTRIC SURGERY")
    slmc.confirm_order(:anaesth_code => "0126", :surgeon_code => "6726")
    slmc.validate_orders(:procedures => true, :orders => "multiple").should == 1
    slmc.confirm_validation_all_items.should be_true
  end
  it "Patient3 - Clinical Discharge" do
    slmc.go_to_occupancy_list_page
    @@visit_no = slmc.clinically_discharge_patient(:outpatient => true, :pin => @@doctor_dependent, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
  end
  it "Patient3 - Compute and Save PhilHealth" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@doctor_dependent)
    slmc.click_philhealth_link(:pin => @@doctor_dependent, :visit_no => @@visit_no)
    slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :compute => true, :rvu_code => "11446")
    slmc.ph_save_computation.should be_true
  end
  it "Patient3 - Add Discount" do
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
    slmc.go_to_page_using_visit_number("Discount", @@visit_no)
    slmc.add_discount(:discount => "Doctor Dependent Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :discount_rate => @@discount_rate3).should be_true
    slmc.exclude_item(:drugs => true, :supplies => true, :save => true).should be_true
    puts "@@doctor_dependent - #{@@doctor_dependent}"
  end
  it "Patient3 - Cancels Ancillary ordered item" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true)
    slmc.discharge_to_payment.should be_true
  end
  it "Patient3 - Search for the Discount" do
    slmc.pba_adjustment_and_cancellation(:doc_type => "DISCOUNT", :search_option => "VISIT NUMBER", :entry => @@visit_no)
    count = slmc.get_css_count("css=#processedDiscountsBody>tr")
    count.times do |n|
      j = slmc.get_text("css=#processedDiscountsBody>tr:nth-child(#{n + 1})>td:nth-child(6)").gsub(",","").to_f
      if j == @@discount_rate3
        @my_row = n
      else
        n += 1
      end
    end
    @@discount_number2 = slmc.get_text("css=#processedDiscountsBody>tr:nth-child(#{@my_row + 1})>td:nth-child(1)")
    #@@discount_number2 = (slmc.get_discount_number_using_visit_number(:visit_no => @@visit_no, :discount_rate => @@discount_rate3)).gsub(' ', '')
    slmc.click_display_details(:visit_no => @@visit_no, :discount_no => @@discount_number2, :outpatient => true)
    slmc.click("adjustBtn", :wait_for => :page)
  end
  it "Patient3 - Print Gate Pass" do
    slmc.login(@or_user, @password).should be_true
    slmc.or_print_gatepass(:pin => @@doctor_dependent, :visit_no => @@visit_no).should be_true
  end
  it "Patient4 - Create Order in pharmacy and add Guarantor" do

    slmc.login(@pharmacy_user, @password).should be_true
    slmc.go_to_pos_ordering
    slmc.oss_add_guarantor(:acct_class => "HMO", :guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :coverage_choice => "max_amount", :coverage_amount => "35000", :guarantor_add => true).should be_true
  end
  it "Patient4 - Order items (1 special and 3 additional orders)" do
    slmc.oss_order(:item_code => "9999", :service_rate => 5000, :order_add => true, :special => true).should be_true
    slmc.oss_order(:item_code => "040004334", :order_add => true).should be_true
    slmc.oss_order(:item_code => "CAPSICUM SACHET 10", :order_add => true).should be_true
    slmc.oss_order(:item_code => "040004337", :order_add => true).should be_true
  end
  it "Patient4 - Add Discount" do
    slmc.oss_add_discount(:type => "percent", :scope => "dept", :amount => 10)
  end
  it "Patient4 - Complete Payment" do
    @amount = slmc.get_db_net_amount.to_s + '0'
    @amount = slmc.get_total_amount_due
    puts "@amount - #{@amount}"
    if @amount.to_f != 0.00
        slmc.oss_add_payment(:type => "CASH", :amount => @amount.to_s)
    end
    slmc.submit_order.should be_true
end
end