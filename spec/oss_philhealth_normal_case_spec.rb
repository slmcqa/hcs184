require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: OSS - Philhealth Module Test - Normal Case (1st - 9th Availment)" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
#    @selenium_driver.evaluate_rooms_for_admission('0164','RCHSP')
    @selenium_driver.start_new_browser_session
    @ph_patient = Admission.generate_data
    #@oss_user = USERS['oss_philhealth_normal_spec_user1']
    @oss_user = "jtsalang"
    @pba_user = "ldcastro"
    @password = "123qweuser"
    @promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@ph_patient[:age])
    @discount = 30.0
    # @all_oss_items = {"010000317" =>1, "010000212" =>1, "010001039"=>1, "010000211"=>1,"010000160"=>1, "010000008"=>1, "010000003"=>1,  "010000600"=>1, "010000611"=>1}
    #items to be ordered
    #1st availment
    @ancillary1 =
      {
      "010000317" => 1, #QUALITATIVE PROPOXYPHENE
      "010000212" => 1, #ACID PHOSPHATASE
      "010001039" => 1, #URINALYSIS
      "010000211" => 1 #ACETAMINOPHEN
    }
    @operation1 = {"010000160" => 1} #POLARIZING MICROSCOPY
    @doctors = ["6726","0126","6793","7065","7065"]
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

    it "Creates patient for OSS transactions" do
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => "test")
      slmc.click_outpatient_registration.should be_true
      @@oss_pin = slmc.oss_outpatient_registration(@ph_patient).should be_true
      @@oss_pin.should be_true
      @@pin = @@oss_pin.gsub(' ', '')
    end

    ## 1st AVAILMENT
    ## Account Class: Individual
    ## Case Type: Ordinary Case
    ## Claim Type: Accounts Receivable
    ## With Operation: No
    ## Diagnosis: DENGUE HEMORRHAGIC FEVER (A91)

    it "1st Availment: Searches and adds order items in the OSS outpatient order page" do
      sleep 6
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true

      #add all items to be ordered
      @@orders1 =  @ancillary1.merge(@operation1)
      @@orders1.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => '0126')
      end
    end
    it "1st Availment: Add guarantor and enable philhealth patient information" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
      slmc.oss_patient_info(:philhealth => true)
      @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "A91", :philhealth_id => "12345", :compute => true,:case_rate_type =>"SURGICAL", :rvu_code => "11444" )
    end
    it "1st Availment: Check Benefit Summary totals" do
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
#      sam = @@orders1.count
#      puts sam
      @@orders1.each do |order,n|
#      while sam != 0
#            order,n = @@orders1[0]
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
          x_lab_amt = item[:rate].to_f * n
          @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
        end
        if item[:ph_code] == "PHS03"
          o_amt = item[:rate].to_f * n
          o_amt = item[:rate].to_f * n
          @@comp_operation += o_amt  # total compensable operations
        end
        if item[:ph_code] == "PHS10"
          s_amt = item[:rate].to_f * n
          @@non_comp_supplies += s_amt  # total non compensable supplies
        end
      end
    end
    it "1st Availment: Checks if the actual charge for drugs/medicine is correct"   do
      # actual medical charges computation
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs -  (@promo_discount * total_drugs)
      @@ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "1st Availment: Checks if the actual benefit claim for drugs/medicine is correct" do
      # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim1 = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f
      end
      @@ph[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
    end
    it "1st Availment: Checks if the actual charge for xrays, lab and others is correct" do
      # compensible + noncompensible xray lab + noncompensible supplies(010000211)
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
      @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
      @@ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "1st Availment: Checks if the actual lab benefit claim is correct" do
      # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
####      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
####      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
####      if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f
####        @@actual_lab_benefit_claim1 = @@actual_comp_xray_lab_others
####      else
####        @@actual_lab_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f
####      end
####      @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim1))

    @@ph[:actual_lab_benefit_claim].should == "0.00"

    end
    it "1st Availment: Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@promo_discount * @@comp_operation)
      @@ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "1st Availment: Checks if the actual operation benefit claim is correct" do
####      if slmc.get_value("philHealthBean.rvu.code").empty? == false
####        @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
####        if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
####          @@actual_operation_benefit_claim1 = @@actual_operation_charges
####        else
####          @@actual_operation_benefit_claim1 = @@operation_ph_benefit[:max_amt].to_f
####        end
####        @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
####      else
                @@actual_operation_benefit_claim1 = 0.00
####        @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
####      end
    end
    it "1st Availment: Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "1st Availment: Checks if the total actual benefit claim is correct" do
#      @@total_actual_benefit_claim1 = @@actual_medicine_benefit_claim1 + @@actual_lab_benefit_claim1 + @@actual_operation_benefit_claim1
#      @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim1))
@@ph[:total_actual_benefit_claim].should == "3100.00"
@@total_actual_benefit_claim1 = "3100.00"

    end
    it "1st Availment: Checks if the maximum benefits are correct" do
#      @@ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
#      @@ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "1st Availment: Checks if Deduction Claims are correct" do
#      @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim1))
#      @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim1))
#      @@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim1))
#




    end
    it "1st Availment: Checks if Remaining Benefit Claims are correct" do
#      if @@actual_medicine_benefit_claim1 < @@med_ph_benefit[:max_amt].to_f
#        @@drugs_remaining_benefit_claim1 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim1
#      else
#        @@drugs_remaining_benefit_claim1 = 0.00
#      end
#      @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim1
#
#      if @@actual_lab_benefit_claim1 < @@lab_ph_benefit[:max_amt].to_f
#        @@lab_remaining_benefit_claim1 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1
#      else
#        @@lab_remaining_benefit_claim1 = 0.00
#      end
#      @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim1
    end
    it "1st Availment: Checks if Philhealth Claims is displayed in Summary Totals correctly" do
      #slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim1))
    end
    it "1st Availment: Checks if Summary Totals > Total Amount Due is equal to Payments > Total Amount Due " do
    slmc.get_total_amount_due.should == slmc.get_billing_total_amount_due
    end
    it "1st Availment: Checks No Claim History" do
      slmc.get_text(Locators::OSS_Philhealth.claims_history).should == "Nothing found to display."
    end
    it "1st Availment: PhilHealth benefit claim shall not reflect in Payment details" do
      slmc.click "paymentToggle"
      sleep 5
      (slmc.get_text('paymentSection').include? 'Philhealth').should be_false
      (slmc.get_text('paymentSection').include? @@total_actual_benefit_claim1.to_s).should be_false
      slmc.click "paymentToggle"
      sleep 5
    end
    it "1st Availment: Proceed with payment successfully" do
      if @promo_discount == 0.2
        slmc.type'seniorIdNumber','123456'
      end
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
     puts amount
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end

    ## 2nd AVAILMENT
    ## Account Class: Individual
    ## Case Type: Ordinary Case
    ## Claim Type: Refund
    ## With Operation: No
    ## Diagnosis: DENGUE HEMORRHAGIC FEVER (A91)

    it "2nd Availment: Searches and adds order items in the OSS outpatient order page" do
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true

      @ancillary2 =
        {
        "010000317" => 1, #QUALITATIVE PROPOXYPHENE
        "010000212" => 1, #ACID PHOSPHATASE
        "010001039" => 1  #URINALYSIS
      }
      @operation2 = {"010000160" => 1} #POLARIZING MICROSCOPY

      #add all items to be ordered
      @@orders2 =  @ancillary2.merge(@operation2)
      @@orders2.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => '0126').should be_true
      end
    end
    it "2nd Availment: Add guarantor information" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    end
    it "2nd Availment: Proceed with payment successfully" do
      amount =  slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "2nd Availment: PBA user login and verify submitted transaction from the PhilHealth Outpatient Computation page" do
      sleep 6
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.go_to_philhealth_outpatient_computation.should be_true
      slmc.pba_pin_search(:pin => @@pin).should be_true
    end
    it "2nd Availment: Click Philhealth link and input Philhealth details" do
      slmc.click_latest_philhealth_link_for_outpatient
      Database.connect
      t = "SELECT RVS_CODE FROM SLMC.REF_PBA_PH_CASE_RATE WHERE CATARACT_SURGERY IS NULL AND EXEMPT_SPC_RULE IS NULL AND STATUS= 'A' AND RVS_CODE NOT IN
              (SELECT A.RVU_CODE FROM SLMC.TXN_PBA_PH_HDR A JOIN SLMC.TXN_ADM_ENCOUNTER B ON A.VISIT_NO = B.VISIT_NO WHERE A.STATUS = 'F' AND B.PIN = '#{@@pin}')#"
      rate = Database.select_last_statement t
      Database.logoff
      puts rate
     @@mycase_rate =  rate

    @@ph = slmc.philhealth_computation(:medical_case_type => "ORDINARY CASE", :diagnosis => "A91", :philhealth_id => "12345", :compute => true,  :rvu_code => @@mycase_rate)
   # @@ph = slmc.oss_input_philhealth(:medical_case_type => "ORDINARY CASE", :diagnosis => "A91", :philhealth_id => "12345", :compute => true,  :rvu_code => @@mycase_rate)
    end
    it "sa" do
      puts @@ph[:actual_medicine_charges]
      puts @@ph[:actual_medicine_benefit_claim]
      puts @@ph[:actual_lab_charges]
      puts @@ph[:actual_lab_benefit_claim]
      puts @@ph[:actual_operation_charges]
      puts @@ph[:actual_operation_benefit_claim]
      puts @@ph[:total_actual_charges]
      puts @@ph[:total_actual_benefit_claim]
    end
    it "sa" do
      puts @@ph[:er_max_benefit_drugs]
      puts @@ph[:er_max_benefit_xray_lab_others]
    end
    it "sa" do
      puts @@ph[:drugs_deduction_claims]
      puts @@ph[:lab_deduction_claims]
      puts @@ph[:drugs_remaining_benefit_claims]
      puts @@ph[:lab_remaining_benefit_claim]      
    end
    it "2nd Availment: Check Benefit Summary totals" do
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
          x_lab_amt = item[:rate].to_f * n
          @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
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
    it "2nd Availment: Checks if the actual charge for drugs/medicine is correct"   do
      # actual medical charges computation
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs -  (@promo_discount * total_drugs)
      @@ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "2nd Availment: Checks if the actual benefit claim for drugs/medicine is correct" do
      # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
