#require File.dirname(__FILE__) + '/../lib/slmc.rb'

require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
require 'spec_helper'
require 'yaml'

describe "SLMC :: Additional Account Class 2  (Company & House Staff)" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @patient = Admission.generate_data
    @oss_patient = Admission.generate_data
    @or_patient = Admission.generate_data
    @dr_patient = Admission.generate_data
    @er_patient = Admission.generate_data
    @wellness_patient1 = Admission.generate_data
    @wellness_patient2 = Admission.generate_data

    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient[:age])
    @@promo_discount2 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@oss_patient[:age])
    @@promo_discount3 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@or_patient[:age])
    @@promo_discount4 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@dr_patient[:age])
    @@promo_discount5 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@er_patient[:age])
    @@promo_discount6 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@wellness_patient1[:age])
    @@promo_discount7 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@wellness_patient2[:age])
    
    #"5c456b0314b9013d321e5f917a3a4aa3d6235dab"
    if CONFIG['db_sid'] == "QAFUNC"
            @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
            #@pba_user = "ldcastro" #"sel_pba7"
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
    
    
    
    @room_rate = 4167.0
    @drugs = {"040000357" => 1} #ORT02 discount_scheme = 'COMIPLDT001' walang ORT02
    @ancillary = {"010000003" => 1} #ORT01
    @sel_dr_validator = "msgepte"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Company : Inpatient - Create and Admit patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin = slmc.create_new_patient(@patient)
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin)
    puts @@pin
    result = slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :account_class => "COMPANY", :diagnosis => "GASTRITIS", :guarantor_code => "ABSC001").should == "Patient admission details successfully saved."
     if result == "Patient admission details successfully saved." || "Unable to print patient wristband please check your printer."
            admission = true
    else
            admission = false
    end
    admission.should == true
  end 
  it "Company : Inpatient - Update Patient Information PLDT" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.click_guarantor_to_update
    slmc.pba_update_guarantor(:guarantor_type => "COMPANY", :guarantor_code => "PLDT001")
    slmc.click_submit_changes.should be_true
  end
  it "Company : Inpatient - Order items" do
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)

    @drugs.each do |drug, q|
      slmc.search_order(:drugs => true, :code => drug).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
    end
    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
    slmc.validate_orders(:drugs => true, :ancillary => true, :multiple => true).should == 2
    slmc.confirm_validation_all_items.should be_true
  end
  it "Company : Inpatient - Clinical Discharge patient" do
    slmc.go_to_general_units_page
    #slmc.clinically_discharge_patient(:pin => @@pin, :no_pending_order => true, :pf_amount => "1000", :save => true)
    slmc.clinically_discharge_patient(:pin => @@pin, :pf_type => "DIRECT", :no_pending_order => true, :pf_amount => '1000', :type => "standard", :save => true).should be_true
  end
  it "Company : Inpatient - Skip to Payment" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.is_text_present("PLDT001").should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end
  it "Company : Inpatient - Compute Payment and Verifies Company Discount on Ordered items" do
    @@order_type1 = 0
    @@order_type2 = 0
    @@order_type3 = 0

    @@orders = @ancillary.merge(@drugs)
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

    @@gross = 0.0
    @@orders = @drugs.merge(@ancillary)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_inpatient_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end

    @@total_gross = slmc.truncate_to((@@gross + @room_rate), 2)
    @@discount_percentage = 10

    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :promo => true) if @@promo_discount == 0.16
    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :senior => true) if @@promo_discount == 0.2
    @@cd1 = @@order_type1 - @@discount1
    @@cd2 = @room_rate - (@room_rate * @@promo_discount)
    @@courtesy_discount1 = (slmc.compute_courtesy_discount(:percent => true, :net => @@cd1, :amount => @@discount_percentage)) +
                           (slmc.compute_courtesy_discount(:percent => true, :net => @@cd2, :amount => @@discount_percentage))
    @@discount = slmc.compute_discounts(:unit_price => @@total_gross, :promo => true) if @@promo_discount == 0.16
    @@discount = slmc.compute_discounts(:unit_price => @@total_gross, :senior => true) if @@promo_discount == 0.2
    @@total_discount = ((@@discount + @@courtesy_discount1) * 100).round.to_f / 100
    @@total_hospital_bill = @@total_gross - @@total_discount



    @@summary = slmc.get_billing_details_from_payment_data_entry
        puts "@@summary[:discounts].to_f  #{@@summary[:discounts].to_f }"
    puts "@@total_discount #{@@total_discount}"
    ((slmc.truncate_to((@@summary[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bill),2).to_f).abs).should <= 1.0
  end
  it "Company : OSS - Creates patient in DAS - OSS" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(@oss_patient).gsub(' ', '')
  end
  it "Company : OSS - Add Guarantor in OSS page" do
    sleep 5
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order(:pin => @@oss_pin).should be_true
    slmc.oss_add_guarantor(:guarantor_type => 'COMPANY', :acct_class => 'COMPANY', :guarantor_code => "PLDT001", :guarantor_add => true)
  end
  it "Company : OSS Order items" do
    slmc.oss_order(:item_code => "010000000", :order_add => true, :doctor => "6726").should be_true
    slmc.oss_order(:item_code => "081000001", :order_add => true, :doctor => "0126").should be_true
  end
  it "Company : OSS Checks Computation of Gross, Discount and Balance Due" do
    @@orders = {"010000000" => 1, "081000001" => 1}

    @@order_type1 = 0
    @@order_type2 = 0
    @@order_type3 = 0

    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_order_details_based_on_order_number(order)
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

    @@gross = 0.0
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt
    end

    @@discount_percentage = 10
    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :promo => true) if @@promo_discount2 == 0.16
    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :senior => true) if @@promo_discount2 == 0.2
    @@cd1 = @@order_type1 - @@discount1
    @@courtesy_discount1 = (slmc.compute_courtesy_discount(:percent => true, :net => @@cd1, :amount => @@discount_percentage))

    @@gross = ((@@gross)*100).round.to_f / 100
    @@pos = slmc.pos_computation(:total_gross => @@gross, :promo => true) if @@promo_discount2 == 0.16
    @@pos = slmc.pos_computation(:total_gross => @@gross, :senior => true) if @@promo_discount2 == 0.2
    @@net_amount = (@@pos[:gross] - @@pos[:discount] - @@courtesy_discount1)
    @@balance_due = (@@gross - (slmc.truncate_to(@@pos[:discount],2) + slmc.truncate_to(@@courtesy_discount1, 2) ))

    @@summary = slmc.get_summary_totals
    ((slmc.truncate_to((@@summary[:total_gross_amount].to_f - @@pos[:gross]),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @@pos[:discount]),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_net_amount].to_f - @@net_amount),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_amount_due].to_f - @@balance_due),2).to_f).abs).should <= 1.0
  end
  it "Company : OSS Settles Payment and Submit" do
    @@amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => @@amount, :type => "CASH")
    slmc.oss_submit_order("yes").should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end
  it "Company : OR - Create and Admit patient" do
    slmc.login(@or_user, @password).should be_true
    @@or_pin = slmc.or_create_patient_record(@or_patient.merge!(:admit => true, :account_class => "COMPANY", :guarantor_type => "COMPANY", :guarantor_code => "PLDT001")).gsub(' ', '')
  end
  it "Company : OR - Order items" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@or_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@or_pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :stat => true,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    slmc.er_submit_added_order(:validate => true).should be_true
   slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
  end
  it "Company : OR - Clinical Discharge patient" do
    slmc.go_to_occupancy_list_page
    slmc.clinically_discharge_patient(:outpatient => true, :pin => @@or_pin, :save => true, :pf_amount => "1000", :no_pending_order =>true)

  end
  it "Company : OR - Skip to Payment" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@or_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.is_text_present("PLDT001").should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end
  it "Company : OR - Compute Payment and Verifies Company Discount on Ordered items" do
    @@order_type1 = 0
    @@order_type2 = 0
    @@order_type3 = 0

    @@orders = @ancillary.merge(@drugs)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
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

    @@gross = 0.0
    @@orders = @drugs.merge(@ancillary)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end

    @@gross = ((@@gross)*100).round.to_f / 100
    @@discount_percentage = 10

    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :promo => true) if @@promo_discount3 == 0.16
    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :senior => true) if @@promo_discount3 == 0.2
    @@cd1 = @@order_type1 - @@discount1
    @@courtesy_discount1 = (slmc.compute_courtesy_discount(:percent => true, :net => @@cd1, :amount => @@discount_percentage))
    @@discount = slmc.compute_discounts(:unit_price => @@gross, :promo => true) if @@promo_discount3 == 0.16
    @@discount = slmc.compute_discounts(:unit_price => @@gross, :senior => true) if @@promo_discount3 == 0.2
    @@total_discount = ((@@discount + @@courtesy_discount1) * 100).round.to_f / 100
    @@total_hospital_bill = @@gross - @@total_discount + 0.01

    @@summary = slmc.get_billing_details_from_payment_data_entry
    ((slmc.truncate_to((@@summary[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:room_charges].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:adjustments].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:philhealth].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:ewt].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:gift_check].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:payments].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:charged_amount].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bill),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:pf_amount].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:pf_payments].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:pf_charged].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_amount_due].to_f - @@total_hospital_bill),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_payments].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:balance_due].to_f - @@total_hospital_bill),2).to_f).abs).should <= 1.0
  end
  it "Company : DR - Create and Admit patient" do
    slmc.login(@dr_user, @password).should be_true
    @@dr_pin = slmc.or_nb_create_patient_record(@dr_patient.merge!(:admit => true, :org_code => "0170", :account_class => "COMPANY", :guarantor_type => "COMPANY", :guarantor_code => "PLDT001")).gsub(' ', '')
  end
  it "Company : DR - Order items" do
    slmc.go_to_occupancy_list_page
    slmc.patient_pin_search(:pin => @@dr_pin)
    slmc.go_to_su_page_for_a_given_pin("Order Page", @@dr_pin)
    @drugs.each do |item, q|
      slmc.search_order(:description => item, :drugs => true).should be_true
      slmc.add_returned_order(:drugs => true, :description => item, :stat => true,
        :stock_replacement => true, :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
    end
    @ancillary.each do |item, q|
      slmc.search_order(:description => item, :ancillary => true).should be_true
      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
    end
    slmc.er_submit_added_order(:validate => true, :username => @sel_dr_validator).should be_true
    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 2
    slmc.confirm_validation_all_items.should be_true
  end
  it "Company : DR - Clinical Discharge patient" do
    slmc.go_to_occupancy_list_page
    slmc.clinically_discharge_patient(:outpatient => true, :pin => @@dr_pin, :save => true, :pf_amount => "1000")
  end
  it "Company : DR - Skip to Payment" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@dr_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.is_text_present("PLDT001").should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end
  it "Company : DR - Compute Payment and Verifies Company Discount on Ordered items" do
    @@order_type1 = 0
    @@order_type2 = 0
    @@order_type3 = 0

    @@orders = @ancillary.merge(@drugs)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
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

    @@gross = 0.0
    @@orders = @drugs.merge(@ancillary)
    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
      amt = item[:rate].to_f * n
      @@gross += amt  # total gross amount
    end

    @@gross = ((@@gross)*100).round.to_f / 100
    @@discount_percentage = 10

    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :promo => true) if @@promo_discount4 == 0.16
    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :senior => true) if @@promo_discount4 == 0.2
    @@cd1 = @@order_type1 - @@discount1
    @@courtesy_discount1 = (slmc.compute_courtesy_discount(:percent => true, :net => @@cd1, :amount => @@discount_percentage))
    @@discount = slmc.compute_discounts(:unit_price => @@gross, :promo => true) if @@promo_discount4 == 0.16
    @@discount = slmc.compute_discounts(:unit_price => @@gross, :senior => true) if @@promo_discount4 == 0.2
    @@total_discount = ((@@discount + @@courtesy_discount1) * 100).round.to_f / 100
    @@total_hospital_bill = @@gross - @@total_discount

    @@summary = slmc.get_billing_details_from_payment_data_entry
    ((slmc.truncate_to((@@summary[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:room_charges].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:adjustments].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:philhealth].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:ewt].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:gift_check].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:payments].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:charged_amount].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bill),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:pf_amount].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:pf_payments].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:pf_charged].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_amount_due].to_f - @@total_hospital_bill),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_payments].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:balance_due].to_f - @@total_hospital_bill),2).to_f).abs).should <= 1.0
  end
  it "NO ER PHILHEALTH" do
            ########  NO ER PHILHEALTH
            ########  it "Company : ER - Create and Admit patient" do
            ########    slmc.login(@er_user, @password).should be_true
            ########    @@er_pin = slmc.er_create_patient_record(@er_patient.merge!(:admit => true, :account_class => "COMPANY")).gsub(' ','')
            ########  end
            ########
            ########  it "Company : ER - Updates Guarantor (PLDT001)" do
            ########    slmc.go_to_er_billing_page
            ########    slmc.pba_search_1(:admitted => true, :pin => @@er_pin).should be_true
            ########    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
            ########    slmc.click_new_guarantor
            ########    slmc.pba_update_guarantor(:guarantor_type => "COMPANY", :guarantor_code => "PLDT001").should be_true
            ########    slmc.click_submit_changes.should be_true
            ########  end
            ########
            ########  it "Company : ER - Order items" do
            ########    slmc.go_to_er_landing_page
            ########    slmc.patient_pin_search(:pin => @@er_pin)
            ########    slmc.go_to_er_page_using_pin("Order Page", @@er_pin)
            ########    @drugs.each do |item, q|
            ########    slmc.search_order(:description => item, :drugs => true).should be_true
            ########      slmc.add_returned_order(:drugs => true, :description => item,
            ########        :quantity => q, :frequency => "ONCE A WEEK", :add => true, :doctor => "6726").should be_true
            ########    end
            ########    @ancillary.each do |item, q|
            ########      slmc.search_order(:description => item, :ancillary => true).should be_true
            ########      slmc.add_returned_order(:ancillary => true, :description => item, :add => true, :doctor => "0126").should be_true
            ########    end
            ########    slmc.er_submit_added_order
            ########    slmc.validate_orders(:drugs => true, :ancillary => true, :orders => "multiple").should == 2
            ########    slmc.confirm_validation_all_items.should be_true
            ########  end
            ########
            ########  it "Company : ER - Clinical Discharge Patient" do
            ########    slmc.go_to_er_page
            ########    slmc.clinically_discharge_patient(:er => true, :pin => @@er_pin, :save => true, :pf_amount => "1000")
            ########  end
            ########
            ########  it "Company : ER - Skip to Payment in ER Billing" do
            ########    slmc.go_to_er_billing_page
            ########    slmc.pba_search_1(:with_discharge_notice => true, :pin => @@er_pin)
            ########    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
            ########    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
            ########    slmc.is_text_present("PLDT001").should be_true
            ########    slmc.skip_update_patient_information.should be_true
            ########    slmc.skip_philhealth.should be_true
            ########    slmc.skip_discount.should be_true
            ########    slmc.skip_generation_of_soa.should be_true
            ########  end
            ########
            ########  it "Company : ER - Compute Payment and Verifies Company Discount on Ordered items" do
            ########    @@order_type1 = 0
            ########    @@order_type2 = 0
            ########    @@order_type3 = 0
            ########
            ########    @@orders = @ancillary.merge(@drugs)
            ########    @@orders.each do |order,n|
            ########      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
            ########      if item[:order_type] == "ORT01"
            ########        amt = item[:rate].to_f * n
            ########        @@order_type1 += amt
            ########      end
            ########      if item[:order_type] == "ORT02"
            ########        n_amt = item[:rate].to_f * n
            ########        @@order_type2 += n_amt
            ########      end
            ########      if item[:order_type] == "ORT03"
            ########        x_lab_amt = item[:rate].to_f * n
            ########        @@order_type3 += x_lab_amt
            ########      end
            ########    end
            ########
            ########    @@gross = 0.0
            ########    @@orders = @drugs.merge(@ancillary)
            ########    @@orders.each do |order,n|
            ########      item = PatientBillingAccountingHelper::Philhealth.get_or_order_details_based_on_order_number(order)
            ########      amt = item[:rate].to_f * n
            ########      @@gross += amt  # total gross amount
            ########    end
            ########
            ########    @@gross = ((@@gross)*100).round.to_f / 100
            ########    @@discount_percentage = 10
            ########
            ########    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :promo => true) if @@promo_discount5 == 0.16
            ########    @@discount1 = slmc.compute_discounts(:unit_price => @@order_type1, :senior => true) if @@promo_discount5 == 0.2
            ########    @@cd1 = @@order_type1 - @@discount1
            ########    @@courtesy_discount1 = (slmc.compute_courtesy_discount(:percent => true, :net => @@cd1, :amount => @@discount_percentage))
            ########    @@discount = slmc.compute_discounts(:unit_price => @@gross, :promo => true) if @@promo_discount5 == 0.16
            ########    @@discount = slmc.compute_discounts(:unit_price => @@gross, :senior => true) if @@promo_discount5 == 0.2
            ########    @@total_discount = ((@@discount + @@courtesy_discount1) * 100).round.to_f / 100
            ########    @@total_hospital_bill = @@egross - @@total_discount
            ########
            ########    @@summary = slmc.get_billing_details_from_payment_data_entry
            ########    ((slmc.truncate_to((@@summary[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:room_charges].to_f - 0.0),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:adjustments].to_f - 0.0),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:philhealth].to_f - 0.0),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:discounts].to_f - @@total_discount),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:ewt].to_f - 0.0),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:gift_check].to_f - 0.0),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:payments].to_f - 0.0),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:charged_amount].to_f - 0.0),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bill),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:pf_amount].to_f - 0.0),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:pf_payments].to_f - 0.0),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:pf_charged].to_f - 0.0),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:total_amount_due].to_f - @@total_hospital_bill),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:total_payments].to_f - 0.0),2).to_f).abs).should <= 1.0
            ########    ((slmc.truncate_to((@@summary[:balance_due].to_f - @@total_hospital_bill),2).to_f).abs).should <= 1.0
            ########  end
  end
  it "Company : Wellness Outpatient - Create patient" do
    slmc.login(@wellness_user, @password).should be_true
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => "test").should be_true
    @@wellness1 = slmc.create_new_patient(@wellness_patient1.merge(:gender => 'M'))
  end
  it "Company : Wellness Outpatient - Add Package and Validate" do
    slmc.login(@wellness_user, @password).should be_true
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness1).should be_true
    slmc.click_outpatient_package_management.should be_true
    slmc.add_wellness_package(:package => "CANCER PACKAGE - ADVANCE A MALE", :doctor => "6930").should be_true
    slmc.validate_wellness_package
  end
  it "Company : Wellness Outpatient - Add Company Guarantor (PLDT001) and Goes to Payment Page" do
    slmc.wellness_allocate_doctor_pf(:pf_type => "PF INCLUSIVE OF PACKAGE", :pf_amount => 16800).should be_true
    slmc.wellness_update_guarantor(:account_class => "COMPANY", :guarantor => "COMPANY", :guarantor_code => "PLDT001").should be_true
    sleep 4
    slmc.go_to_wellness_package_billing_page
    slmc.patient_pin_search(:pin => @@wellness1).should be_true
    slmc. click "link=PAYMENT", :wait_for =>:page

  end
  it "Company : Wellness Outpatient - Compute Payment and Verifies Company Discount on Ordered items" do
    @@gross = ((slmc.wellness_get_total_gross_of_items_in_package(:unit_price => true)) * 100).round.to_f / 100
    @@discount = @@gross * @@promo_discount6
    @@package_amount = slmc.access_from_database(:what => "PACKAGE_AMOUNT", :table => "REF_PACKAGE_RATE", :column1 => "PACKAGE_CODE", :condition1 => "94001").to_i
    @@total_package_discount = ((@@gross - (@@package_amount + @@discount)) * 100).round.to_f / 100  # Package Discount	= Actual Package Price – (Package Amount + Promo Discount)
    @@pf_fee = 16800.0
    @@total_amount_due = @@package_amount + @@pf_fee

    @@summary = slmc.get_summary_totals
    ((slmc.truncate_to((@@summary[:total_gross_amount].to_f - @@gross),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @@discount),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_class_discount].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_package_discount].to_f - @@total_package_discount),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_net_amount].to_f - @@package_amount),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_pf].to_f - @@pf_fee),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_amount_due].to_f - @@total_amount_due),2).to_f).abs).should <= 1.0
    slmc.wellness_payment(:cash => true).should be_true
  end
  it "Company : Wellness Outpatient - Settle Payment" do
    slmc.go_to_wellness_package_ordering_page
    slmc.patient_pin_search(:pin => @@wellness1).should be_true
    slmc.click_outpatient_package_management.should be_true
   # slmc.wellness_payment(:cash => true).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    #slmc.wellness_payment(:cash => true).should == "The SOA was successfully updated with printTag = 'Y'."
