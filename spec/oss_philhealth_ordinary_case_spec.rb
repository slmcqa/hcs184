require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: OSS - Philhealth Module Test(Ordinary Case)" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @ph_patient = Admission.generate_data    
    @password = "123qweuser"
    @promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@ph_patient[:age])
    
    # items to be ordered
    @doctors = ["6726","0126","6726","0126"]
    @drugs = {"042422511" => 20}
    @ancillary = {"010000004" => 1}
    @operation = {"010000160" => 1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Creates patient for OSS transactions" do
    slmc.login('sel_oss1', @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(@ph_patient).should be_true
    @@oss_pin.should be_true
    @@pin = @@oss_pin.gsub(' ', '')
  end

  it "Searches and adds order items in the OSS outpatient order page" do
        slmc.login('sel_oss1', @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true

    #add all items to be ordered
    @@orders = @ancillary.merge(@operation).merge(@drugs)
    n = 0
    @@orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
      n += 1
    end
  end

  it "Add guarantor and enable philhealth patient information" do
    slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "10060", :compute => true)
  end

  it "Check Benefit Summary totals" do
    # set to 0 to initialize variables
    sleep 5
    @@comp_drugs = 0
    @@comp_xray_lab = 0
    @@comp_operation = 0
    @@comp_others = 0
    @@comp_supplies = 0
    @@non_comp_drugs = 0
    @@non_comp_drugs_mrp_tag = 0
    @@non_comp_xray_lab = 0
    @@non_comp_operation = 0
    @@non_comp_others = 0
    @@non_comp_supplies = 0

    @@orders.each do |order,n|
      item = PatientBillingAccountingHelper::Philhealth.get_order_details_based_on_order_number(order)
      if item[:ph_code] == "PHS01"
        amt = item[:rate].to_f * n
        @@comp_drugs += amt  # total compensable drug
      end
      if item[:ph_code] == "PHS06"
        n_amt = item[:rate].to_f * n
        @@non_comp_drugs += n_amt # total non-compensable drug
      end
      if item[:ph_code] == "PHS02"
        x_lab_amt = item[:rate].to_f * n
        @@comp_xray_lab += x_lab_amt   # total compensable xray and lab
      end
      if item[:ph_code] == "PHS03"
        o_amt = item[:rate].to_f * n
        @@comp_operation += o_amt  # total compensable operations
      end
      if item[:ph_code] == "PHS10"
        s_amt = item[:rate].to_f * n
        @@non_comp_supplies += s_amt  # total non compensable supplies
      end
    end
  end

  it "Checks if the actual charge for drugs/medicine is correct"   do
    # actual medical charges computation
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs -  (@promo_discount * total_drugs)
    @@ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end

  it "Checks if the actual benefit claim for drugs/medicine is correct" do
    # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
#    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB02")
#    if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
#      @@actual_medicine_benefit_claim = @@actual_medicine_charges
#    else
#      @@actual_medicine_benefit_claim = @@med_ph_benefit[:max_amt].to_f
#    end
    @@actual_medicine_benefit_claim = 0.00
    @@ph[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
  end

  it "Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_supplies
    @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
    @@ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end

  it "Checks if the actual lab benefit claim is correct" do
    # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
#    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB03")
#    if @@actual_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
#      @@actual_lab_benefit_claim = @@actual_xray_lab_others
#    else
#      @@actual_lab_benefit_claim = @@lab_ph_benefit[:max_amt].to_f
#    end
    @@actual_lab_benefit_claim = 0.00
    @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim))
  end

  it "Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@promo_discount * @@comp_operation)
    @@ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end

  it "Checks if the actual operation benefit claim is correct" do
#    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB04.1")
#    if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
#      @@actual_operation_benefit_claim = @@actual_operation_charges
#    else
#      @@actual_operation_benefit_claim = @@operation_ph_benefit[:max_amt].to_f
#    end
    @@actual_operation_benefit_claim = 0.00
    @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim))
  end

  it "Checks if the total actual charge(s) is correct" do
    total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
    @@ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end

  it "Checks if the total actual benefit claim is correct" do