#      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB02")
#      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
#        @@actual_medicine_benefit_claim2 = @@actual_medicine_charges
#      else
#        @@actual_medicine_benefit_claim2 = @@med_ph_benefit[:max_amt].to_f
#      end
#      @@ph[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
@@ph[:or_actual_medicine_benefit_claim].should == "0.00"
    end
    it "2nd Availment: Checks if the actual charge for xrays, lab and others is correct" do
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
      @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
      @@ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "2nd Availment: Checks if the actual lab benefit claim is correct" do
      # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
###      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
###      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB03")
###
###      ## consider @@actual_lab_benefit_claim1 in BENEFIT CLAIM computation since 1st and 2nd availment has the same diagnosis - DENGUE HEMORRHAGIC FEVER (A91)
###      if (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1.to_f) < 0.00
###        @@actual_lab_benefit_claim2 = 0.00
###      elsif @@actual_comp_xray_lab_others < (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1.to_f)
###        @@actual_lab_benefit_claim2 = @@actual_comp_xray_lab_others
###      else
###        @@actual_lab_benefit_claim2 = (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim1.to_f)
###      end
###      @@ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim2))

        @@actual_lab_benefit_claim2 = "0.00"
        @@ph[:or_actual_lab_benefit_claim].should == "0.00"
    end
    it "2nd Availment: Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@promo_discount * @@comp_operation)
      @@ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "2nd Availment: Checks if the actual operation benefit claim is correct" do
####      if slmc.get_value("rvu.code").empty? == false
####        @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("ORD_CSE","PHB04.1")
####        if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
####          @@actual_operation_benefit_claim2 = @@actual_operation_charges
####        else
####          @@actual_operation_benefit_claim2 = @@operation_ph_benefit[:max_amt].to_f
####        end
####        @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
####      else
####        @@actual_operation_benefit_claim2 = 0.00
####        @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
####      end
              @@actual_operation_benefit_claim2 = 0.00
              @@ph[:or_actual_operation_benefit_claim].should == "0.00"
    end
    it "2nd Availment: Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
#      @@ph[:er_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    ((slmc.truncate_to((@@ph[:or_total_actual_charges].to_f - total_actual_charges),2).to_f).abs).should <= 0.02
    end
    it "2nd Availment: Checks if the total actual benefit claim is correct" do
#      @@total_actual_benefit_claim2 = @@actual_medicine_benefit_claim2 + @@actual_lab_benefit_claim2 + @@actual_operation_benefit_claim2
#      @@ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim2))
#
  #   @@mycase_rate =  "66983"
     Database.connect
            t = "SELECT TO_CHAR(PF_AMOUNT) FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
            pf = Database.select_last_statement t
     Database.logoff
     Database.connect
            t = "SELECT TO_CHAR(RATE)  FROM REF_PBA_PH_CASE_RATE WHERE RVS_CODE ='#{@@mycase_rate}'"
            rate = Database.select_last_statement t
     Database.logoff
     mm = @@ph[:or_total_actual_benefit_claim].to_f
     puts mm
     puts rate
     puts pf
     pf = pf.to_i
     rate = rate.to_i
