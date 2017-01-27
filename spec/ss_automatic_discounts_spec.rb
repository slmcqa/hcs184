require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
#require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'


describe "SLMC :: Social Service - Automatic Discounts" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    @user = "billing_spec_user2"
    @password = "123qweuser"
    @pba_user = "ldcastro" #"sel_pba7"
    @esc_no = "121024AG0012" #0000462Scenario 1 - Medical Case 30% : Compute and Save PhilHealth
    @patient_share = 5000.0
    @fund_share = 1234.56
    @room_rate = 4167.0

    @drugs = {"040000357" => 1, "040004334" => 1}  
    @ancillary = {"010000003" => 1}
    @supplies = {"080100021" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

########  # Social Service - Standard - Discharge - w/ Adjustment - w/ PhilHealth Final

  it "Social Service : Scenario 1 - Create and Admit Patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin = slmc.create_new_patient(Admission.generate_data(:not_senior => true))
    #slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
   puts @@pin

  end

  it "Social Service : Scenario 1 - Order items" do
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
    @drugs.each do |drug, q|
      slmc.search_order(:description => drug, :drugs => true).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
    end
    @supplies.each do |supply, q|
      slmc.search_order(:description => supply, :supplies => true ).should be_true
      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
    end
    sleep 5
    slmc.verify_ordered_items_count(:drugs => 2).should be_true
    slmc.verify_ordered_items_count(:supplies => 1).should be_true
    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
    slmc.confirm_validation_all_items.should be_true
    @@visit_no = slmc.get_text("banner.visitNo").gsub(' ','')
		puts "@@pin - #{@@pin}"
  end

  it "Social Service : Scenario 1 - Cancel ancillary in Order Adjustment" do
    #  @@visit_no=  "5608000293"
    slmc.login("sel_pharmacy1", @password).should be_true
    slmc.go_to_order_adjustment_and_cancellation
    slmc.ci_search(:request_unit => "0287")
    @data1 = slmc.get_ord_grp_no_and_ci_no(@@visit_no, "0004") #0004 for pharmacy user performing unit
    puts @data1
    slmc.oss_click_adjust_order(:ci_no => @data1[1]).should be_true
    slmc.oss_select_specific_order_adjustment(:item_code => "040004334", :cancel => true).should be_true
  end
#
#  it "Social Service : Scenario 1 - Clinically Discharge patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.go_to_general_units_page
#    slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Social Service : Scenario 1 - Compute and Save PhilHealth" do
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
#    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
#    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "10060", :medical_case_type => "CATASTROPHIC CASE", :compute => true)
#    slmc.ph_save_computation
#  end
#
#  it "Social Service : Scenario 1 - Add Patient Share, Fund Share" do
#    slmc.login("sel_ss1", @password).should be_true
#    slmc.go_to_social_services_landing_page
#    slmc.pba_search(:pin => @@pin)
#    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
#    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share)
#    puts @@pin
#  end
#
#  it "Social Service : Scenario 1 - Go to PhilHealth during Discharge" do
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
#    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
#    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#    slmc.skip_update_patient_information
#    slmc.skip_room_and_bed_cancelation
#    @@ph1 = slmc.philhealth_computation(:edit => true, :claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "10060", :medical_case_type => "CATASTROPHIC CASE", :compute => true)
#    slmc.ph_save_computation
##   #slmc.get_text("css=div.clearfix>h2").should == "FINAL"
#      slmc.is_text_present("FINAL").should be_true
#  end
#
#  it "Social Service : Scenario 1 - Go to Payment Page" do
#    slmc.skip_philhealth.should be_true
#    slmc.skip_discount.should be_true
#    slmc.skip_generation_of_soa.should be_true
#  end
#
#  it "Social Service : Scenario 1 - Checks Payment Details" do
#    @drugs = {"040000357" => 1}
#    @ancillary = {"010000003" => 1}
#    @supplies = {"080100021" => 1}
#
#    @@orders = (@drugs).merge(@ancillary).merge(@supplies)
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @room_rate
#    @@social_service_coverage = @fund_share
#    @@discount = slmc.compute_discounts(:unit_price => @@total_gross, :promo => true)
#    @@total_discount = @@total_gross - @@ph1[:total_actual_benefit_claim].to_i - @@social_service_coverage - @patient_share
#    @@balance_due = @patient_share
#  end
#
#  it "Social Service : Scenario 1 - Verify Payment" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#	puts "hb- #{@@summary[:hospital_bill]} == gross #{@@gross}"
#	puts "balance_due- #{@@summary[:balance_due]} == gross #{@@balance_due}"
#	puts "discount- #{@@summary[:discounts]} == discount #{@@total_discount}"
#	
#		
#    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    @@summary[:balance_due].should == ("%0.2f" %(@@balance_due))
#    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
#  end
#
#  it "Social Service : Scenario 1 - Complete Payment" do
#    @balance_due = slmc.get_balance_due.to_f
#    slmc.oss_add_payment(:type => 'CASH', :amount => @balance_due.to_s)
#      slmc.submit_payment.should be_true
#  end
#
#  it "Social Service : Scenario 1 - Print Gate Pass" do
#    sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin)
#    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
#  end
#
#################################################################################
#
######  # Social Service  - Standard - Discharge - w/ Adjustment - w/ PhilHealth Estimate
#  it "Social Service : Scenario 2 - Admit patient" do
#    sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#@@pin = slmc.create_new_patient(Admission.generate_data(:not_senior => true))
#    slmc.admission_search(:pin => @@pin)
#    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
#  end
#
#  it "Social Service : Scenario 2 - Order items" do
#    slmc.nursing_gu_search(:pin => @@pin)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
#   # @drugs = {"040000357" => 1, "040004334" => 1}
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 2).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
#    slmc.confirm_validation_all_items.should be_true
#    @@visit_no2 = slmc.get_text("banner.visitNo").gsub(' ','')
#  end
#
#  it "Social Service : Scenario 2 - Cancel ancillary in Order Adjustment" do
#        sleep 6
#    slmc.login("sel_pharmacy1", @password).should be_true
#    slmc.go_to_order_adjustment_and_cancellation
#    slmc.ci_search(:request_unit => "0287")
#    @data1 = slmc.get_ord_grp_no_and_ci_no(@@visit_no2, "0004") #0004 for pharmacy user performing unit
#    slmc.oss_click_adjust_order(:ci_no => @data1[1]).should be_true
#    slmc.oss_select_specific_order_adjustment(:item_code => "040004334", :cancel => true)
#  end
#
#  it "Social Service : Scenario 2 - Clinically Discharge patient" do
#    sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.go_to_general_units_page
#    @@visit_no2 = slmc.clinically_discharge_patient(:pin => @@pin, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Social Service : Scenario 2 - Compute and Save PhilHealth" do
#    sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
#    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no2)
#    @@ph2 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "10060", :medical_case_type => "ORDINARY CASE", :compute => true)
#puts  @@ph2[:total_actual_benefit_claim].to_f
# @@claim = @@ph2[:total_actual_benefit_claim].to_i
#    slmc.ph_save_computation
#  end
#
#  it "Social Service : Scenario 2 - Add Patient Share, Fund Share" do
#    sleep 6
#    slmc.login("sel_ss1", @password).should be_true
#    slmc.go_to_social_services_landing_page
#    slmc.pba_search(:pin => @@pin)
#    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
#    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share)
#  end
#
#  it "Social Service : Scenario 2 - Go to Payment during Discharge" do
#    sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
#    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no2)
#    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#    slmc.skip_update_patient_information.should be_true
#    slmc.skip_room_and_bed_cancelation.should be_true
#
#     if slmc.is_editable("btnSave")
#        slmc.click "id=btnSave"
#        slmc.get_alert() =~ /^Please click the Compute button to apply the computation of Philhealth claim./ if slmc.is_alert_present
#        slmc.choose_ok_on_next_confirmation()
#        slmc.click "id=btnCompute", :wait_for => :page
#        sleep 10
#        slmc.click "id=btnSave", :wait_for => :page
#        sleep 10
#        slmc.is_text_present("FINAL").should be_true
#        sleep 6
#        slmc.skip_philhealth.should be_true
#     end
#    slmc.skip_discount.should be_true
#    slmc.skip_generation_of_soa.should be_true
#  end
#
#  it "Social Service : Scenario 2 - Checks Payment Details" do
#    @drugs = {"040000357" => 1}
#    @ancillary = {"010000003" => 1}
#    @supplies = {"080100021" => 1}
#
#    @@orders = (@drugs).merge(@ancillary).merge(@supplies)
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @room_rate
#    @@social_service_coverage = @fund_share
#    @@discount = slmc.compute_discounts(:unit_price => @@total_gross, :promo => true)
#    @@total_discount = @@total_gross - @@social_service_coverage - @patient_share - @@claim
#    @@balance_due = @patient_share
#  end
#
#  it "Social Service : Scenario 2 - Verify Payment" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    @@summary[:balance_due].should == ("%0.2f" %(@@balance_due))
#    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
#  end
#
#  it "Social Service : Scenario 2 - Complete Payment" do
#    @balance_due = slmc.get_balance_due.to_f
#    slmc.oss_add_payment(:type => 'CASH', :amount => @balance_due.to_s)
#    slmc.submit_payment.should be_true
#  end
#
#  it "Social Service : Scenario 2 - Print Gate Pass" do
#    sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin)
#    slmc.print_gatepass(:no_result => true, :pin => @@pin).should be_true
#  end
#
################################################################################
#
#  #### Social Service - Standard - Discharge - w/ Adjustment - w/o PhilHealth
#  it "Social Service : Scenario 3 - Admit patient" do
#    sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pin2 = slmc.create_new_patient(Admission.generate_data(:not_senior => true))
#      #  slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin2)
#    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
#  end
#
#  it "Social Service : Scenario 3 - Order items" do
#    slmc.nursing_gu_search(:pin => @@pin2)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin2)
#    @drugs = {"040000357" => 1, "040004334" => 1}
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 2).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
#    slmc.confirm_validation_all_items.should be_true
#    @@visit_no3 = slmc.get_text("banner.visitNo").gsub(' ','')
#  end
#
#  it "Social Service : Scenario 3 - Cancel ancillary in Order Adjustment" do
#    sleep 6
#    slmc.login("sel_pharmacy1", @password).should be_true
#    slmc.go_to_order_adjustment_and_cancellation
#    slmc.ci_search(:request_unit => "0287")
#    @data1 = slmc.get_ord_grp_no_and_ci_no(@@visit_no3, "0004") #0004 for pharmacy user performing unit
#    slmc.oss_click_adjust_order(:ci_no => @data1[1]).should be_true
#    slmc.oss_select_specific_order_adjustment(:item_code => "040004334", :cancel => true)
#  end
#
#  it "Social Service : Scenario 3 - Clinically Discharge patient" do
#    sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.go_to_general_units_page
#    @@visit_no3 = slmc.clinically_discharge_patient(:pin => @@pin2, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Social Service : Scenario 3 - Add Patient Share, Fund Share" do
#    sleep 6
#    slmc.login("sel_ss1", @password).should be_true
#    slmc.go_to_social_services_landing_page
#    slmc.pba_search(:pin => @@pin2)
#    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
#    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share)
#  end
#
#  it "Social Service : Scenario 3 - Go to Payment during Discharge" do
#    sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
#    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no3)
#    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#    slmc.skip_update_patient_information.should be_true
#    slmc.skip_room_and_bed_cancelation.should be_true
#    slmc.skip_philhealth.should be_true
#    slmc.skip_discount.should be_true
#    slmc.skip_generation_of_soa.should be_true
#  end
#
#  it "Social Service : Scenario 3 - Checks Payment Details" do
#    @drugs = {"040000357" => 1}
#    @ancillary = {"010000003" => 1}
#    @supplies = {"080100021" => 1}
#
#    @@orders = (@drugs).merge(@ancillary).merge(@supplies)
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @room_rate
#    @@social_service_coverage = @fund_share
#    @@discount = slmc.compute_discounts(:unit_price => @@total_gross, :promo => true)
#    @@total_discount = @@total_gross - @@social_service_coverage - @patient_share
#    @@balance_due = @patient_share
#  end
#
#  it "Social Service : Scenario 3 - Verify Payment" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    @@summary[:balance_due].should == ("%0.2f" %(@@balance_due))
#    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
#  end
#
#  it "Social Service : Scenario 3 - Complete Payment" do
#    @balance_due = slmc.get_balance_due.to_f
#    slmc.oss_add_payment(:type => 'CASH', :amount => @balance_due.to_s)
#    slmc.submit_payment.should be_true
#  end
#
#  it "Social Service : Scenario 3 - Print Gate Pass" do
#    sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin2)
#    slmc.print_gatepass(:no_result => true, :pin => @@pin2).should be_true
#  end
#
#######################################################################################
########
########   ####Social Service - Standard - Discharge - w/o Adjustment - w/o PhilHealth
#  it "Social Service : Scenario 4 - Admit patient" do
#    sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin2)
#    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
#  end
#
#  it "Social Service : Scenario 4 - Order items" do
#    slmc.nursing_gu_search(:pin => @@pin2)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin2)
#    @drugs = {"040000357" => 1, "040004334" => 1}
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 2).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Social Service : Scenario 4 - Clinically Discharge patient" do
#    slmc.go_to_general_units_page
#    @@visit_no4 = slmc.clinically_discharge_patient(:pin => @@pin2, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Social Service : Scenario 4 - Add Patient Share, Fund Share" do
#    sleep 6
#    slmc.login("sel_ss1", @password).should be_true
#    slmc.go_to_social_services_landing_page
#    slmc.pba_search(:pin => @@pin2)
#    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
#    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share)
#  end
#
#  it "Social Service : Scenario 4 - Go to Payment during Discharge" do
#    sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
#    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no4)
#    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#    slmc.skip_update_patient_information.should be_true
#    slmc.skip_room_and_bed_cancelation.should be_true
#    slmc.skip_philhealth.should be_true
#    slmc.skip_discount.should be_true
#    slmc.skip_generation_of_soa.should be_true
#  end
#
#  it "Social Service : Scenario 4 - Checks Payment Details" do
#    @@orders = (@drugs).merge(@ancillary).merge(@supplies)
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @room_rate
#    @@social_service_coverage = @fund_share
#    @@discount = slmc.compute_discounts(:unit_price => @@total_gross, :promo => true)
#    @@total_discount = @@total_gross - @@social_service_coverage - @patient_share
#    @@balance_due = @patient_share
#  end
#
#  it "Social Service : Scenario 4 - Verify Payment" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    @@summary[:balance_due].should == ("%0.2f" %(@@balance_due))
#    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
#  end
#
#  it "Social Service : Scenario 4 - Complete Payment" do
#    @balance_due = slmc.get_balance_due.to_f
#    slmc.oss_add_payment(:type => 'CASH', :amount => @balance_due.to_s)
#    slmc.submit_payment.should be_true
#  end
#
#  it "Social Service : Scenario 4 - Print Gate Pass" do
#       sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin2)
#    slmc.print_gatepass(:no_result => true, :pin => @@pin2).should be_true
#  end
#
########
########################################################################################
########
########  # Social Service - Standard - Discharge - w/o Adjustment - w/ PhilHealth
#  it "Social Service : Scenario 5 - Admit patient" do #Bug 51724
#    sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pin3 = slmc.create_new_patient(Admission.generate_data(:not_senior => true))
#        #slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin3)
#    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
#  end
#
#  it "Social Service : Scenario 5 - Order items" do
#    slmc.nursing_gu_search(:pin => @@pin3)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin3)
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 2).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Social Service : Scenario 5 - Clinically Discharge patient" do
#    sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.go_to_general_units_page
#    @@visit_no5 = slmc.clinically_discharge_patient(:pin => @@pin3, :pf_amount => '1000', :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Social Service : Scenario 5 - Compute and Save PhilHealth" do
#    sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin3)
#    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no5)
#    @@ph5 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :with_operation => true, :rvu_code => "10060", :medical_case_type => "ORDINARY CASE", :compute => true)
#    slmc.ph_save_computation
#  end
#
#  it "Social Service : Scenario 5 - Add Patient Share, Fund Share" do
#    sleep 6
#    slmc.login("sel_ss1", @password).should be_true
#    slmc.go_to_social_services_landing_page
#    slmc.pba_search(:pin => @@pin3)
#    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
#    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share)
#  end
#
#  it "Social Service : Scenario 5 - Go to Payment during Discharge" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin3)
#    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no5)
#    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#    slmc.skip_update_patient_information.should be_true
#    slmc.skip_room_and_bed_cancelation.should be_true
#    num = slmc.ph_save_computation
#    puts num
#   # slmc.ph_save_computation_alert
#    slmc.skip_philhealth.should be_true
#    slmc.skip_discount.should be_true
#    slmc.skip_generation_of_soa.should be_true
#  end
#
#  it "Social Service : Scenario 5 - Checks Payment Details" do
#    @@orders = (@drugs).merge(@ancillary).merge(@supplies)
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @room_rate
#    @@social_service_coverage = @fund_share
#    @@discount = slmc.compute_discounts(:unit_price => @@total_gross, :promo => true)
#    @@total_discount = @@total_gross - @@ph5[:total_actual_benefit_claim].to_i - @@social_service_coverage - @patient_share
#    @@balance_due = @patient_share# + @@ph5[:total_actual_benefit_claim].to_i # Bug# 50039
#  end
#
#  it "Social Service : Scenario 5 - Verify Payment" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    @@summary[:balance_due].should == ("%0.2f" %(@@balance_due + 3200)) #ph estimate should add the to balance due.
#    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
#  end
#
#  it "Social Service : Scenario 5 - Complete Payment" do
#    @balance_due = slmc.get_balance_due.to_f
#    slmc.oss_add_payment(:type => 'CASH', :amount => @balance_due.to_s)
#    slmc.submit_payment.should be_true
#  end
#
#  it "Social Service : Scenario 5 - Print Gate Pass" do
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin3)
#    slmc.print_gatepass(:no_result => true, :pin => @@pin3).should be_true
#  end
#
###################################################################################
########## Scenario 6 is just the same as scenario 5 SKIP SCENARIO 6
#######
#########  # Social Service - DAS - Discharge - w/ Adjustment - w/ PhilHealth
#  it "Social Service : Scenario 7 - Admit patient" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pin4 = slmc.create_new_patient(Admission.generate_data(:not_senior => true))
#        slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin4)
#    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
#  end
#
#  it "Social Service : Scenario 7 - Order items" do
#    slmc.nursing_gu_search(:pin => @@pin4)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin4)
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 2).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
#    slmc.confirm_validation_all_items.should be_true
#    @@visit_no7 = slmc.get_text("banner.visitNo").gsub(' ','')
#  end
#
#  it "Social Service : Scenario 7 - Cancel ancillary in Order Adjustment" do
#        sleep 6
#    slmc.login("sel_pharmacy1", @password).should be_true
#    slmc.go_to_order_adjustment_and_cancellation
#    slmc.ci_search(:request_unit => "0287")
#    @data1 = slmc.get_ord_grp_no_and_ci_no(@@visit_no7, "0004") #0004 for pharmacy user performing unit
#    slmc.oss_click_adjust_order(:ci_no => @data1[1]).should be_true
#    slmc.oss_select_specific_order_adjustment(:item_code => "040004334", :cancel => true)
#  end
#
#  it "Social Service : Scenario 7 - Clinically Discharge patient" do
#    sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.go_to_general_units_page
#    @@visit_no7 = slmc.clinically_discharge_patient(:pin => @@pin4, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Social Service : Scenario 7 - Compute and Save PhilHealth" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin4)
#    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no7)
#    @@ph7 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "10060", :medical_case_type => "CATASTROPHIC CASE", :compute => true)
#    slmc.ph_save_computation
#  end
#
#  it "Social Service : Scenario 7 - Add Patient Share, Fund Share" do
#        sleep 6
#    slmc.login("sel_ss1", @password).should be_true
#    slmc.go_to_social_services_landing_page
#    slmc.pba_search(:pin => @@pin4)
#    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
#    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share)
#  end
#
#  it "Social Service : Scenario 7 - Add Payment Patient Share in Payment Page" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin4)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no7)
#    slmc.oss_add_payment(:amount => @patient_share, :type => "CASH", :deposit => true, :payment_amount => true)
#    slmc.submit_payment.should be_true
#  end
#
#  it "Social Service : Scenario 7 - DAS Discharge patient" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin4)
#    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no7)
#    slmc.select_discharge_patient_type(:type => "DAS").should be_true
#  end
#
#  it "Social Service : Scenario 7 - Goes to Payment Page" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:discharged => true, :pin => @@pin4)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no7)
#  end
#
#  it "Social Service : Scenario 7 - Checks Payment Details" do
#    @drugs = {"040000357" => 1}
#    @ancillary = {"010000003" => 1}
#    @supplies = {"080100021" => 1}
#
#    @@orders = (@drugs).merge(@ancillary).merge(@supplies)
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @room_rate
#    @@payments = @patient_share
#    @@social_service_coverage = @fund_share
#    @@total_discount = @@total_gross - @@ph7[:total_actual_benefit_claim].to_i - @patient_share - @fund_share #working in r26390
#  end
#
#  it "Social Service : Scenario 7 - Verify Payment" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    @@summary[:philhealth].should == ("%0.2f" %(@@ph7[:total_actual_benefit_claim].to_i))
#    @@summary[:payments].should == ("%0.2f" %(@patient_share))
#    @@summary[:social_service_coverage].should == ("%0.2f" %(@fund_share))
#    @@summary[:balance_due].should == ("%0.2f" %(0.0))
#   #### @@summary[:discounts].should == ("%0.2f" %(@@total_discount + @room_rate))
#    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
#  end
#
#  it "Social Service : Scenario 7 - Print Gate Pass" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin4)
#    slmc.print_gatepass(:no_result => true, :pin => @@pin4).should be_true
#  end
#
#####################################################################################
#####
#####  # Social Service - DAS - Discharge - w/ Adjustment - w/o PhilHealth
#  it "Social Service : Scenario 8 - Admit patient" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin4)
#    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
#  end
#
#  it "Social Service : Scenario 8 - Order items" do
#    slmc.nursing_gu_search(:pin => @@pin4)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin4)
#    @drugs = {"040000357" => 1, "040004334" => 1}
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 2).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
#    slmc.confirm_validation_all_items.should be_true
#    @@visit_no8 = slmc.get_text("banner.visitNo").gsub(' ','')
#  end
#
#  it "Social Service : Scenario 8 - Cancel ancillary in Order Adjustment" do
#        sleep 6
#    slmc.login("sel_pharmacy1", @password).should be_true
#    slmc.go_to_order_adjustment_and_cancellation
#    slmc.ci_search(:request_unit => "0287")
#    @data1 = slmc.get_ord_grp_no_and_ci_no(@@visit_no8, "0004") #0004 for pharmacy user performing unit
#    slmc.oss_click_adjust_order(:ci_no => @data1[1]).should be_true
#    slmc.oss_select_specific_order_adjustment(:item_code => "040004334", :cancel => true)
#  end
#
#  it "Social Service : Scenario 8 - Clinically Discharge patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.go_to_general_units_page
#    @@visit_no8 = slmc.clinically_discharge_patient(:pin => @@pin4, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Social Service : Scenario 8 - Add Patient Share, Fund Share" do
#        sleep 6
#    slmc.login("sel_ss1", @password).should be_true
#    slmc.go_to_social_services_landing_page
#    slmc.pba_search(:pin => @@pin4)
#    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
#    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share)
#  end
#
#  it "Social Service : Scenario 8 - Add Payment Patient Share in Payment Page" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin4)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no8)
#    slmc.oss_add_payment(:amount => @patient_share, :type => "CASH", :deposit => true, :payment_amount => true)
#    slmc.submit_payment.should be_true
#  end
#
#  it "Social Service : Scenario 8 - DAS Discharge patient" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin4)
#    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no8)
#    slmc.select_discharge_patient_type(:type => "DAS").should be_true
#  end
#
#  it "Social Service : Scenario 8 - Goes to Payment Page" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:discharged => true, :pin => @@pin4)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no8)
#  end
#
#  it "Social Service : Scenario 8 - Checks Payment Details" do
#    @drugs = {"040000357" => 1}
#    @ancillary = {"010000003" => 1}
#    @supplies = {"080100021" => 1}
#
#    @@orders = (@drugs).merge(@ancillary).merge(@supplies)
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @room_rate
#    @@payments = @patient_share
#    @@social_service_coverage = @fund_share
#    @@total_discount = @@total_gross - @patient_share - @fund_share #working in r26390
#  end
#
#  it "Social Service : Scenario 8 - Verify Payment" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    @@summary[:philhealth].should == ("%0.2f" %(0.0))
#    @@summary[:payments].should == ("%0.2f" %(@patient_share))
#    @@summary[:social_service_coverage].should == ("%0.2f" %(@fund_share))
#    @@summary[:balance_due].should == ("%0.2f" %(0.0))
#  ############  @@summary[:discounts].should == ("%0.2f" %(@@total_discount - @room_rate))
#    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
#  end
#
#  it "Social Service : Scenario 8 - Print Gate Pass" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin4)
#    slmc.print_gatepass(:no_result => true, :pin => @@pin4).should be_true
#  end
#
#######################################################################################
#######
#######  # Social Service - DAS - Discharge - w/o Adjustment - w/o PhilHealth
#  it "Social Service : Scenario 9 - Admit patient" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pin5 = slmc.create_new_patient(Admission.generate_data(:not_senior => true))
#       slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin5)
#    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
#  end
#
#  it "Social Service : Scenario 9 - Order items" do
#    slmc.nursing_gu_search(:pin => @@pin5)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin5)
#    @drugs = {"040000357" => 1, "040004334" => 1}
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 2).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Social Service : Scenario 9 - Clinically Discharge patient" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.go_to_general_units_page
#    @@visit_no9 = slmc.clinically_discharge_patient(:pin => @@pin5, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Social Service : Scenario 9 - Add Fund Share" do
#        sleep 6
#    slmc.login("sel_ss1", @password).should be_true
#    slmc.go_to_social_services_landing_page
#    slmc.pba_search(:pin => @@pin5)
#    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
#    slmc.add_recommendation_entry(:pcso => @fund_share)
#  end
#
#  it "Social Service : Scenario 9 - DAS Discharge patient" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin5)
#    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no9)
#    slmc.select_discharge_patient_type(:type => "DAS").should be_true
#  end
#
#  it "Social Service : Scenario 9 - Goes to Payment Page" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:discharged => true, :pin => @@pin5)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no9)
#  end
#
#  it "Social Service : Scenario 9 - Checks Payment Details" do
#    @@orders = (@drugs).merge(@ancillary).merge(@supplies)
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @room_rate
#    @@social_service_coverage = @fund_share
#    @@total_discount = @@total_gross - @fund_share #working in r26390
#  end
#
#  it "Social Service : Scenario 9 - Verify Payment" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    @@summary[:philhealth].should == ("%0.2f" %(0.0))
#    @@summary[:payments].should == ("%0.2f" %(0.0))
#    @@summary[:social_service_coverage].should == ("%0.2f" %(@fund_share))
#    @@summary[:balance_due].should == ("%0.2f" %(0.0))
#    ########@@summary[:discounts].should == ("%0.2f" %(@@total_discount - @room_rate))
#    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
#  end
#
#  it "Social Service : Scenario 9 - Print Gate Pass" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin5)
#    slmc.print_gatepass(:no_result => true, :pin => @@pin5).should be_true
#  end
#########
#######################################################################################
#######  # Social Service - DAS - Discharge - w/o Adjustment - w/ PhilHealth
#  it "Social Service : Scenario 10 - Admit patient" do #Bug 52594
#        sleep 8
#        slmc.login(@user, @password).should be_true
#        slmc.admission_search(:pin => "test")
#        @@pin5 = slmc.create_new_patient(Admission.generate_data(:not_senior => true))
#        slmc.admission_search(:pin => @@pin5)
#        slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
#  end
#
#  it "Social Service : Scenario 10 - Order items" do
#    slmc.nursing_gu_search(:pin => @@pin5)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin5)
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 2).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Social Service : Scenario 10 - Clinically Discharge patient" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.go_to_general_units_page
#    @@visit_no10 = slmc.clinically_discharge_patient(:pin => @@pin5, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Social Service : Scenario 10 - Compute and Save PhilHealth" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin5)
#    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no10)
#    @@ph10 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "10060", :medical_case_type => "CATASTROPHIC CASE", :compute => true)
#    slmc.ph_save_computation
#  end
#
#  it "Social Service : Scenario 10 - Add Fund Share" do
#        sleep 6
#    slmc.login("sel_ss1", @password).should be_true
#    slmc.go_to_social_services_landing_page
#    slmc.pba_search(:pin => @@pin5)
#    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
#    slmc.add_recommendation_entry(:pcso => @fund_share)
#  end
#
#  it "Social Service : Scenario 10 - DAS Discharge patient" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin5)
#    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no10)
#    slmc.select_discharge_patient_type(:type => "DAS").should be_true
#  end
#
#  it "Social Service : Scenario 10 - Goes to Payment Page" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:discharged => true, :pin => @@pin5)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no10)
#  end
#
#  it "Social Service : Scenario 10 - Checks Payment Details" do
#    @@orders = (@drugs).merge(@ancillary).merge(@supplies)
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @room_rate
#    @@social_service_coverage = @fund_share
#    @@total_discount = @@total_gross - @fund_share - @@ph10[:total_actual_benefit_claim].to_i #working in r26390
#  end
#
#  it "Social Service : Scenario 10 - Verify Payment" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    @@summary[:philhealth] ==  ("%0.2f" %(@@ph10[:total_actual_benefit_claim].to_i))
#    @@summary[:payments].should == ("%0.2f" %(0.0))
#    @@summary[:social_service_coverage].should == ("%0.2f" %(@fund_share))
#    @@summary[:balance_due].should == ("%0.2f" %(0.0))
#    ######@@summary[:discounts].should == ("%0.2f" %(@@total_discount - @room_rate))
#    @@summary[:discounts].should == ("%0.2f" %(@@total_discount))
#  end
#
#  it "Social Service : Scenario 10 - Print Gate Pass" do
#     sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin5)
#    slmc.print_gatepass(:no_result => true, :pin => @@pin5).should be_true
#
#  end
#
#####
#####################################################################################
######  # Social Service - Express Discharge - w/ Adjustment - w/ PhilHealth
#
#  it "Social Service : Scenario 11 - Admit patient" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pin6 = slmc.create_new_patient(Admission.generate_data(:not_senior => true))
#       slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin6)
#    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
#  end
#
#  it "Social Service : Scenario 11 - Order items" do
#    slmc.nursing_gu_search(:pin => @@pin6)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin6)
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 2).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
#    slmc.confirm_validation_all_items.should be_true
#    @@visit_no11 = slmc.get_text("banner.visitNo").gsub(' ','')
#  end
#
#  it "Social Service : Scenario 11 - Cancel ancillary in Order Adjustment" do
#        sleep 6
#    slmc.login("sel_pharmacy1", @password).should be_true
#    slmc.go_to_order_adjustment_and_cancellation
#    slmc.ci_search(:request_unit => "0287")
#    @data1 = slmc.get_ord_grp_no_and_ci_no(@@visit_no11, "0004") #0004 for pharmacy user performing unit
#    slmc.oss_click_adjust_order(:ci_no => @data1[1]).should be_true
#    slmc.oss_select_specific_order_adjustment(:item_code => "040004334", :cancel => true)
#  end
#
#  it "Social Service : Scenario 11 - Add Fund Share" do
#        sleep 6
#    slmc.login("sel_ss1", @password).should be_true
#    slmc.go_to_social_services_landing_page
#    slmc.pba_search_1(:pin => @@pin6, :admitted => true)
#    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
#    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share, :express_discharge => true)
#  end
#
#  it "Social Service : Scenario 11 - Compute and Save PhilHealth" do
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:admitted => true, :pin => @@pin6)
#    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no11)
#    @@ph11 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "10060", :medical_case_type => "CATASTROPHIC CASE", :compute => true)
#    slmc.ph_save_computation
#  end
#
#  it "Social Service : Scenario 11 - Add Payment Share before Clinical Discharge" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:admitted => true, :pin => @@pin6)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no11)
#    slmc.oss_add_payment(:amount => @patient_share, :type => "CASH", :deposit => true, :payment_amount => true)
#    slmc.submit_payment.should be_true
#  end
#
#  it "Social Service : Scenario 11 - Clinically Discharge patient" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.go_to_general_units_page
#    @@visit_no11 = slmc.clinically_discharge_patient(:pin => @@pin6, :pf_amount => "1000", :type => "express", :no_pending_order => true, :save => true).should be_true
#    slmc.is_text_present("Express discharge successful.").should be_true
#  end
#
#  it "Social Service : Scenario 11 - Go to Payment Page" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:discharged => true, :pin => @@pin6)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no11)
#  end
#
#  it "Social Service : Scenario 11 - Checks Payment Details" do
#    @drugs = {"040000357" => 1}
#    @ancillary = {"010000003" => 1}
#    @supplies = {"080100021" => 1}
#
#    @@orders = (@drugs).merge(@ancillary).merge(@supplies)
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @room_rate
#    @@social_service_coverage = @fund_share
#    @@total_discount = @@total_gross - @@ph11[:total_actual_benefit_claim].to_i - @patient_share - @fund_share
#  end
#
#  it "Social Service : Scenario 11 - Verify Payment" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    @@summary[:philhealth] ==  ("%0.2f" %(@@ph11[:total_actual_benefit_claim].to_i))
#    @@summary[:payments].should == ("%0.2f" %(@patient_share))
#    @@summary[:social_service_coverage].should == ("%0.2f" %(@fund_share))
#    @@summary[:balance_due].should == ("%0.2f" %(0.0))
#    @@summary[:discounts].should == ("%0.2f" %(@@total_discount - @room_rate))
#  end
#
#  it "Social Service : Scenario 11 - Print Gate Pass" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin6)
#    slmc.print_gatepass(:no_result => true, :pin => @@pin6).should be_true
#  end
##########
########################################################################################
########
########  # Social Service - Express Discharge - w/ Adjustment - w/o PhilHealth
#  it "Social Service : Scenario 12 - Admit patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "test")
#    @@pin6 = slmc.create_new_patient(Admission.generate_data(:not_senior => true))
#  slmc.admission_search(:pin => @@pin6)
#    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
#  end
#
#  it "Social Service : Scenario 12 - Order items" do
#    slmc.nursing_gu_search(:pin => @@pin6)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin6)
#    @drugs = {"040000357" => 1, "040004334" => 1}
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 2).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
#    slmc.confirm_validation_all_items.should be_true
#    @@visit_no12 = slmc.get_text("banner.visitNo").gsub(' ','')
#  end
#
#  it "Social Service : Scenario 12 - Cancel ancillary in Order Adjustment" do
#        sleep 6
#    slmc.login("sel_pharmacy1", @password).should be_true
#    slmc.go_to_order_adjustment_and_cancellation
#    slmc.ci_search(:request_unit => "0287")
#    @data1 = slmc.get_ord_grp_no_and_ci_no(@@visit_no12, "0004") #0004 for pharmacy user performing unit
#    slmc.oss_click_adjust_order(:ci_no => @data1[1]).should be_true
#    slmc.oss_select_specific_order_adjustment(:item_code => "040004334", :cancel => true)
#  end
#
#  it "Social Service : Scenario 12 - Add Fund Share" do
#        sleep 6
#    slmc.login("sel_ss1", @password).should be_true
#    slmc.go_to_social_services_landing_page
#    slmc.pba_search_1(:pin => @@pin6, :admitted => true)
#    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
#    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share, :express_discharge => true)
#  end
#
#  it "Social Service : Scenario 12 - Add Payment Share before Clinical Discharge" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:admitted => true, :pin => @@pin6)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no12)
#    slmc.oss_add_payment(:amount => @patient_share, :type => "CASH", :deposit => true, :payment_amount => true)
#    slmc.submit_payment.should be_true
#  end
#
#  it "Social Service : Scenario 12 - Clinically Discharge patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.go_to_general_units_page
#    @@visit_no12 = slmc.clinically_discharge_patient(:pin => @@pin6, :pf_amount => "1000", :type => "express", :no_pending_order => true, :save => true).should be_true
#    slmc.is_text_present("Express discharge successful.").should be_true
#  end
#
#  it "Social Service : Scenario 12 - Go to Payment Page" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:discharged => true, :pin => @@pin6)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no12)
#  end
#
#  it "Social Service : Scenario 12 - Checks Payment Details" do
#    @drugs = {"040000357" => 1}
#    @ancillary = {"010000003" => 1}
#    @supplies = {"080100021" => 1}
#
#    @@orders = (@drugs).merge(@ancillary).merge(@supplies)
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @room_rate
#    @@social_service_coverage = @fund_share
#    @@total_discount = @@total_gross - @patient_share - @fund_share
#  end
#
#  it "Social Service : Scenario 12 - Verify Payment" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    @@summary[:philhealth] ==  ("%0.2f" %(0.0))
#    @@summary[:payments].should == ("%0.2f" %(@patient_share))
#    @@summary[:social_service_coverage].should == ("%0.2f" %(@fund_share))
#    @@summary[:balance_due].should == ("%0.2f" %(0.0))
#    @@summary[:discounts].should == ("%0.2f" %(@@total_discount - @room_rate))
#  end
#
#  it "Social Service : Scenario 12 - Print Gate Pass" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin6)
#    slmc.print_gatepass(:no_result => true, :pin => @@pin6).should be_true
#  end
#
######################################################################################
#######
########  # Social Service - Express Discharge - w/o Adjustment - w/o PhilHealth
#  it "Social Service : Scenario 13 - Admit patient" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pin7 = slmc.create_new_patient(Admission.generate_data(:not_senior => true))
#       slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin7)
#    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
#  end
#
#  it "Social Service : Scenario 13 - Order items" do
#    slmc.nursing_gu_search(:pin => @@pin7)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin7)
#    @drugs = {"040000357" => 1, "040004334" => 1}
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 2).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
#    slmc.confirm_validation_all_items.should be_true
#    @@visit_no13 = slmc.get_text("banner.visitNo").gsub(' ','')
#  end
#
#  it "Social Service : Scenario 13 - Add Fund Share" do
#        sleep 6
#    slmc.login("sel_ss1", @password).should be_true
#    slmc.go_to_social_services_landing_page
#    slmc.pba_search_1(:pin => @@pin7, :admitted => true)
#    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
#    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share, :express_discharge => true)
#  end
#
#  it "Social Service : Scenario 13 - Add Payment Share before Clinical Discharge" do
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:admitted => true, :pin => @@pin7)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no13)
#    slmc.oss_add_payment(:amount => @patient_share, :type => "CASH", :deposit => true, :payment_amount => true)
#    slmc.submit_payment.should be_true
#  end
#
#  it "Social Service : Scenario 13 - Clinically Discharge patient" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.go_to_general_units_page
#    @@visit_no13 = slmc.clinically_discharge_patient(:pin => @@pin7, :pf_amount => "1000", :type => "express", :no_pending_order => true, :save => true).should be_true
#    slmc.is_text_present("Express discharge successful.").should be_true
#  end
#
#  it "Social Service : Scenario 13 - Go to Payment Page" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:discharged => true, :pin => @@pin7)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no13)
#  end
#
#  it "Social Service : Scenario 13 - Checks Payment Details" do
#    @@orders = (@drugs).merge(@ancillary).merge(@supplies)
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @room_rate
#    @@social_service_coverage = @fund_share
#    @@total_discount = @@total_gross - @patient_share - @fund_share
#  end
#
#  it "Social Service : Scenario 13 - Verify Payment" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    @@summary[:philhealth] ==  ("%0.2f" %(0.0))
#    @@summary[:payments].should == ("%0.2f" %(@patient_share))
#    @@summary[:social_service_coverage].should == ("%0.2f" %(@fund_share))
#    @@summary[:balance_due].should == ("%0.2f" %(0.0))
#    @@summary[:discounts].should == ("%0.2f" %(@@total_discount - @room_rate))
#  end
#
#  it "Social Service : Scenario 13 - Print Gate Pass" do
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin7)
#    slmc.print_gatepass(:no_result => true, :pin => @@pin7).should be_true
#  end
#
#######################################################################################
#######
#######  # Social Service - Express Discharge - w/o Adjustment - w/ PhilHealth
#  it "Social Service : Scenario 14 - Admit patient" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin7)
#    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
#  end
#
#  it "Social Service : Scenario 14 - Order items" do
#    slmc.nursing_gu_search(:pin => @@pin7)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin7)
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true, :quantity => q).should be_true
#    end
#    @supplies.each do |supply, q|
#      slmc.search_order(:description => supply, :supplies => true ).should be_true
#      slmc.add_returned_order(:description => supply, :supplies => true, :add => true).should be_true
#    end
#    sleep 5
#    slmc.verify_ordered_items_count(:drugs => 2).should be_true
#    slmc.verify_ordered_items_count(:supplies => 1).should be_true
#    slmc.verify_ordered_items_count(:ancillary => 1).should be_true
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :orders => "multiple").should == 4
#    slmc.confirm_validation_all_items.should be_true
#    @@visit_no14 = slmc.get_text("banner.visitNo").gsub(' ','')
#  end
#
#  it "Social Service : Scenario 14 - Add Fund Share" do
#        sleep 6
#    slmc.login("sel_ss1", @password).should be_true
#    slmc.go_to_social_services_landing_page
#    slmc.pba_search_1(:pin => @@pin7, :admitted => true)
#    slmc.go_to_page_using_visit_number("Recommendation Entry", slmc.visit_number)
#    slmc.add_recommendation_entry(:patient_share => @patient_share, :pcso => @fund_share, :express_discharge => true)
#  end
#
#  it "Social Service : Scenario 14 - Compute and Save PhilHealth" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:admitted => true, :pin => @@pin7)
#    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no14)
#    @@ph14 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "DENGUE HEMORRHAGIC FEVER", :with_operation => true, :rvu_code => "10060", :medical_case_type => "CATASTROPHIC CASE", :compute => true)
#    slmc.ph_save_computation
#  end
#
#  it "Social Service : Scenario 14 - Add Payment Share before Clinical Discharge" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:admitted => true, :pin => @@pin7)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no14)
#    slmc.oss_add_payment(:amount => @patient_share, :type => "CASH", :deposit => true, :payment_amount => true)
#    slmc.submit_payment.should be_true
#  end
#
#  it "Social Service : Scenario 14 - Clinically Discharge patient" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.go_to_general_units_page
#    @@visit_no14 = slmc.clinically_discharge_patient(:pin => @@pin7, :pf_amount => "1000", :type => "express", :no_pending_order => true, :save => true).should be_true
#    slmc.is_text_present("Express discharge successful.").should be_true
#  end
#
#  it "Social Service : Scenario 14 - Go to Payment Page" do
#        sleep 6
#    slmc.login(@pba_user, @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:discharged => true, :pin => @@pin7)
#    slmc.go_to_page_using_visit_number("Payment", @@visit_no14)
#  end
#
#  it "Social Service : Scenario 14 - Checks Payment Details" do
#    @@orders = (@drugs).merge(@ancillary).merge(@supplies)
#    @@gross = 0.0
#    @@orders.each do |order,n|
#      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
#      amt = item[:rate].to_f * n
#      @@gross += amt  # total gross amount
#    end
#
#    @@gross = (@@gross * 100).round.to_f / 100
#    @@total_gross = @@gross + @room_rate
#    @@social_service_coverage = @fund_share
#    @@total_discount = @@total_gross - @@ph14[:total_actual_benefit_claim].to_i - @patient_share - @fund_share
#  end
#
#  it "Social Service : Scenario 14 - Verify Payment" do
#    @@summary = slmc.get_billing_details_from_payment_data_entry
#
#    @@summary[:hospital_bill].should == ("%0.2f" %(@@gross))
#    @@summary[:philhealth] ==  ("%0.2f" %(@@ph14[:total_actual_benefit_claim].to_i))
#    @@summary[:payments].should == ("%0.2f" %(@patient_share))
#    @@summary[:social_service_coverage].should == ("%0.2f" %(@fund_share))
#    @@summary[:balance_due].should == ("%0.2f" %(0.0))
#    @@summary[:discounts].should == ("%0.2f" %(@@total_discount - @room_rate))
#  end
#
#  it "Social Service : Scenario 14 - Print Gate Pass" do
#        sleep 6
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin7)
#    slmc.print_gatepass(:no_result => true, :pin => @@pin7).should be_true
#  end

end