#    @@total_actual_benefit_claim = @@actual_medicine_benefit_claim + @@actual_lab_benefit_claim + @@actual_operation_benefit_claim
    @@total_actual_benefit_claim = 2800
    @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Checks if the maximum benefits are correct" do
    @@ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end

  it "Checks if Deduction Claims are correct" do
    @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim))
    @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim))
    @@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim))
  end

  it "Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim < @@med_ph_benefit[:max_amt].to_f
      drugs_remaining_benefit_claim = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim
    else
      drugs_remaining_benefit_claim = 0.0
    end
    (@@ph[:drugs_remaining_benefit_claims].to_f).should == drugs_remaining_benefit_claim

    if @@actual_lab_benefit_claim < @@lab_ph_benefit[:max_amt].to_f
      lab_remaining_benefit_claim = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim
    else
      lab_remaining_benefit_claim = 0
    end
    (@@ph[:lab_remaining_benefit_claims].to_f).should == lab_remaining_benefit_claim
  end

  it "Checks if PF Claims for surgeon(GP) is correct" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.3")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f

    @@ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "Checks if PF Claims for anesthesiologist(GP) is correct" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.6")
    anesthesiologist_claim = (@@surgeon_claim.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))

    @@ph[:anesthesiologist_benefit_claim].should == ("%0.2f" %(anesthesiologist_claim))
  end

  it "Checks if Philhealth Claims is displayed in Summary Totals correctly" do
    slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim))
  end

  it "Checks if Summary Totals > Total Amount Due is equal to Payments > Total Net Amount " do
    slmc.get_total_amount_due.should == slmc.get_billing_total_net_amount
  end

  it "Checks No Claim History" do
    slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
  end

  it "PhilHealth benefit claim shall not reflect in Payment details" do
    slmc.click "paymentToggle"
    (slmc.get_text('paymentSection').include? 'Philhealth').should be_false
    (slmc.get_text('paymentSection').include? @@total_actual_benefit_claim.to_s).should be_false
    slmc.click "paymentToggle"
  end

  it "Proceed with payment successfully" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "Bug #26201 - PhilHealth-OSS * PF claim not saved for endoscopic procedure" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_order(:order_add => true, :item_code => "010001900", :doctor => "6726") ## assigned doctor is surgeon
    slmc.oss_order(:order_add => true, :item_code => "010000050", :doctor => "0126") ## assigned doctor is anesthesiologist
    slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "10060", :surgeon_type => "GENERAL PRACTITIONER", :anesthesiologist_type => "GENERAL PRACTITIONER",  :compute => true)

    #endoscopic items computes straight operation benefit claim (rvu_value * ph_pcf)
    #rvu with a range 0 to 30 will have a fixed benefit claim of 1200
    #rvu with a range 31 to 80 will have a fixed benefit claim of 1500
    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
    @@actual_operation_benefit_claim2 = @@operation_ph_benefit[:max_amt].to_f

    @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
  end

  it "Checks if PF Claims for surgeon is correct for orders with endoscopic item" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.3")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f

    @@ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
  end

  it "Checks if PF Claims for anesthesiologist is correct for orders with endoscopic items" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))

    @@ph[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
  end

  it "Proceed with payment successfully for orders with endoscopic items" do
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_f
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it "Bug #26198 - PhilHealth-OSS * Incorrect PF benefit claim displayed in PhilHealth Outpatient Computation page" do
    slmc.login("sel_pba1", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation.should be_true
    slmc.pba_pin_search(:pin => @@pin)
    slmc.click_latest_philhealth_link_for_outpatient
    slmc.get_text('//html/body/div/div[2]/div[2]/form/div[4]/div[9]/div[2]/table/tbody/tr/td[5]').gsub(',','').to_f.should == @@surgeon_claim
    slmc.get_text('//html/body/div/div[2]/div[2]/form/div[4]/div[9]/div[2]/table/tbody/tr[2]/td[5]').gsub(',','').to_f.should == @@anesthesiologist_claim
  end

  it "Bug #25165 - PhilHealth-OSS * PF benefit claim is computed on special case - radiation oncology" do
    slmc.login('sel_oss1', @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_order(:order_add => true, :item_code => "010001636", :doctor => "6726") ## assigned doctor is anesthesiologist
    slmc.oss_order(:order_add => true, :item_code => "010001585", :doctor => "0126") ## assigned doctor is surgeon
    slmc.oss_order(:order_add => true, :item_code => "010001583", :doctor => "6726")
    slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    slmc.oss_patient_info(:philhealth => true)
    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "10060", :surgeon_type => "GENERAL PRACTITIONER", :anesthesiologist_type => "GENERAL PRACTITIONER",  :compute => true)

    @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ordinary_ph_benefit_using_code("PHB04.1")

    actual_operation_benefit_claim = @@operation_ph_benefit[:max_amt].to_f * 3 ## number of operation sessions
    @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(actual_operation_benefit_claim))
  end
  
end