#
#     @@comp_drugs
#     @@comp_xray_lab
#     @@comp_operation
#     @@comp_others
#     @@comp_supplies
#     @@non_comp_drugs
#     @@non_comp_drugs_mrp_tag
#     @@non_comp_xray_lab
#     @@non_comp_operation
#     @@non_comp_others
#     @@non_comp_supplies

     @@total_actual_benefit_claim = (rate - pf )#REF_PBA_PH_CASE_RATE.CASE_RATE_NO = '5381'
     @@physician_pf_claim = pf
     puts "@@total_actual_benefit_claim - #{@@total_actual_benefit_claim}"
     puts "@@ph1[:total_actual_benefit_claim #{mm}"
     ((slmc.truncate_to((@@ph[:or_total_actual_benefit_claim].to_f - @@total_actual_benefit_claim),2).to_f).abs).should <= 0.01
     ((slmc.truncate_to((@@ph[:or_physician_fee].to_f - @@physician_pf_claim),2).to_f).abs).should <= 0.01

    end
    it "2nd Availment: Checks if the maximum benefits are correct" do
#      @@ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
#      @@ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "2nd Availment: Checks if Deduction Claims are correct" do
#      @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim2))
#      @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim2))
      #@@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
    end
    it "2nd Availment: Checks if Remaining Benefit Claims are correct" do
      ## consider @@actual_medicine_benefit_claim1 in REMAINING BENEFIT CLAIM computation since 1st and 2nd availment has the same diagnosis - DENGUE HEMORRHAGIC FEVER (A91)
#      if @@actual_medicine_benefit_claim2 < @@drugs_remaining_benefit_claim1
#        @@drugs_remaining_benefit_claim2 = @@drugs_remaining_benefit_claim1 - @@actual_medicine_benefit_claim2
#      else
#        @@drugs_remaining_benefit_claim2 = 0.00
#      end
#      @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim2
#      ## consider @@actual_lab_benefit_claim1 in REMAINING BENEFIT CLAIM computation since 1st and 2nd availment has the same diagnosis - DENGUE HEMORRHAGIC FEVER (A91)
#      if @@actual_lab_benefit_claim2 < @@lab_remaining_benefit_claim1
#        @@lab_remaining_benefit_claim2 = @@lab_remaining_benefit_claim1 - @@actual_lab_benefit_claim2
#      else
#        @@lab_remaining_benefit_claim2 = 0.00
#      end
#      @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim2
    end
    it "2nd Availment: Checks if clicking 'Save' button saves the philhealth computation as ESTIMATE " do
      slmc.ph_save_computation
      slmc.is_text_present("ESTIMATE").should be_true
    end
    it "2nd Availment: Checks if clicking 'View details' button displays of order details" do
      slmc.ph_view_details(:close => true).should == 4
    end
    it "2nd Availment: Checks Claim History" do
      sleep 6
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin).should be_true
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
      slmc.get_text(Locators::OSS_Philhealth.first_total_claim_history).gsub(',','').should == ("%0.2f" %(@@total_actual_benefit_claim1))
    end

    ## 3rd Availment
    ## Account Class: Individual
    ## Case Type: Intensive Case
    ## Claim Type: Accounts Receivable
    ## With Operation: No
    ## Diagnosis: CALIFORNIA ENCEPHALITIS (A83.5)


    it "3rd Availment: Searches and adds order items in the OSS outpatient order page" do
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true

      @ancillary3 =
        {
        "010000317" => 1, #QUALITATIVE PROPOXYPHENE
        "010000212" => 1, #ACID PHOSPHATASE
        "010001039" => 1, #URINALYSIS
        "010000211" => 1 #ACETAMINOPHEN
      }
      @operation3 = {"010000160" => 1} #POLARIZING MICROSCOPY

      #add all items to be ordered
      @@orders3 =  @ancillary3.merge(@operation3)
      @@orders3.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => '0126')
      end
    end
    it "3rd Availment: Add guarantor and enable philhealth patient information" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
      slmc.oss_patient_info(:philhealth => true)
      @@ph = slmc.oss_input_philhealth(:case_type => "INTENSIVE CASE", :diagnosis => "A83.5", :philhealth_id => "12345", :compute => true, :rvu_code=>"11446")
    end
    it "3rd Availment: Check Benefit Summary totals" do
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
          x_lab_amt = item[:rate].to_f * n
          @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
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
    it "3rd Availment: Checks if the actual charge for drugs/medicine is correct"   do
      # actual medical charges computation
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs -  (@promo_discount * total_drugs)
      @@ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "3rd Availment: Checks if the actual benefit claim for drugs/medicine is correct" do
      # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