#     Database.connect
#        a =  "SELECT MAX(VISIT_NO) FROM SLMC.TXN_ADM_ENCOUNTER WHERE PIN ='#{@@wellness1}'"
#        visit_no = Database.select_statement a
#     Database.logoff
#     slmc.wellness_payment(:cash => true).should == "SOA with Confinement No = #{visit_no} successfully printed."
slmc.is_text_present("Fully Paid").should be_true
  end
  it "Company : Wellness Inpatient - Admit and Create patient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@wellness2 = slmc.create_new_patient(@wellness_patient2.merge!(:gender => 'M'))
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@wellness2)
    slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :room_charge => "REGULAR PRIVATE", :account_class => "COMPANY", :guarantor_code => "ABSC001", :diagnosis => "GASTRITIS", :package => "PLAN A MALE").should == "Patient admission details successfully saved."
  end
  it "Company : Wellness Inpatient - Update Patient Information PLDT" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@wellness2)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.click_guarantor_to_update
    slmc.pba_update_guarantor(:guarantor_type => "COMPANY", :guarantor_code => "PLDT001")
    slmc.click_submit_changes.should be_true
    puts @@wellness2
  end
  it "Company : Wellness Inpatient - Validates Package" do
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.nursing_gu_search(:pin => @@wellness2)
    slmc.go_to_gu_page_for_a_given_pin("Package Management", @@wellness2)
