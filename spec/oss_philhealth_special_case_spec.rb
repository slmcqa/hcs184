require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: OSS - Philhealth Module Test(Special Case)" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
#    @selenium_driver.evaluate_rooms_for_admission('0164','RCHSP')
    @selenium_driver.start_new_browser_session
    @ph_patient = Admission.generate_data(:not_senior=>true)
    @password = "123qweuser"


        @pba_user = "ldcastro" #"sel_pba7"



    @promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@ph_patient[:age])
    #@all_items = {"010001194" => 1, "010001448" => 1, "010000050" => 1,"010001585" => 1, "010001583" => 1,"010000003"=>1,"010000160" => 1,"010001900" =>1,"010001636" =>1}
    @ancillary = {"010001194" =>1, "010001448" =>1, "010000050" =>1}
    @doctors = ["5979","0126"]
    @operation = {"010000160" =>1}

    @ancillary1={"010000050"=>1}
    @operation1={"010001900" =>1}

    @ancillary2 = {"010001585" => 1, "010001583" => 1}
    @operation2={"010001636" =>1}
    @doctors2 = ["5979","0126","5979"]

    @ancillary3 = {"010001585" => 1, "010001583" => 1, "010000003"=>1}
    @operation3={"010001636" =>1}
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

    it "Creates patient for OSS transactions" do
    slmc.login('jtsalang', @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(@ph_patient).should be_true
    @@oss_pin.should be_true
    @@pin = @@oss_pin.gsub(' ', '')
  end
    it "3rd Scenario -Normal Spontaneous Delivery Package, Claim Type: Accounts Receivable" do #is treated as normal case
        slmc.login('jtsalang', @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_patient_info(:philhealth => true)
  end
    it "3rd Scenario - Input guarantors" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    end
    it "3rd Scenario - Order items" do
      @@orders =  @ancillary.merge(@operation)
      @@orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => "5979")
      end
    end
    it "3rd scenario - Enable Philhealth Information" do
        @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE",:claim_type=>"ACCOUNTS RECEIVABLE",:with_operation=>true,
          :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "59400", :compute => true)
  end
    it "3rd scenario - Check Benefit Summary totals" do
      # set to 0 to initialize variables
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
        if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
        end
        if item[:ph_code] == "PHS03"
          o_amt = item[:rate].to_f * n
          o_amt = item[:rate].to_f * n
          @@comp_operation += o_amt  # total compensable operations
        end
        if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
        end
      end
    end
    it "3rd scenario - Checks if the actual charge for drugs/medicine is correct"   do
      @@actual_medicine_charges = @@comp_drugs -  (@promo_discount * @@comp_drugs)
      @@actual_medicine_charges.should == "0.0".to_f
      @@ph[:actual_medicine_charges].should == "0.00"
    end
    it "3rd scenario - Checks if the actual benefit claim for drugs/medicine is correct" do
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim1 = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f
      end
      @@actual_medicine_benefit_claim1.should == "0.0".to_f
      @@ph[:actual_medicine_benefit_claim].should == "0.00"
    end
    it "3rd scenario - Checks if the actual charge for xrays, lab and others is correct" do
      @@actual_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
      @@ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "3rd scenario - Checks if the actual lab benefit claim is correct" do
      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
      if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
        @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
      end
      @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
    end
    it "3rd scenario - Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@promo_discount * @@comp_operation)
      @@ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "3rd scenario - Checks if the actual operation benefit claim is correct" do
       if slmc.get_value("philHealthBean.rvu.code").empty? == false
             @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
          if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
            @@actual_operation_benefit_claim1 = @@actual_operation_charges
          else
            @@actual_operation_benefit_claim1 = @@operation_ph_benefit[:max_amt].to_f
          end
          @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
        else
          @@actual_operation_benefit_claim1 = 0.00
          @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
      end
    end
    it "3rd scenario - Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "3rd scenario - Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim1 = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1
      @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim1))
    end
    it "3rd scenario - Checks if the maximum benefits are correct" do
      @@ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "3rd scenario - Checks if Deduction Claims are correct" do
      @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
      @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
      @@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
    end
    it "3rd scenario - Checks if Remaining Benefit Claims are correct" do
      if @@actual_medicine_benefit_claim1 < @@med_ph_benefit[:max_amt].to_f
        @@drugs_remaining_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1
      else
        @@drugs_remaining_benefit_claim1 = 0.00
      end
      @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim1

      if @@actual_lab_benefit_claim1 < @@lab_ph_benefit[:max_amt].to_f
        @@lab_remaining_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
      else
        @@lab_remaining_benefit_claim1 = 0.00
      end
      @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim1
    end
    it "3rd scenario - Checks if Philhealth Claims is displayed in Summary Totals correctly" do
      slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim1))
    end
    it "3rd scenario - Checks if Summary Totals > Total Amount Due is equal to Payments > Total Amount Due " do
      slmc.get_total_amount_due.should == slmc.get_billing_total_amount_due
    end
    it "3rd scenario - Checks No Claim History" do
      slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
    end
    it "3rd scenario - PhilHealth benefit claim shall not reflect in Payment details" do
      slmc.click "paymentToggle"
      (slmc.get_text('paymentSection').include? 'Philhealth').should be_false
      (slmc.get_text('paymentSection').include? @@total_actual_benefit_claim1.to_s).should be_false
      slmc.click "paymentToggle"
    end
    it "3rd scenario - Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "3rd scenario - Should be able to search patient in pba" do
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.go_to_philhealth_outpatient_computation.should be_true
      slmc.pba_pin_search(:pin => @@pin)
    end
    it "3rd scenario - Checks No Claim History" do
      slmc.click_latest_philhealth_link_for_outpatient
      slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
    end
    it "3rd scenario - Should be able to View Details" do
      slmc.ph_view_details(:close => true).should == 4
    end
    it "3rd scenario - Should Print Philhealth Form and Prooflist" do
      slmc.ph_print_report.should be_true
    end
    it "4th scenario - Normal Spontaneous Delivery Package, Claim Type: Refund" do
      sleep 6
      slmc.login('jtsalang', @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true
    end
    it "4th Scenario - Input guarantors" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    end
    it "4th Scenario - Order items" do
      @@orders =  @ancillary.merge(@operation)
      @@orders.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => "5979")
      end
    end
    it "4th scenario - Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "4th scenario - Should be able to search patient in pba" do
      sleep 6
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.go_to_philhealth_outpatient_computation.should be_true
      slmc.pba_pin_search(:pin => @@pin)
    end
    it "4th scenario - Philhealth claim type should be refund" do
      slmc.click_latest_philhealth_link_for_outpatient
      slmc.is_element_present'//input[@type="text" and @value="REFUND"]'
    end
    it "4th scenario - Enable Philhealth Information" do
     @@ph = slmc.philhealth_computation(:medical_case_type => "ORDINARY CASE",:with_operation=>true,
          :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "59401", :compute => true)
  end
    it "4th scenario - Check Benefit Summary totals" do
      # set to 0 to initialize variables
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
        if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
        end
        if item[:ph_code] == "PHS03"
          o_amt = item[:rate].to_f * n
          o_amt = item[:rate].to_f * n
          @@comp_operation += o_amt  # total compensable operations
        end
        if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
        end
      end
    end
    it "4th scenario - Checks if the actual charge for drugs/medicine is correct"   do
      @@actual_medicine_charges = @@comp_drugs -  (@promo_discount * @@comp_drugs)
      @@actual_medicine_charges.should == "0.0".to_f
      @@ph[:or_actual_medicine_charges].should == "0.00"
    end
    it "4th scenario - Checks if the actual benefit claim for drugs/medicine is correct" do
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim2 = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f
      end
      @@actual_medicine_benefit_claim2.should == "0.0".to_f
      @@ph[:or_actual_medicine_benefit_claim].should == "0.00"
    end
    it "4th scenario - Checks if the actual charge for xrays, lab and others is correct" do
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
      @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
      @@ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "4th scenario - Checks if the actual lab benefit claim is correct" do
      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
        if (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1.to_f) < 0.00
        @@actual_lab_benefit_claim2 = 0.00
      elsif @@actual_comp_xray_lab_others < (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1.to_f)
        @@actual_lab_benefit_claim2 = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim2 = (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1.to_f)
      end
      @@ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
    end
    it "4th scenario - Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@promo_discount * @@comp_operation)
      @@ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "4th scenario - Checks if the actual operation benefit claim is correct" do
      if slmc.get_value("rvu.code").empty? == false
        @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
        if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
          @@actual_operation_benefit_claim2 = @@actual_operation_charges
        else
          @@actual_operation_benefit_claim2 = @@operation_ph_benefit[:max_amt].to_f
        end
        @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
      else
        @@actual_operation_benefit_claim2 = 0.00
        @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
      end
    end
    it "4th scenario - Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@ph[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "4th scenario - Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim2 = @@actual_medicine_benefit_claim2 + @@actual_lab_benefit_claim2 + @@actual_operation_benefit_claim2
      @@ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim2))
    end
    it "4th scenario - Checks if the maximum benefits are correct" do
      @@ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "4th scenario - Checks if Deduction Claims are correct" do
      @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
      @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
      @@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
    end
    it "4th scenario - Checks if Remaining Benefit Claims are correct" do
      if @@actual_medicine_benefit_claim2 < @@med_ph_benefit[:max_amt].to_f
        @@drugs_remaining_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim2
      else
        @@drugs_remaining_benefit_claim2 = 0.00
      end
      @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim2

      if @@actual_lab_benefit_claim2 < @@lab_remaining_benefit_claim1
        @@lab_remaining_benefit_claim2 = @@lab_remaining_benefit_claim1 - @@actual_lab_benefit_claim2
      else
        @@lab_remaining_benefit_claim2 = 0.00
      end
      @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim2
    end
    it "4th scenario - Checks Claim History" do
      slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
    end
    it "4th scenario - Should be able to View Details" do
      slmc.ph_view_details(:close => true).should == 4
    end
    it "4th scenario - Should be able to Save philhealth computation" do
      slmc.ph_save_computation.should be_true
    end
    it "4th scenario - Should Print Philhealth Form and Prooflist" do
      slmc.ph_print_report.should be_true
    end
    it "5th scenario - Endoscopic Procedure, Claim Type: Accounts Receivable" do#is now treated as normal case
      slmc.login('jtsalang', @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order
      slmc.oss_patient_info(:philhealth => true)
    end
    it "5th Scenario - Input guarantors" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    end
    it "5th Scenario - Order items" do
      @@orders1 =  @ancillary1.merge(@operation1)
      n = 0
      @@orders1.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
      n += 1
      end
    end
    it "5th scenario - Enable Philhealth Information" do
        @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE",:claim_type=>"ACCOUNTS RECEIVABLE",:with_operation=>true,
          :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "10060", :compute => true)
    end
    it "5th scenario - Check Benefit Summary totals" do
      # set to 0 to initialize variables
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

      @@orders1.each do |order,n|
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
        if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
        end
        if item[:ph_code] == "PHS03"
          o_amt = item[:rate].to_f * n
          o_amt = item[:rate].to_f * n
          @@comp_operation += o_amt  # total compensable operations
        end
        if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
        end
      end
    end
    it "5th scenario - Checks if the actual charge for drugs/medicine is correct"   do
      @@actual_medicine_charges = @@comp_drugs -  (@promo_discount * @@comp_drugs)
      @@actual_medicine_charges.should == "0.0".to_f
      @@ph[:actual_medicine_charges].should == "0.00"
    end
    it "5th scenario - Checks if the actual benefit claim for drugs/medicine is correct" do
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim3 = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f
      end
      @@actual_medicine_benefit_claim3.should == "0.0".to_f
      @@ph[:actual_medicine_benefit_claim].should == "0.00"
    end
    it "5th scenario - Checks if the actual charge for xrays, lab and others is correct" do
       total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
      @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
      @@ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "5th scenario - Checks if the actual lab benefit claim is correct" do
      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
      if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2)
        @@actual_lab_benefit_claim3 = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2)
      end
      @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
    end
    it "5th scenario - Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@promo_discount * @@comp_operation)
      @@ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "5th scenario - Checks if the actual operation benefit claim is correct" do
      if slmc.get_value("philHealthBean.rvu.code").empty? == false
        @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
        if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
          @@actual_operation_benefit_claim3 = @@actual_operation_charges
        else
          @@actual_operation_benefit_claim3 = @@operation_ph_benefit[:max_amt].to_f
        end
        @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
      else
        @@actual_operation_benefit_claim3 = 0.00
        @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
      end
    end
    it "5th scenario - Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "5th scenario - Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim3 = @@actual_medicine_benefit_claim3 + @@actual_lab_benefit_claim3 + @@actual_operation_benefit_claim3
      @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim3))
    end
    it "5th scenario - Checks if the maximum benefits are correct" do
      @@ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "5th scenario - Checks if Deduction Claims are correct" do
      @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
      @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
      @@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
    end
    it "5th scenario - Checks if Remaining Benefit Claims are correct" do
      if @@actual_medicine_benefit_claim3 < @@med_ph_benefit[:max_amt].to_f
        @@drugs_remaining_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim3
      else
        @@drugs_remaining_benefit_claim3 = 0.00
      end
      @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim3

    if @@actual_lab_benefit_claim3 < @@lab_remaining_benefit_claim2
        @@lab_remaining_benefit_claim3 = @@lab_remaining_benefit_claim1 - @@actual_lab_benefit_claim3
      else
        @@lab_remaining_benefit_claim3 = 0.00
      end
      @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim3
    end
    it "5th scenario - Checks if Philhealth Claims is displayed in Summary Totals correctly" do
      slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim3))
    end
    it "5th scenario - Checks if Summary Totals > Total Amount Due is equal to Payments > Total Amount Due " do
      slmc.get_total_amount_due.should == slmc.get_billing_total_amount_due
    end
    it "5th scenario - PhilHealth benefit claim shall not reflect in Payment details" do
      slmc.click "paymentToggle"
      (slmc.get_text('paymentSection').include? 'Philhealth').should be_false
      (slmc.get_text('paymentSection').include? @@total_actual_benefit_claim3.to_s).should be_false
      slmc.click "paymentToggle"
    end
    it "5th scenario - Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "5th scenario - Should be able to search patient in pba" do
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.go_to_philhealth_outpatient_computation.should be_true
      slmc.pba_pin_search(:pin => @@pin)
    end
    it "5th scenario - Checks Claim History" do
      slmc.click_latest_philhealth_link_for_outpatient
      slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
    end
    it "5th scenario - Should be able to View Details" do
      slmc.ph_view_details(:close => true).should == 2
    end
    it "5th scenario - Should Print Philhealth Form and Prooflist" do
      slmc.ph_print_report.should be_true
    end
    it "7th scenario - Radiation Oncology, Claim Type: Accounts Receivable" do
      slmc.login('jtsalang', @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order
      slmc.oss_patient_info(:philhealth => true)
    end
    it "7th Scenario - Input guarantors" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    end
    it "7th Scenario - Order items" do
      @@orders2 =  @ancillary2.merge(@operation2)
      n = 0
      @@orders2.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors2[n])
      n += 1
      end
    end
    it "7th scenario - Enable Philhealth Information" do
        @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE",:claim_type=>"ACCOUNTS RECEIVABLE",:with_operation=>true,
          :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "59401", :compute => true) #10060
    end
    it "7th scenario - Check Benefit Summary totals" do
      # set to 0 to initialize variables
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

      @@orders2.each do |order,n|
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
        if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
        end
        if item[:ph_code] == "PHS03"
          o_amt = item[:rate].to_f * n
          o_amt = item[:rate].to_f * n
          @@comp_operation += o_amt  # total compensable operations
        end
        if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
        end
      end
    end
    it "7th scenario - Checks if the actual charge for drugs/medicine is correct" do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@promo_discount * total_drugs)
    @@ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end
    it "7th scenario - Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim3)
      @@actual_medicine_benefit_claim4 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim3)
    end
    @@ph[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
  end
    it "7th scenario - Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab
    @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
  #  @@ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
     @@ph[:actual_lab_charges].should == "0.00"
    

  end
    it "7th scenario - Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3)
      @@actual_lab_benefit_claim4 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3)
    end
    @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
  end
    it "7th scenario - Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @promo_discount))
                                                                                             

    @@ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end
    it "7th scenario - Checks if the actual operation benefit claim is correct" do
       if slmc.get_value("philHealthBean.rvu.code").empty? == false
          @@sessions = 3
          @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
          if @@sessions
              @@actual_operation_benefit_claim4 = @@operation_ph_benefit[:max_amt].to_f * @@sessions
          else
              @@actual_operation_benefit_claim4 = 0.0
          end
      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
      end
  end
    it "7th scenario - Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end
    it "7th scenario - Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim4 = @@actual_medicine_benefit_claim4 + @@actual_lab_benefit_claim4+ @@actual_operation_benefit_claim4
      @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim4))
   end
    it "7th scenario - Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim4 = @@actual_medicine_benefit_claim4 + @@actual_lab_benefit_claim4 + @@actual_operation_benefit_claim4
    @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim4))
   end
    it "7th scenario - Checks if the maximum benefits are correct" do
    @@ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end
    it "7th scenario - Checks if Deduction Claims are correct" do
    @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
    @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
    @@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
  end
    it "7th scenario - Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim4 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim3)
    else
      @@drugs_remaining_benefit_claim4 = 0.0
    end
    @@ph[:drugs_remaining_benefit_claims].to_f.should == (@@drugs_remaining_benefit_claim4)

    if @@actual_lab_benefit_claim4 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim4 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3)
    else
      @@lab_remaining_benefit_claim4 = 0
    end
    @@ph[:lab_remaining_benefit_claims].to_f.should == (@@lab_remaining_benefit_claim4)
  end
    it "7th scenario - Checks if computation of PF claims surgeon is applied correctly" do
    @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.3")
    @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
    @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f