#      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
#      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
#        @@actual_medicine_benefit_claim3 = @@actual_medicine_charges
#      else
#        @@actual_medicine_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f
#      end
      @@actual_medicine_benefit_claim3 = 0.00
      @@ph[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
      
    end
    it "3rd Availment: Checks if the actual charge for xrays, lab and others is correct" do
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
      @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
      @@ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "3rd Availment: Checks if the actual lab benefit claim is correct" do
      # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
#      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
#      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")
#      #    if ( @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1.to_f + @@actual_lab_benefit_claim2.to_f)) < 0.0
#      #      @@actual_lab_benefit_claim3 = 0.00
#      if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f #- (@@actual_lab_benefit_claim1.to_f + @@actual_lab_benefit_claim2.to_f))
#        @@actual_lab_benefit_claim3 = @@actual_comp_xray_lab_others
#      else
#        @@actual_lab_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f #- (@@actual_lab_benefit_claim1.to_f + @@actual_lab_benefit_claim2.to_f))
#      end
      @@actual_lab_benefit_claim3 = "0.00"
      @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
    end
    it "3rd Availment: Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@promo_discount * @@comp_operation)
      @@ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "3rd Availment: Checks if the actual operation benefit claim is correct" do
#      if slmc.get_value("philHealthBean.rvu.code").empty? == false
#        @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04.1")
#        if @@actual_operation_charges < @@operation_ph_benefit[:max_amt].to_f
#          @@actual_operation_benefit_claim3 = @@actual_operation_charges
#        else
#          @@actual_operation_benefit_claim3 = @@operation_ph_benefit[:max_amt].to_f
#        end
#        @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
#      else
        @@actual_operation_benefit_claim3 = 0.00
        @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
     # end
    end
    it "3rd Availment: Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "3rd Availment: Checks if the total actual benefit claim is correct" do
#      @@total_actual_benefit_claim3 = @@actual_medicine_benefit_claim3 + @@actual_lab_benefit_claim3 + @@actual_operation_benefit_claim3
#      @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim3))
    end
    it "3rd Availment: Checks if the maximum benefits are correct" do
      @@ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "3rd Availment: Checks if Deduction Claims are correct" do
      @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim3))
      @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim3))
      #@@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim3))
    end
    it "3rd Availment: Checks if Remaining Benefit Claims are correct" do
      if @@actual_medicine_benefit_claim3 < @@med_ph_benefit[:max_amt].to_f
        @@drugs_remaining_benefit_claim3 = @@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim3
      else
        @@drugs_remaining_benefit_claim3 = 0.00
      end
      ((slmc.truncate_to((@@ph[:drugs_remaining_benefit_claims].to_f - @@drugs_remaining_benefit_claim3),2).to_f).abs).should <= 0.02


      if @@actual_lab_benefit_claim3 < @@lab_ph_benefit[:max_amt].to_f #- (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2))
        @@lab_remaining_benefit_claim3 = @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3
      else
        @@lab_remaining_benefit_claim3 = 0.00
      end
      ((slmc.truncate_to((@@ph[:lab_remaining_benefit_claims].to_f - @@lab_remaining_benefit_claim3),2).to_f).abs).should <= 0.02
    end
    it "3rd Availment: Checks if Philhealth Claims is displayed in Summary Totals correctly" do
      (slmc.get_philhealth_claims_amount).to_f.should == ("%0.2f" %(@@total_actual_benefit_claim3 - 0.01)).to_f
    end
    it "3rd Availment: Checks if Summary Totals > Total Amount Due is equal to Payments > Total Amount Due " do
    slmc.get_total_amount_due.should == slmc.get_billing_total_amount_due
    end
    it "3rd Availment: PhilHealth benefit claim shall not reflect in Payment details" do
      slmc.click "paymentToggle"
      (slmc.get_text('paymentSection').include? 'Philhealth').should be_false
      (slmc.get_text('paymentSection').include? @@total_actual_benefit_claim3.to_s).should be_false
      slmc.click "paymentToggle"
    end
    it "3rd Availment: Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "3rd Availment: Checks Claim History" do
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
      slmc.get_text(Locators::OSS_Philhealth.second_total_claim_history).gsub(',','').should == ("%0.2f" %(@@total_actual_benefit_claim2))
    end

    ## 4th Availment
    ## Account Class: Individual
    ## Case Type: Intensive Case
    ## Claim Type: Refund
    ## With Operation: No
    ## Diagnosis: CALIFORNIA ENCEPHALITIS (A83.5)

    it "4th Availment: Searches and adds order items in the OSS outpatient order page" do
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true

      @ancillary4 =
        {
        "010000008" => 1, #BONE IMAGING
        "010000003" => 1  #ADRENOMEDULLARY IMAGING-M-IBG
      }
      @operation4 = {"010000160" => 1} #POLARIZING MICROSCOPY

      #add all items to be ordered
      @@orders4 =  @ancillary4.merge(@operation4)
      @@orders4.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => '0126')
      end
    end
    it "4th Availment: Add guarantor information" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    end
    it "4th Availment: Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "4th Availment: PBA user login and verify submitted transaction from the PhilHealth Outpatient Computation page" do
      sleep 6
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.go_to_philhealth_outpatient_computation.should be_true
      slmc.pba_pin_search(:pin => @@pin).should be_true
    end
    it "4th Availment: Click Philhealth link and input Philhealth details" do
      slmc.click_latest_philhealth_link_for_outpatient
      @@ph = slmc.philhealth_computation(:medical_case_type => "INTENSIVE CASE", :diagnosis => "A83.5", :philhealth_id => "12345", :compute => true)
    end
    it "4th Availment: Check Benefit Summary totals" do
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

      @@orders4.each do |order,n|
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
          x_lab_amt = item[:rate].to_f * n
          @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
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
    it "4th Availment: Checks if the actual charge for drugs/medicine is correct"   do
      # actual medical charges computation
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs -  (@promo_discount * total_drugs)
      @@ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "4th Availment: Checks if the actual benefit claim for drugs/medicine is correct" do
      # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB02")
      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim4 = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim4 = @@med_ph_benefit[:max_amt].to_f
      end
      @@ph[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
    end
    it "4th Availment: Checks if the actual charge for xrays, lab and others is correct" do
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
      @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
      @@ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "4th Availment: Checks if the actual lab benefit claim is correct" do
      # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB03")

      ## consider @@actual_lab_benefit_claim3 in BENEFIT CLAIM computation since 3rd and 4th availment has the same diagnosis - CALIFORNIA ENCEPHALITIS (A83.5)
      if ( @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3.to_f) < 0.0
        @@actual_lab_benefit_claim4 = 0.00
      elsif @@actual_comp_xray_lab_others < ( @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3.to_f )
        @@actual_lab_benefit_claim4 = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim4 = ( @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim3.to_f )
      end
      @@ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
    end
    it "4th Availment: Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@promo_discount * @@comp_operation)
      @@ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "4th Availment: Checks if the actual operation benefit claim is correct" do
      if slmc.get_value("rvu.code").empty? == false
        puts"4th Availm"
        @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("INT_CSE","PHB04.1")
        if @@actual_operation_charges < @@operation_ph_benefit[:min_amt].to_f
          @@actual_operation_benefit_claim4 = @@actual_operation_charges
        else
          @@actual_operation_benefit_claim4 = @@operation_ph_benefit[:min_amt].to_f
        end
        @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
      else
        @@actual_operation_benefit_claim4 = 0.00
        @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim4))
      end
    end
    it "4th Availment: Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@ph[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "4th Availment: Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim4 = @@actual_medicine_benefit_claim4 + @@actual_lab_benefit_claim4 + @@actual_operation_benefit_claim4
      @@ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim4))
    end
    it "4th Availment: Checks if the maximum benefits are correct" do
      @@ph[:or_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@ph[:or_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "4th Availment: Checks if Deduction Claims are correct" do
      @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim4))
      @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim4))
      #@@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim2))
    end
    it "4th Availment: Checks if Remaining Benefit Claims are correct" do
      ## consider @@actual_medicine_benefit_claim3 in REMAINING BENEFIT CLAIM computation since 3rd and 4th availment has the same diagnosis - CALIFORNIA ENCEPHALITIS (A83.5)
      if @@actual_medicine_benefit_claim4 < (@@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim3)
        @@drugs_remaining_benefit_claim4 = (@@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3  + @@actual_medicine_benefit_claim4))
      else
        @@drugs_remaining_benefit_claim4 = 0.00
      end
      @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim4

      ## consider @@actual_lab_benefit_claim3 in REMAINING BENEFIT CLAIM computation since 3rd and 4th availment has the same diagnosis - CALIFORNIA ENCEPHALITIS (A83.5)
      if @@actual_lab_benefit_claim4 < @@lab_remaining_benefit_claim3
        @@lab_remaining_benefit_claim4 = @@lab_remaining_benefit_claim2 - @@actual_lab_benefit_claim3
      else
        @@lab_remaining_benefit_claim4 = 0.00
      end
      @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim4
    end
    it "4th Availment: Checks if clicking 'Save' button saves the philhealth computation as ESTIMATE " do
      slmc.ph_save_computation
      slmc.is_text_present("ESTIMATE").should be_true
    end
    it "4th Availment: Checks if clicking 'View details' button displays of order details" do
      slmc.ph_view_details(:close => true).should == 3
    end
    it "4th Availment: Checks Claim History" do
      sleep 6
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin).should be_true
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
      sleep 10
      slmc.get_text(Locators::OSS_Philhealth.third_total_claim_history).gsub(',','').should == ("%0.2f" %(@@total_actual_benefit_claim3))
    end

    ## 5th Availment
    ## Account Class: Individual
    ## Case Type: Catastrophic Case
    ## Claim Type: Accounts Receivable
    ## With Operation: Yes
    ## Diagnosis: CALIFORNIA ENCEPHALITIS (A83.5)

    it "5th Availment: Searches and adds order items in the OSS outpatient order page" do
      sleep 6
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true

      @ancillary3 =
        {
        "010000008" => 1, #BONE IMAGING
        "010000003" => 1, #ADRENOMEDULLARY IMAGING-M-IBG
        "010000600" => 1, #TISSUE CHOROMOGRANIN A
        "010000611" => 1  #TISSUE CYTOKERATIN 7
      }
      @operation3 = {"010000160" => 1} #POLARIZING MICROSCOPY

      #add all items to be ordered
      @@orders3 =  @ancillary3.merge(@operation3)
      n = 0
      @@orders3.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
        n += 1
      end
    end
    it "5th Availment: Add guarantor and enable philhealth patient information" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
      slmc.oss_patient_info(:philhealth => true)
      @@ph = slmc.oss_input_philhealth(:case_type => "CATASTROPHIC CASE", :diagnosis => "A83.5", :philhealth_id => "12345",:with_operation=>true, :rvu_code => "29358", :compute => true)
    end
    it "5th Availment: Check Benefit Summary totals" do
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
          x_lab_amt = item[:rate].to_f * n
          @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
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
    it "5th Availment: Checks if the actual charge for drugs/medicine is correct"   do
      # actual medical charges computation
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs -  (@promo_discount * total_drugs)
      @@ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "5th Availment: Checks if the actual benefit claim for drugs/medicine is correct" do
      # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim5 = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim5 = @@med_ph_benefit[:max_amt].to_f
      end
      @@ph[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
    end
    it "5th Availment: Checks if the actual charge for xrays, lab and others is correct" do
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
      @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
      @@ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "5th Availment: Checks if the actual lab benefit claim is correct" do
      # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")

      ## consider @@actual_lab_benefit_claim3 and @@actual_lab_benefit_claim4 in BENEFIT CLAIM computation since 3rd, 4th and 5th availment has the same diagnosis - Diagnosis: CALIFORNIA ENCEPHALITIS (A83.5)
      if ( @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4)) < 0.0
        @@actual_lab_benefit_claim5 = 0.00
      elsif @@actual_comp_xray_lab_others < ( @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4))
        @@actual_lab_benefit_claim5 = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim5 = ( @@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4))
      end
      @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim5))
    end
    it "5th Availment: Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@promo_discount * @@comp_operation)
      @@ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "5th Availment: Checks if the actual operation benefit claim is correct" do
      if slmc.get_value("philHealthBean.rvu.code").empty? == false
          @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB04")
          if @@actual_operation_charges < @@operation_ph_benefit[:min_amt].to_f
            @@actual_operation_benefit_claim5 = @@actual_operation_charges
          else
            @@actual_operation_benefit_claim5 = @@operation_ph_benefit[:min_amt].to_f
          end
          @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
      else
        @@actual_operation_benefit_claim5 = 0.00
        @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
      end