#    if slmc.is_element_present('id="divValidateSwitchItems"')
#          slmc.click "//button[@type='button']"
#
#    end
    slmc.click Locators::Wellness.order_package #, :wait_for => :page
    #slmc.click "xpath=(//button[@type='button'])[3]" if slmc.is_element_present("xpath=(//button[@type='button'])[3]")
    sleep 10

    slmc.validate_package.should be_true
    slmc.validate_credentials(:username => "sel_0287_validator", :password => @password, :package => true)
    
  end
  it "Company : Wellness Inpatient - Clinical Discharge patient" do
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @@wellness2, :no_pending_order => true, :pf_amount => "1000", :with_complementary => true, :save => true).should be_true
    puts @@wellness2
  end
  it "Company : Wellness Inpatient - Skip to Payment" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@wellness2)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.is_text_present("PLDT001").should be_true
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
    slmc.skip_philhealth.should be_true
    slmc.skip_discount.should be_true
    slmc.skip_generation_of_soa.should be_true
  end
  it "Company : Wellness Inpatient - Verifies Payment" do
    @@pf_fee = 6300
    @@gross = slmc.access_from_database(
      :what => "PACKAGE_AMOUNT",
      :table => "REF_PACKAGE_RATE",
      :column1 => "PACKAGE_CODE",
      :condition1 => "10000",
      :gate => "and",
      :column2 => "TOTAL_PF",
      :condition2 => @@pf_fee).to_i
    @@total_hospital_bill = (@@gross * 100).round.to_f / 100
    @@total_amount_due = @@total_hospital_bill + @@pf_fee


    @@summary = slmc.get_billing_details_from_payment_data_entry
    ((slmc.truncate_to((@@summary[:hospital_bill].to_f - @@gross),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:room_charges].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:adjustments].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:philhealth].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:discounts].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:ewt].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:gift_check].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:payments].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:charged_amount].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @@total_hospital_bill),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:pf_amount].to_f - @@pf_fee),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:pf_payments].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:pf_charged].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_amount_due].to_f - @@total_amount_due),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:total_payments].to_f - 0.0),2).to_f).abs).should <= 1.0
    ((slmc.truncate_to((@@summary[:balance_due].to_f - @@total_amount_due),2).to_f).abs).should <= 1.0
  end
  ############### House Staff not yet available, refer to testcase
end