#    if @@ph[:surgeon_benefit_claim] != ("%0.2f" %(@@surgeon_claim))
#      @@ph[:surgeon_benefit_claim].should == ("%0.2f" %(8000.0))
#    else
#      @@ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
@@ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
#    end
  end
    it "7th scenario - Checks if computation of PF claims anesthesiologist is applied correctly" do
    @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB06.6")
    @@anesthesiologist_claim = (@@surgeon_claim * ((@@pf_gp_anesthesiologist[:ph_pcf].to_f) / 100))
#    if @@ph[:anesthesiologist_benefit_claim] != ("%0.2f" %(@@anesthesiologist_claim))
#      @@ph[:anesthesiologist_benefit_claim].should == ("%0.2f" %(8000.0))
#    else
      @@ph[:anesthesiologist_benefit_claim].should == ("%0.2f" %(@@anesthesiologist_claim))
#    end
  end
    it "7th scenario - Checks if Philhealth Claims is displayed in Summary Totals correctly" do
      slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim4))
    end
    it "7th scenario -Checks if Summary Totals > Total Amount Due is equal to Payments > Total Amount Due " do
      slmc.get_total_amount_due.should == slmc.get_billing_total_amount_due
    end
    it "7th scenario - PhilHealth benefit claim shall not reflect in Payment details" do
      slmc.click "paymentToggle"
      (slmc.get_text('paymentSection').include? 'Philhealth').should be_false
      (slmc.get_text('paymentSection').include? @@total_actual_benefit_claim4.to_s).should be_false
      slmc.click "paymentToggle"
    end
    it "7th scenario - Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "7th scenario - Should be able to search patient in pba" do
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.go_to_philhealth_outpatient_computation.should be_true
      slmc.pba_pin_search(:pin => @@pin)
    end
    it "7th scenario - Checks Claim History" do
      slmc.click_latest_philhealth_link_for_outpatient
      slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
    end
    it "7th scenario - Should be able to View Details" do
      slmc.ph_view_details(:close => true).should == 3
    end
    it "7th scenario - Should Print Philhealth Form and Prooflist" do
      slmc.ph_print_report.should be_true
    end
    it "8th scenario - Normal Spontaneous Delivery Package, Claim Type: Refund" do
      slmc.login('jtsalang', @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true
    end
    it "8th Scenario - Input guarantors" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    end
    it "8th Scenario - Order items" do
      @@orders3 =  @ancillary3.merge(@operation3)
      @@orders3.each do |item, q|
      slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => "5979")
      end
    end
    it "8th scenario - Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "8th scenario - Should be able to search patient in pba" do
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.go_to_philhealth_outpatient_computation.should be_true
      slmc.pba_pin_search(:pin => @@pin)
    end
    it "8th scenario - Philhealth claim type should be refund" do
      slmc.click_latest_philhealth_link_for_outpatient
      slmc.is_element_present'//input[@type="text" and @value="REFUND"]'
    end
    it "8th scenario - Enable Philhealth Information" do
     @@ph = slmc.philhealth_computation(:medical_case_type => "ORDINARY CASE",:with_operation=>true,
          :diagnosis => "CHOLERA", :philhealth_id => "12345", :rvu_code => "59400", :compute => true) #10060
  end
    it "8th scenario - Check Benefit Summary totals" do
      # set to 0 to initialize variables
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

      @@orders3.each do |order,n|
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
        if item[:ph_code] == "PHS07"
        n_x_lab_amt = item[:rate].to_f * n
        @@non_comp_xray_lab += n_x_lab_amt # total non compensable xray and lab
        end
        if item[:ph_code] == "PHS03"
          o_amt = item[:rate].to_f * n
          o_amt = item[:rate].to_f * n
          @@comp_operation += o_amt  # total compensable operations
        end
        if item[:ph_code] == "PHS08"
        n_o_amt = item[:rate].to_f * n
        @@non_comp_operation += n_o_amt # total non compensable operations
        end
      end
    end
    it "8th scenario - Checks if the actual charge for drugs/medicine is correct"   do
    @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
    total_drugs = @@comp_drugs + @@non_comp_drugs
    @@actual_medicine_charges = total_drugs - (@promo_discount * total_drugs)
    @@ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
  end
    it "8th scenario - Checks if the actual benefit claim for drugs/medicine is correct" do
    @@comp_drugs_total = @@comp_drugs - (@@comp_drugs * @promo_discount)
    if @@comp_drugs_total < @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim4)
      @@actual_medicine_benefit_claim5 = @@comp_drugs_total
    else
      @@actual_medicine_benefit_claim5 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim4)
    end
    @@ph[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
  end
    it "8th scenario - Checks if the actual charge for xrays, lab and others is correct" do
    total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab # + @@comp_operation
    @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
    @@ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
  end
    it "8th scenario - Checks if the actual lab benefit claim is correct" do
    @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
    @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
    if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4)
      @@actual_lab_benefit_claim5 = @@actual_comp_xray_lab_others
    else
      @@actual_lab_benefit_claim5 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4)
    end
    @@ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim5))
  end
    it "8th scenario - Checks if the actual charge for operation is correct" do
    @@actual_operation_charges = @@comp_operation - (@@comp_operation * @promo_discount) + (@@non_comp_operation - (@@non_comp_operation * @promo_discount))
    @@ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
  end
    it "8th scenario - Checks if the actual operation benefit claim is correct" do
       if slmc.get_value("rvu.code").empty? == false
          @@sessions = 3
          @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04")
          if @@sessions
              @@actual_operation_benefit_claim5 = @@operation_ph_benefit[:max_amt].to_f * @@sessions
          else
              @@actual_operation_benefit_claim5 = 0.0
          end
      @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
      end
  end
    it "8th scenario - Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@ph[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
  end
    it "8th scenario - Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim5 = @@actual_medicine_benefit_claim5 + @@actual_lab_benefit_claim5 + @@actual_operation_benefit_claim5
      @@ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim5))
   end
    it "8th scenario - Checks if the total actual benefit claim is correct" do
    @@total_actual_benefit_claim5 = @@actual_medicine_benefit_claim5 + @@actual_lab_benefit_claim5 + @@actual_operation_benefit_claim5
    @@ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim5))
   end
    it "8th scenario - Checks if the maximum benefits are correct" do
    @@ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
    @@ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
  end
    it "8th scenario - Checks if Deduction Claims are correct" do
    @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
    @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim5))
    @@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
  end
    it "8th scenario - Checks if Remaining Benefit Claims are correct" do
    if @@actual_medicine_benefit_claim5 < @@med_ph_benefit[:max_amt].to_f
      @@drugs_remaining_benefit_claim5 = @@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim4)
    else
      @@drugs_remaining_benefit_claim5 = 0.0
    end
    @@ph[:drugs_remaining_benefit_claims].to_f.should == (@@drugs_remaining_benefit_claim5)

    if @@actual_lab_benefit_claim5 < @@lab_ph_benefit[:max_amt].to_f
      @@lab_remaining_benefit_claim5 = @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4)
    else
      @@lab_remaining_benefit_claim5 = 0
    end
    @@ph[:lab_remaining_benefit_claims].to_f.should == (@@lab_remaining_benefit_claim5)
  end
    it "8th scenario - Checks Claim History" do
      slmc.get_text(Locators::OSS_Philhealth.claims_history).should_not == "Nothing found to display."
    end
    it "8th scenario - Should be able to View Details" do
      slmc.ph_view_details(:close => true).should == 4
    end
    it "8th scenario - Should be able to Save philhealth computation" do
      slmc.ph_save_computation.should be_true
    end
    it "8th scenario - Should Print Philhealth Form and Prooflist" do
      slmc.ph_print_report.should be_true
    end


end