#      @@actual_operation_benefit_claim5 = 1500.00
    #  @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
#      @@actual_operation_benefit_claim5 = 1500.00 # 137.5 environment only
#      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
    end
    it "5th Availment: Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "5th Availment: Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim5 = @@actual_medicine_benefit_claim5 + @@actual_lab_benefit_claim5 + @@actual_operation_benefit_claim5
      @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim5))
    end
    it "5th Availment: Checks if the maximum benefits are correct" do
      @@ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "5th Availment: Checks if Deduction Claims are correct" do
      @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim5))
      @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim5))
      @@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim5))
    end
    it "5th Availment: Checks if Remaining Benefit Claims are correct" do
      ## consider @@actual_medicine_benefit_claim3 and @@actual_medicine_benefit_claim4 in REMAINING BENEFIT CLAIM computation since 3rd, 4th and 5th availment has the same diagnosis - Diagnosis: CALIFORNIA ENCEPHALITIS (A83.5)
      if @@actual_medicine_benefit_claim5 < (@@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim4))
        @@drugs_remaining_benefit_claim5 = (@@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim4  + @@actual_medicine_benefit_claim5))
      else
        @@drugs_remaining_benefit_claim5 = 0.00
      end
      @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim5

      ## consider @@actual_lab_benefit_claim3 and @@actual_lab_benefit_claim4 in REMAINING BENEFIT CLAIM computation since 3rd, 4th and 5th availment has the same diagnosis - Diagnosis: CALIFORNIA ENCEPHALITIS (A83.5)
      if @@actual_lab_benefit_claim5 < (@@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4))
        @@lab_remaining_benefit_claim5 = (@@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim5))
      else
        @@lab_remaining_benefit_claim5 = 0.00
      end
      @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim5
    end
    it "5th Availment: Checks if PF Claims for surgeon is correct" do
      @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.3")
      @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("29358")
      @@surgeon_claim = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f

      @@ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim))
    end
    it "5th Availment: Checks if PF Claims for anesthesiologist is correct" do
      @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.6")
      anesthesiologist_claim = (@@surgeon_claim.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))

      @@ph[:anesthesiologist_benefit_claim].should == ("%0.2f" %(anesthesiologist_claim))
    end
    it "5th Availment: Checks if Philhealth Claims is displayed in Summary Totals correctly" do
      slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim5))
    end
    it "5th Availment: Checks if Summary Totals > Total Amount Due is equal to Payments > Total Amount Due " do
    slmc.get_total_amount_due.should == slmc.get_billing_total_amount_due
    end
    it "5th Availment: PhilHealth benefit claim shall not reflect in Payment details" do
      slmc.click "paymentToggle"
      (slmc.get_text('paymentSection').include? 'Philhealth').should be_false
      (slmc.get_text('paymentSection').include? @@total_actual_benefit_claim5.to_s).should be_false
      slmc.click "paymentToggle"
    end
    it "5th Availment: Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "5th Availment: Checks Claim History" do
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
      slmc.get_text(Locators::OSS_Philhealth.fourth_total_claim_history).gsub(',','').should == ("%0.2f" %(@@total_actual_benefit_claim4))
    end

    ## 6th Availment
    ## Account Class: Individual
    ## Case Type: Catastrophic Case
    ## Claim Type: Refund
    ## With Operation: Yes
    ## Diagnosis: AMEBIC INFECTION OF OTHER SITES (A06.8)

    it "6th Availment: Searches and adds order items in the OSS outpatient order page" do
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true

      @ancillary6 =
        {
        "010000008" => 1, #BONE IMAGING
        "010000003" => 1  #ADRENOMEDULLARY IMAGING-M-IBG
      }
      @operation6 = {"010000160" => 1} #POLARIZING MICROSCOPY

      #add all items to be ordered
      @@orders6 =  @ancillary6.merge(@operation6)
      n = 0
      @@orders6.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
        n += 1
      end
    end
    it "6th Availment: Add guarantor information" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    end
    it "6th Availment: Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "6th Availment: PBA user login and verify submitted transaction from the PhilHealth Outpatient Computation page" do
      sleep 6
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.go_to_philhealth_outpatient_computation.should be_true
      slmc.pba_pin_search(:pin => @@pin).should be_true
    end
    it "6th Availment: Click Philhealth link and input Philhealth details" do
      slmc.click_latest_philhealth_link_for_outpatient
      @@ph = slmc.philhealth_computation(:medical_case_type => "CATASTROPHIC CASE", :diagnosis => "A06.8", :philhealth_id => "12345", :rvu_code => "10060", :compute => true, :surgeon_type => "DIPLOMATE/FELLOW", :anesthesiologist_type => "DIPLOMATE/FELLOW")
    end
    it "6th Availment: Check Benefit Summary totals" do
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

      @@orders6.each do |order,n|
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
          x_lab_amt = item[:rate].to_f * n
          @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
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
    it "6th Availment: Checks if the actual charge for drugs/medicine is correct"   do
      # actual medical charges computation
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs -  (@promo_discount * total_drugs)
      @@ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "6th Availment: Checks if the actual benefit claim for drugs/medicine is correct" do
      # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB02")
      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim6 = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim6 = @@med_ph_benefit[:max_amt].to_f
      end
      @@ph[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim6))
    end
    it "6th Availment: Checks if the actual charge for xrays, lab and others is correct" do
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
      @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
      @@ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "6th Availment: Checks if the actual lab benefit claim is correct" do
      # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB03")
      #    if (@@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim5)) < 0.0
      #      @@actual_lab_benefit_claim6 = 0.00
      if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f #- (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim5))
        @@actual_lab_benefit_claim6 = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim6 = @@lab_ph_benefit[:max_amt].to_f #- (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim5))
      end
      @@ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim6))
    end
    it "6th Availment: Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@promo_discount * @@comp_operation)
      @@ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "6th Availment: Checks if the actual operation benefit claim is correct" do
      if slmc.get_value("rvu.code").empty? == false
        @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB04")
        if @@actual_operation_charges < @@operation_ph_benefit[:min_amt].to_f
          @@actual_operation_benefit_claim6 = @@actual_operation_charges
        else
          @@actual_operation_benefit_claim6 = @@operation_ph_benefit[:min_amt].to_f
        end
    #   @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
        @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
      else
        @@actual_operation_benefit_claim6 = 0.00
       # @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
        @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
      end
 #     @@actual_operation_benefit_claim6 = 1200.00
 #     @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
#      @@actual_operation_benefit_claim6 = 1200.00 # 137.5 environment only
#      @@ph[:er_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
    end
    it "6th Availment: Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@ph[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "6th Availment: Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim6 = @@actual_medicine_benefit_claim6 + @@actual_lab_benefit_claim6 + @@actual_operation_benefit_claim6
      @@ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim6))
    end
    it "6th Availment: Checks if the maximum benefits are correct" do
      @@ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "6th Availment: Checks if Deduction Claims are correct" do
      @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim6))
      @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim6))
      #@@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim6))
    end
    it "6th Availment: Checks if Remaining Benefit Claims are correct" do
      if @@actual_medicine_benefit_claim6 < @@med_ph_benefit[:max_amt].to_f #- (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim5))
        @@drugs_remaining_benefit_claim6 = (@@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim6)
      else
        @@drugs_remaining_benefit_claim6 = 0.00
      end
      @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim6

      if @@actual_lab_benefit_claim6 < @@lab_ph_benefit[:max_amt].to_f #- (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim5))
        @@lab_remaining_benefit_claim6 = (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim6)
      else
        @@lab_remaining_benefit_claim6 = 0.00
      end
      @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim6
    end
    it "6th Availment: Checks if PF Claims for surgeon is correct" do
      @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.5")
      @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
      @@surgeon_claim6 = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f

      @@ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim6))
    end
    it "6th Availment:Checks if PF Claims for anesthesiologist is correct" do
      @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("CAT_CSE","PHB06.8")
      anesthesiologist_claim6 = (@@surgeon_claim6.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))

      @@ph[:anesthesiologist_benefit_claim].should == ("%0.2f" %(anesthesiologist_claim6))
    end
    it "6th Availment: Checks if clicking 'Save' button saves the philhealth computation as ESTIMATE " do
      slmc.ph_save_computation
      slmc.is_text_present("ESTIMATE").should be_true
    end
    it "6th Availment: Checks if clicking 'View details' button displays of order details" do
      slmc.ph_view_details(:close => true)#.should be_true
    end
    it "6th Availment: Checks Claim History" do
      sleep 6
      slmc.login(@oss_user, @password)
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
      slmc.get_text(Locators::OSS_Philhealth.fifth_total_claim_history).gsub(',','').should == ("%0.2f" %(@@total_actual_benefit_claim5))
    end

    ## 7th Availment
    ## Account Class: Individual
    ## Case Type: Super Catastrophic
    ## Claim Type: Accounts Receivable
    ## With Operation: Yes
    ## Diagnosis: AMEBIC INFECTION OF OTHER SITES (A06.8)

    it "7th Availment: Searches and adds order items in the OSS outpatient order page" do
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true

      @ancillary7 =
        {
        "010000008" => 1, #BONE IMAGING
        "010000003" => 1, #ADRENOMEDULLARY IMAGING-M-IBG
      }
      @operation7 = {"010000160" => 1} #POLARIZING MICROSCOPY

      #add all items to be ordered
      @@orders7 =  @ancillary7.merge(@operation7)
      n = 0
      @@orders7.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
        n +=1
      end
    end
    it "7th Availment: Add guarantor and enable philhealth patient information" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
      slmc.oss_patient_info(:philhealth => true)
      @@ph = slmc.oss_input_philhealth(:case_type => "SUPER CATASTROPHIC CASE", :diagnosis => "A06.8", :philhealth_id => "12345", :rvu_code => "10060", :compute => true)
    end
    it "7th Availment: Check Benefit Summary totals" do
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

      @@orders7.each do |order,n|
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
          x_lab_amt = item[:rate].to_f * n
          @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
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
    it "7th Availment: Checks if the actual charge for drugs/medicine is correct"   do
      # actual medical charges computation
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs -  (@promo_discount * total_drugs)
      @@ph[:actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "7th Availment: Checks if the actual benefit claim for drugs/medicine is correct" do
      # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim7 = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim7 = @@med_ph_benefit[:max_amt].to_f
      end
      @@ph[:actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim7))
    end
    it "7th Availment: Checks if the actual charge for xrays, lab and others is correct" do
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
      @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
      @@ph[:actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "7th Availment: Checks if the actual lab benefit claim is correct" do
      # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")

      ## consider @@actual_lab_benefit_claim6 in BENEFIT CLAIM computation since 6th and 7th availment has the same diagnosis - AMEBIC INFECTION OF OTHER SITES (A06.8)
      if ( @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim6) < 0.0
        @@actual_lab_benefit_claim7 = 0.00
      elsif @@actual_comp_xray_lab_others < ( @@lab_ph_benefit[:max_amt].to_f -  @@actual_lab_benefit_claim6)
        @@actual_lab_benefit_claim7 = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim7 = ( @@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim6)
      end
      @@ph[:actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim7))
    end
    it "7th Availment: Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@promo_discount * @@comp_operation)
      @@ph[:actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "7th Availment: Checks if the actual operation benefit claim is correct" do
      if slmc.get_value("philHealthBean.rvu.code").empty? == false
        @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB04")
        if @@actual_operation_charges < @@operation_ph_benefit[:min_amt].to_f
          @@actual_operation_benefit_claim7 = @@actual_operation_charges
        else
          @@actual_operation_benefit_claim7 = @@operation_ph_benefit[:min_amt].to_f
        end
        @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
      else
        @@actual_operation_benefit_claim7 = 0.00
        @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
      end
###      @@actual_operation_benefit_claim7 = 1200.00
#      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
#      @@actual_operation_benefit_claim7 = 1200.00 # 137.5 environment only
#      @@ph[:actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
    end
    it "7th Availment: Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@ph[:total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "7th Availment: Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim7 = @@actual_medicine_benefit_claim7 + @@actual_lab_benefit_claim7 + @@actual_operation_benefit_claim7
      @@ph[:total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim7))
    end
    it "7th Availment: Checks if the maximum benefits are correct" do
      @@ph[:max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@ph[:max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "7th Availment: Checks if Deduction Claims are correct" do
      @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim7))
      @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim7))
      @@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim7))
    end
    it "7th Availment: Checks if Remaining Benefit Claims are correct" do
      ## consider @@actual_medicine6_benefit_claim6 in REMAINING BENEFIT CLAIM computation since 6th and 7th availment has the same diagnosis - AMEBIC INFECTION OF OTHER SITES (A06.8)
      if @@actual_medicine_benefit_claim7 < (@@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim6)
        @@drugs_remaining_benefit_claim7 = (@@med_ph_benefit[:max_amt].to_f - (@@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim7))
      else
        @@drugs_remaining_benefit_claim7 = 0.00
      end
      @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim7

      ## consider @@actual_lab_benefit_claim6 in REMAINING BENEFIT CLAIM computation since 6th and 7th availment has the same diagnosis - AMEBIC INFECTION OF OTHER SITES (A06.8)
      if @@actual_lab_benefit_claim7 < (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim6)
        @@lab_remaining_benefit_claim7 = (@@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim7))
      else
        @@lab_remaining_benefit_claim7 = 0.00
      end
      @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim7
    end
    it "7th Availment: Checks if PF Claims for surgeon is correct" do
      @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.3")
      @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("10060")
      @@surgeon_claim7 = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f

      @@ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim7))
    end
    it "7th Availment:Checks if PF Claims for anesthesiologist is correct" do
      @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.6")
      anesthesiologist_claim7 = (@@surgeon_claim7.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))

      @@ph[:anesthesiologist_benefit_claim].should == ("%0.2f" %(anesthesiologist_claim7))
    end
    it "7th Availment: Checks if Philhealth Claims is displayed in Summary Totals correctly" do
      slmc.get_philhealth_claims_amount.should == ("%0.2f" %(@@total_actual_benefit_claim7))
    end
    it "7th Availment: Checks if Summary Totals > Total Amount Due is equal to Payments > Total Amount Due " do
    slmc.get_total_amount_due.should == slmc.get_billing_total_amount_due
    end
    it "7th Availment: PhilHealth benefit claim shall not reflect in Payment details" do
      slmc.click "paymentToggle"
      (slmc.get_text('paymentSection').include? 'Philhealth').should be_false
      (slmc.get_text('paymentSection').include? @@total_actual_benefit_claim7.to_s).should be_false
      slmc.click "paymentToggle"
    end
    it "7th Availment: Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "7th Availment: Checks Claim History" do
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
      slmc.get_text(Locators::OSS_Philhealth.sixth_total_claim_history).gsub(',','').should == ("%0.2f" %(@@total_actual_benefit_claim6))
    end

    ## 8th Availment
    ## Account Class: Individual
    ## Case Type: Super Catastrophic
    ## Claim Type: Refund
    ## With Operation: Yes
    ## Diagnosis: GONOCOCCAL INFECTION OF OTHER MUSCULOSKELETAL TISSUE (A54.49)

    it "8th Availment: Searches and adds order items in the OSS outpatient order page" do
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true

      @ancillary8 =
        {
        "010000008" => 1, #BONE IMAGING
        "010000003" => 1  #ADRENOMEDULLARY IMAGING-M-IBG
      }
      @operation8 = {"010000160" => 1} #POLARIZING MICROSCOPY

      #add all items to be ordered
      @@orders8 =  @ancillary8.merge(@operation8)
      n = 0
      @@orders8.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
        n += 1
      end
    end
    it "8th Availment: Add guarantor information" do
      slmc.oss_add_guarantor(:guarantor_type =>  'INDIVIDUAL', :acct_class => 'INDIVIDUAL', :guarantor_add => true)
    end
    it "8th Availment: Proceed with payment successfully" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    end
    it "8th Availment: PBA user login and verify submitted transaction from the PhilHealth Outpatient Computation page" do
      sleep 6
      slmc.login(@pba_user, @password).should be_true
      slmc.go_to_patient_billing_accounting_page
      slmc.go_to_philhealth_outpatient_computation.should be_true
      slmc.pba_pin_search(:pin => @@pin).should be_true
    end
    it "8th Availment: Click Philhealth link and input Philhealth details" do
      slmc.click_latest_philhealth_link_for_outpatient
      @@ph = slmc.philhealth_computation(:medical_case_type => "SUPER CATASTROPHIC CASE", :diagnosis => "A54.49", :philhealth_id => "12345", :rvu_code => "22847", :compute => true, :surgeon_type => "DOCTORS WITH TRAINING", :anesthesiologist_type => "DIPLOMATE/FELLOW")
    end
    it "8th Availment: Check Benefit Summary totals" do
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

      @@orders8.each do |order,n|
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
          x_lab_amt = item[:rate].to_f * n
          @@non_comp_xray_lab += x_lab_amt   # total compensable xray and lab
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
    it "8th Availment: Checks if the actual charge for drugs/medicine is correct"   do
      # actual medical charges computation
      total_drugs = @@comp_drugs + @@non_comp_drugs
      @@actual_medicine_charges = total_drugs -  (@promo_discount * total_drugs)
      @@ph[:or_actual_medicine_charges].should == ("%0.2f" %(@@actual_medicine_charges))
    end
    it "8th Availment: Checks if the actual benefit claim for drugs/medicine is correct" do
      # PHB02	DRUGS AND MEDS PER SINGLE PERIOD OF CONFINEMENT	4200
      @@med_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB02")
      if @@actual_medicine_charges < @@med_ph_benefit[:max_amt].to_f
        @@actual_medicine_benefit_claim8 = @@actual_medicine_charges
      else
        @@actual_medicine_benefit_claim8 = @@med_ph_benefit[:max_amt].to_f
      end
      @@ph[:or_actual_medicine_benefit_claim].should == ("%0.2f" %(@@actual_medicine_benefit_claim8))
    end
    it "8th Availment: Checks if the actual charge for xrays, lab and others is correct" do
      total_xrays_lab_others = @@comp_xray_lab + @@non_comp_xray_lab + @@non_comp_supplies
      @@actual_xray_lab_others = total_xrays_lab_others - (@promo_discount * total_xrays_lab_others)
      @@ph[:or_actual_lab_charges].should == ("%0.2f" %(@@actual_xray_lab_others))
    end
    it "8th Availment: Checks if the actual lab benefit claim is correct" do
      # PHB03,X-RAYS LABS AND OTHERS PER SINGLE PERIOD OF CONFINEMENT,32001160.827368
      @@actual_comp_xray_lab_others = @@comp_xray_lab - (@promo_discount * @@comp_xray_lab)
      @@lab_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB03")
      #    if (@@lab_ph_benefit[:max_amt].to_f - (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim7)) < 0.0
      #      @@actual_lab_benefit_claim8 = 0.00
      if @@actual_comp_xray_lab_others < @@lab_ph_benefit[:max_amt].to_f #- (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim7))
        @@actual_lab_benefit_claim8 = @@actual_comp_xray_lab_others
      else
        @@actual_lab_benefit_claim8 = @@lab_ph_benefit[:max_amt].to_f #- (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim7))
      end
      @@ph[:or_actual_lab_benefit_claim].should == ("%0.2f" %(@@actual_lab_benefit_claim8))
    end
    it "8th Availment: Checks if the actual charge for operation is correct" do
      @@actual_operation_charges = @@comp_operation - (@promo_discount * @@comp_operation)
      @@ph[:or_actual_operation_charges].should == ("%0.2f" %(@@actual_operation_charges))
    end
    it "8th Availment: Checks if the actual operation benefit claim is correct" do
      if slmc.get_value("rvu.code").empty? == false
        @@operation_ph_benefit = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB04")
        if @@actual_operation_charges < @@operation_ph_benefit[:min_amt].to_f
          @@actual_operation_benefit_claim8 = @@actual_operation_charges
        else
          @@actual_operation_benefit_claim8 = @@operation_ph_benefit[:min_amt].to_f
        end
        @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
      else
        @@actual_operation_benefit_claim8 = 0.00
        @@ph[:or_actual_operation_benefit_claim].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
      end
    end
    it "8th Availment: Checks if the total actual charge(s) is correct" do
      total_actual_charges = @@actual_medicine_charges + @@actual_xray_lab_others + @@actual_operation_charges
      @@ph[:or_total_actual_charges].should == ("%0.2f" %(total_actual_charges))
    end
    it "8th Availment: Checks if the total actual benefit claim is correct" do
      @@total_actual_benefit_claim8 = @@actual_medicine_benefit_claim8 + @@actual_lab_benefit_claim8 + @@actual_operation_benefit_claim8
      @@ph[:or_total_actual_benefit_claim].should == ("%0.2f" %(@@total_actual_benefit_claim8))
    end
    it "8th Availment: Checks if the maximum benefits are correct" do
      @@ph[:er_max_benefit_drugs].should == ("%0.2f" %(@@med_ph_benefit[:max_amt]))
      @@ph[:er_max_benefit_xray_lab_others].should == ("%0.2f" %(@@lab_ph_benefit[:max_amt]))
    end
    it "8th Availment: Checks if Deduction Claims are correct" do
      @@ph[:drugs_deduction_claims].should == ("%0.2f" %(@@actual_medicine_benefit_claim8))
      @@ph[:lab_deduction_claims].should == ("%0.2f" %(@@actual_lab_benefit_claim8))
      #@@ph[:operation_deduction_claims].should == ("%0.2f" %(@@actual_operation_benefit_claim8))
    end
    it "8th Availment: Checks if Remaining Benefit Claims are correct" do
      if @@actual_medicine_benefit_claim8 < @@med_ph_benefit[:max_amt].to_f #- (@@actual_medicine_benefit_claim1 + @@actual_medicine_benefit_claim2 + @@actual_medicine_benefit_claim3 + @@actual_medicine_benefit_claim4 + @@actual_medicine_benefit_claim5 + @@actual_medicine_benefit_claim6 + @@actual_medicine_benefit_claim7))
        @@drugs_remaining_benefit_claim8 = (@@med_ph_benefit[:max_amt].to_f - @@actual_medicine_benefit_claim8)
      else
        @@drugs_remaining_benefit_claim8 = 0.00
      end
      @@ph[:drugs_remaining_benefit_claims].to_f.should == @@drugs_remaining_benefit_claim8

      if @@actual_lab_benefit_claim8 < @@lab_ph_benefit[:max_amt].to_f #- (@@actual_lab_benefit_claim1 + @@actual_lab_benefit_claim2 + @@actual_lab_benefit_claim3 + @@actual_lab_benefit_claim4 + @@actual_lab_benefit_claim5 + @@actual_lab_benefit_claim6 + @@actual_lab_benefit_claim7))
        @@lab_remaining_benefit_claim8 = (@@lab_ph_benefit[:max_amt].to_f - @@actual_lab_benefit_claim8)
      else
        @@lab_remaining_benefit_claim8 = 0.00
      end
      @@ph[:lab_remaining_benefit_claims].to_f.should == @@lab_remaining_benefit_claim8
    end
    it "8th Availment: Checks if PF Claims for surgeon is correct" do
      @@pf_gp_surgeon = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.4")
      @@rvu = PatientBillingAccountingHelper::Philhealth.get_rvu_value("22847")
      @@surgeon_claim8 = @@pf_gp_surgeon[:ph_pcf].to_f * @@rvu[:value].to_f

      @@ph[:surgeon_benefit_claim].should == ("%0.2f" %(@@surgeon_claim8))
    end
    it "8th Availment:Checks if PF Claims for anesthesiologist is correct" do
      @@pf_gp_anesthesiologist = PatientBillingAccountingHelper::Philhealth.get_ref_ph_benefit_using_code("SCT_CSE","PHB06.8")
      anesthesiologist_claim8 = (@@surgeon_claim8.to_f * (@@pf_gp_anesthesiologist[:ph_pcf].to_f/100))

      @@ph[:anesthesiologist_benefit_claim].should == ("%0.2f" %(anesthesiologist_claim8))
    end
    it "8th Availment: Checks if clicking 'Save' button saves the philhealth computation as ESTIMATE " do
      slmc.ph_save_computation
      slmc.is_text_present("ESTIMATE").should be_true
    end
    it "8th Availment: Checks if clicking 'View details' button displays of order details" do
      slmc.ph_view_details(:close => true).should == 3
    end
    it "8th Availment: Checks Claim History" do
      slmc.login(@oss_user, @password)
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@pin)
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
      slmc.get_text(Locators::OSS_Philhealth.seventh_total_claim_history).gsub(',','').should == ("%0.2f" %(@@total_actual_benefit_claim7))
    end

    ## 9th Availment - Not able to automate, requires DB manipulation for the scenario: outside 90 days from the previous availment

end

