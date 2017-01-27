#!/bin/env ruby
# encoding: utf-8

require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  
#require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'
require 'oci8'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "Philhealth Multiple Session" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    @password = "123qweuser"
    @pba_user = "sel_pba2"
    @oss_user = "sel_oss3"

    @oss_patient = Admission.generate_data
    @ancillary = {"010001636" => 1,"010001822" => 1}
    @benefit_amount = "3000.00"
    @benefit_amount1 = "4000.00"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

#Feature number 41784
  it"Philhealth outpatient computation options" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(@oss_patient).gsub(' ', '').should be_true

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:philhealth_multiple_session => true)
    (slmc.is_text_present"PhilHealth Reference No.:").should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation 
    (slmc.is_text_present"Patient Billing and Accounting Home › Outpatient Computation").should be_true
    puts @@oss_pin
  end
  it"Philhealth outpatient computation options - PhilHealth Multiple Session" do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:philhealth_multiple_session => true)
#a1    = (slmc.get_attribute"//input[@type='text' and @value='REFUND']@readonly")
#   b1 = (slmc.get_attribute"phPatientInfoBean.patientName.lastName@readonly")
#    c1= (slmc.get_attribute"phPatientInfoBean.memberInfo.birthDateString@readonly")
#    d1= (slmc.get_attribute"phPatientInfoBean.memberInfo.civilStatus@readonly")
#    e1= (slmc.get_attribute"phPatientInfoBean.age@readonly")
#    f1= (slmc.get_attribute"phPatientInfoBean.gender@readonly")
#    puts "a1 = #{a1}"
#    puts "b1 = #{b1}"
#    puts "c1 = #{c1}"
#    puts "d1 = #{d1}"
#    puts "e1 = #{e1}"
##    puts "f1 = #{f1}"
#
#    (slmc.get_attribute"//input[@type='text' and @value='REFUND']@readonly").should == ""
#    (slmc.get_attribute"phPatientInfoBean.patientName.lastName@readonly").should == "true"
#    (slmc.get_attribute"phPatientInfoBean.memberInfo.birthDateString@readonly").should == "true"
#    (slmc.get_attribute"phPatientInfoBean.memberInfo.civilStatus@readonly").should == "true"
#    (slmc.get_attribute"phPatientInfoBean.age@readonly").should == "true"
#    (slmc.get_attribute"phPatientInfoBean.gender@readonly").should == "true"
#

    refund_value = (slmc.get_attribute"//input[@type='text' and @value='REFUND']@readonly")
    if refund_value == "readonly" || refund_value == "true" || refund_value == ""
      a = true
    else
      a = false
    end
    lastname_value =  (slmc.get_attribute"phPatientInfoBean.patientName.lastName@readonly")
    if lastname_value == "readonly" || lastname_value == "true" || lastname_value == ""
      b = true
    else
      b = false
    end
    bday_value = (slmc.get_attribute"phPatientInfoBean.memberInfo.birthDateString@readonly")
    if bday_value == "readonly" || bday_value == "true" || bday_value == ""
      c = true
    else
      c= false
    end
    cvil_value  = (slmc.get_attribute"phPatientInfoBean.memberInfo.civilStatus@readonly")
    if cvil_value == "readonly" || cvil_value == "true" || cvil_value == ""
      d = true
    else
      d = false
    end
    age_value = (slmc.get_attribute"phPatientInfoBean.age@readonly")
    if age_value == "readonly" || age_value == "true" || age_value == ""
      e = true
    else
      e = false
    end
    gender_value = (slmc.get_attribute"phPatientInfoBean.gender@readonly")
    if gender_value  == "readonly" || gender_value  == "true" || gender_value  == ""
      f = true
    else
      f = false
    end
   (a).should be_true
   (b).should be_true
   (c).should be_true
   (d).should be_true
   (e).should be_true
   (f).should be_true

    (slmc.is_text_present"1st Case Rate").should be_true
    (slmc.is_text_present"Case Rate Type:").should be_true
    (slmc.is_text_present"2nd Case Rate").should be_true
    (slmc.is_element_present"medicalCaseType").should be_true
    (slmc.is_element_present"phCaseRateType").should be_true
    slmc.select"phCaseRateType","SURGICAL"
    sleep 1
    (slmc.is_text_present"Case Rate:").should be_true
   # (slmc.get_text"caseRateNo").upcase.should =="RADIOTHERAPYHEMODIALYSISDILATATION AND CURETTAGECATARACT SURGERY"
       # (slmc.get_text"caseRateNo").should =="RADIOTHERAPYHemodialysis"

  end
  it"PhilHealth Multiple Session - Notification is displayed" do
    slmc.type"phPatientInfoBean.pin","12309*&12@"
    sleep 3
    (slmc.get_alert).should == "No record found for pin 12309*&12@"
  end
  it"PhilHealth Multiple Session - Input valid pin" do
    slmc.type"phPatientInfoBean.pin",@@oss_pin
    sleep 2
    (slmc.get_value"phPatientInfoBean.patientName.lastName").should == @oss_patient[:last_name]
    (slmc.get_value"phPatientInfoBean.patientName.firstName").should == @oss_patient[:first_name]
    (slmc.get_value"phPatientInfoBean.memberInfo.birthDateString").should == @oss_patient[:birth_day]
  end
  it"Items that are not claimed are listed TXN_PBA_PAYMENT_HDR" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order(:pin => @@oss_pin).should
    sleep 6
    slmc.oss_add_guarantor(:acct_class => "HMO",:guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :coverage_choice => "percent", :coverage_amount => 50, :guarantor_add => true )
    @ancillary.each do |item, q|
    slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => "5979")
    end
    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    sleep 20
    
    @@visit_no = slmc.get_visit_number_using_pin(@@oss_pin) #sometimes submitting or/ci hang\\
    sleep 6
    puts "@@visit_no - #{@@visit_no}"
    Database.connect
            a =  "SELECT OR_NUMBER  FROM SLMC.TXN_PBA_PAYMENT_HDR WHERE VISIT_NO ='#{@@visit_no}'"
            aa = Database.select_statement a
    Database.logoff
    @@or_no  = aa
  #  @@or_no = slmc.access_from_database(:what => "OR_NUMBER", :table => "TXN_PBA_PAYMENT_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no)
puts "@@or_no = #{@@or_no}"          

  end
  it"Items are listed in Order Details" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:philhealth_multiple_session => true)
    sleep 3
    slmc.oss_rvu(:rvu_key => "77401", :diagnosis => "A00").should be_true
    slmc.click_add_reference(:pin => @@oss_pin,:reference_no=>@@or_no).should be_true
@@order_dtl_no = []
    @@order_dtl_no = slmc.access_from_database_with_join(:table1 => "TXN_OM_ORDER_DTL", :table2 => "TXN_OM_ORDER_GRP",:condition1 => "ORDER_GRP_NO",
      :column1 => "VISIT_NO", :where_condition1 => @@visit_no,:gate => "AND",:column2 => "PERFORMING_UNIT", :where_condition2 => "0075")
    #@@order_dtl_no = @@order_dtl_no.sort
    sleep 1
    puts "@@order_dtl_no = #{@@order_dtl_no}"
  #@@order_dtl_no   = "[#{@@order_dtl_no}],"
   @@order_dtl_no   = "#{@@order_dtl_no}"
    (slmc.get_text"css=#orderDetailRows>tr>td").should == @@order_dtl_no
  end
  it"PhilHealth Multiple Session - Invalid or/ci" do
    slmc.oss_rvu(:rvu_key => "77401").should be_true
    slmc.click_add_reference(:pin => @@oss_pin,:reference_no=>@@or_no + "@@",:alert => true).should == "Nothing to add."
  end
  it"PhilHealth Multiple Session - Valid or with unclaimed items" do
    slmc.click_add_reference(:reference_no=>@@or_no).should be_true
    (slmc.get_text"css=#orCiRows>tr>td:nth-child(4)").should == "Official Reciept"
#    (slmc.get_text"//html/body/div/div[2]/div[2]/form/div[11]/div[2]/div/table/tbody/tr/td[5]").should == "Not Filed"
      slmc.get_text("//html/body/div[1]/div[2]/div[2]/form/div[10]/div[2]/div/table/tbody/tr/td[5]").should == "Not Filed"

  end
  it "PhilHealth Multiple Session - Click Delete" do
    slmc.click"#{@@or_no}delBtn"
    sleep 1
  end
  it"PhilHealth Multiple Session - Check ci of  unclaimed items" do
    slmc.oss_rvu(:rvu_key => "77401").should be_true
    slmc.click_add_reference(:pin => @@oss_pin,:reference_no=>@@or_no,:ci => true,:alert => true).should == "Nothing to add."
    slmc.click"isCi" if slmc.is_checked"isCi"
    sleep 1
  end
  it"Check Benefit Summary" do
    slmc.click_add_reference(:reference_no=>@@or_no).should be_true
#    @@ph = slmc.ph_multiple_session(:case_type => "ORDINARY CASE", :case_rate_type => "SURGICAL",:case_rate => "RADIOTHERAPY",:session => "0", :compute => true)
   # @@ph = slmc.ph_multiple_session(:case_rate_type => "SURGICAL",:case_rate => "77401",:case_rate_name => "RADIATION TREATMENT DELIVERY (LINEAR ACCELERATOR)",:session => "0", :compute => true)
    @@ph = slmc.ph_multiple_session(:case_rate_type => "SURGICAL",:case_rate => "77401",:session => "0", :compute => true)
    #fixed amount
    @@ph[:actual_operation_benefit_claim].should == @benefit_amount
    @@ph[:total_actual_benefit_claim].should == @benefit_amount
  end
  it"Information are save in database" do
    slmc.click"btnSave", :wait_for => :page
    (slmc.is_text_present"The PhilHealth form is saved successfully.")

    @@ph_ref = slmc.get_text"//html/body/div/div[2]/div[2]/form/div[3]/div/div[2]/label"

    @@ph_ref.should == slmc.access_from_database(:what => "PH_REF_NO", :table => "TXN_PBA_PH_HDR", :column1 => "PH_REF_NO", :condition1 => @@ph_ref)
    @@ph_ref.should == slmc.access_from_database(:what => "PH_REF_NO", :table => "TXN_PBA_PH_DTL", :column1 => "PH_REF_NO", :condition1 => @@ph_ref)
    @@ph_ref.should == slmc.access_from_database(:what => "PH_REF_NO", :table => "TXN_PBA_PH_HISTORY", :column1 => "PH_REF_NO", :condition1 => @@ph_ref)
    @@ph_ref.should == slmc.access_from_database(:what => "PH_REF_NO", :table => "TXN_PBA_PH_OR_CI_RECORD", :column1 => "PH_REF_NO", :condition1 => @@ph_ref)
    @@ph_ref.should == slmc.access_from_database(:what => "PH_REF_NO", :table => "TXN_PBA_PH_RB", :column1 => "PH_REF_NO", :condition1 => @@ph_ref)
  end
  it"PhilHealth Multiple Session - with already claimed items " do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:philhealth_multiple_session => true)

    slmc.oss_rvu(:rvu_key => "77401")
    slmc.click_add_reference(:pin => @@oss_pin,:reference_no=>@@or_no).should be_true
#    (slmc.get_text"//html/body/div/div[2]/div[2]/form/div[11]/div[2]/div/table/tbody/tr/td[5]").should == "Filed"
     slmc.get_text("//html/body/div[1]/div[2]/div[2]/form/div[10]/div[2]/div/table/tbody/tr/td[5]").should == "Filed"

    slmc.get_attribute("orCiRecords[0].orderDetailPhBean[0].sessionDate@readonly").should == "true"
  #  (slmc.get_text"//html/body/div/div[2]/div[2]/form/div[11]/div[2]/div/table/tbody/tr[2]/td[5]").should == "Not Filed"
      slmc.get_text("//html/body/div[1]/div[2]/div[2]/form/div[10]/div[2]/div/table/tbody/tr/td[5]").should == "Not Filed"

  end
  it"PhilHealth Multiple Session - Valid ci with unclaimed items" do
    @@ci_no = slmc.access_from_database(:what => "DOCUMENT_NO", :table => "TXN_PBA_AR_PATIENT", :column1 => "VISIT_NO", :condition1 => @@visit_no)
    sleep 1
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:philhealth_multiple_session => true)

    slmc.oss_rvu(:rvu_key => "77401").should be_true
    slmc.click_add_reference(:pin => @@oss_pin,:reference_no=>@@ci_no,:ci => true).should be_true
    (slmc.get_text"css=#orCiRows>tr>td:nth-child(4)").should == "Charge Invoice"

 #   (slmc.get_text"//html/body/div/div[2]/div[2]/form/div[11]/div[2]/div/table/tbody/tr[2]/td[5]").should == "Not Filed"
    #    (slmc.get_text"//html/body/div/div[2]/div[2]/form/div[11]/div[2]/div/table/tbody/tr/td[5]").should == "Not Filed"
#                               "//html/body/div/div[2]/div[2]/form/div[11]/div[2]/div/table/tbody/tr/td[5]"
      slmc.get_text("//html/body/div[1]/div[2]/div[2]/form/div[10]/div[2]/div/table/tbody/tr/td[5]").should == "Not Filed"

  end
  it"PhilHealth Multiple Session - ci with already claimed items " do
   # @@ph1 = slmc.ph_multiple_session(:case_type => "ORDINARY CASE", :case_rate_type => "SURGICAL",:case_rate => "RADIOTHERAPY",:session => "1", :compute => true)
    @@ph1 = slmc.ph_multiple_session(:case_type => "ORDINARY CASE", :case_rate_type => "SURGICAL",:case_rate => "77401",:session => "1", :compute => true)
    #fixed amount
    @@ph1[:actual_operation_benefit_claim].should == @benefit_amount
    @@ph1[:total_actual_benefit_claim].should == @benefit_amount
    slmc.click"btnSave", :wait_for => :page
    (slmc.is_text_present"The PhilHealth form is saved successfully.")

    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:philhealth_multiple_session => true)

    slmc.oss_rvu(:rvu_key => "77401").should be_true
    slmc.click_add_reference(:pin => @@oss_pin,:reference_no=>@@ci_no,:ci => true).should be_true
  #  (slmc.get_text"//html/body/div/div[2]/div[2]/form/div[11]/div[2]/div/table/tbody/tr[2]/td[5]").should == "Filed"
      slmc.get_text("//html/body/div[1]/div[2]/div[2]/form/div[10]/div[2]/div/table/tbody/tr/td[5]").should == "Filed"

    slmc.get_attribute("orCiRecords[0].orderDetailPhBean[1].sessionDate@readonly").should == "true"
  end
  it"PhilHealth Multiple Session - Valid ci previously claimed" do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:philhealth_multiple_session => true)
    slmc.oss_rvu(:rvu_key => "77401").should be_true
    slmc.click_add_reference(:pin => @@oss_pin,:reference_no=>@@ci_no,:ci => true)

    count=slmc.get_css_count"css=#orderDetailRows>tr"
    rows = 0
    count.times do
    @@remarks = ((slmc.get_text"css=#orderDetailRows>tr:nth-child(#{rows + 1})>td:nth-child(5)") == "Filed")
    count+=1
    rows+=1
    end
    @@remarks.should be_true

#    slmc.ph_multiple_session(:case_type => "ORDINARY CASE", :case_rate_type => "SURGICAL",:case_rate => "RADIOTHERAPY", :compute => true)
    slmc.ph_multiple_session(:case_type => "ORDINARY CASE", :case_rate_type => "SURGICAL",:case_rate => "Radiotherapy", :compute => true)

    (slmc.get_text"philHealthForm.errors").should == "All items specific to the selected RVU under this CI/OR number were already claimed!.philHealthForm"
  end
  it"PhilHealth Multiple Session - Valid or with claimed items" do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:philhealth_multiple_session => true)
    slmc.oss_rvu(:rvu_key => "77401").should be_true
    slmc.click_add_reference(:pin => @@oss_pin,:reference_no=>@@or_no)

    count=slmc.get_css_count"css=#orderDetailRows>tr"
    rows = 0
    count.times do
    @@remarks = ((slmc.get_text"css=#orderDetailRows>tr:nth-child(#{rows + 1})>td:nth-child(5)") == "Filed")
    count+=1
    rows+=1
    end
    @@remarks.should be_true

#    slmc.ph_multiple_session(:case_type => "ORDINARY CASE", :case_rate_type => "SURGICAL",:case_rate => "RADIOTHERAPY", :compute => true)
    slmc.ph_multiple_session(:case_type => "ORDINARY CASE", :case_rate_type => "SURGICAL",:case_rate => "Radiotherapy", :compute => true)

    (slmc.get_text"philHealthForm.errors").should == "All items specific to the selected RVU under this CI/OR number were already claimed!.philHealthForm"
  end
  it"Correct Philhealth computation is reflected for 45 sessions only." do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :coverage_choice => "percent", :coverage_amount => 50, :guarantor_add => true )
    slmc.oss_order(:order_add => true, :item_code => "010001636", :quantity => 50, :doctor => "5979")
    slmc.oss_order(:order_add => true, :item_code => "010001822", :quantity => 50, :doctor => "5979")

    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    sleep 2
    @@visit_no1 = (slmc.get_visit_number_using_pin(@@oss_pin)[0])
    @@or_no1 = slmc.access_from_database(:what => "OR_NUMBER", :table => "TXN_PBA_PAYMENT_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no1)

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:philhealth_multiple_session => true)
    slmc.oss_rvu(:rvu_key => "77401").should be_true
    slmc.click_add_reference(:pin => @@oss_pin,:reference_no=>@@or_no1).should be_true
    @item_amount = slmc.get_text"css=#orderDetailRows>tr>td:nth-child(3)"
    #@@ph1 = slmc.ph_multiple_session(:case_type => "ORDINARY CASE", :case_rate_type => "SURGICAL",:case_rate => "RADIOTHERAPY",:all_session => true, :compute => true)
    @@ph1 = slmc.ph_multiple_session(:case_type => "ORDINARY CASE", :case_rate_type => "SURGICAL",:case_rate => "Radiotherapy",:all_session => true, :compute => true)

    @@ph1[:actual_rb_availed_benefit_claim].should == "45" #45 sessions
    (@@ph1[:actual_operation_benefit_claim].to_f).should == (@benefit_amount.to_f * 45)
    (@@ph1[:actual_operation_charges].to_f).should == (@item_amount.to_f * 45)
    (@@ph1[:total_actual_benefit_claim].to_f).should == (@benefit_amount.to_f * 45)
    (@@ph1[:total_actual_charges].to_f).should == (@item_amount.to_f * 45)
  end
  it"Patient can no longer claim Philhealth benefits."do
    slmc.click"btnSave", :wait_for => :page
    sleep 1
    slmc.click"btnPrint" #cannot check pdf
    sleep 1
    slmc.type"procedureNameTxt","LINEAR ACCELERATOR"
    slmc.click"btnOK", :wait_for => :page

    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :coverage_choice => "percent", :coverage_amount => 50, :guarantor_add => true )
    slmc.oss_order(:order_add => true, :item_code => "010001636", :quantity => 50, :doctor => "5979")

    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    sleep 2
    if (slmc.get_visit_number_using_pin(@@oss_pin)[0]) == @@visit_no1
    @@visit_no2 = (slmc.get_visit_number_using_pin(@@oss_pin)[2])
    end
    @@or_no2 = slmc.access_from_database(:what => "OR_NUMBER", :table => "TXN_PBA_PAYMENT_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no2)

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:philhealth_multiple_session => true)
    slmc.oss_rvu(:rvu_key => "77401").should be_true
    slmc.click_add_reference(:pin => @@oss_pin,:reference_no=>@@or_no2).should be_true

    #@@ph2 = slmc.ph_multiple_session(:case_type => "ORDINARY CASE", :case_rate_type => "SURGICAL",:case_rate => "RADIOTHERAPY",:all_session => true, :compute => true, :save => true)
    @@ph2 = slmc.ph_multiple_session(:case_type => "ORDINARY CASE", :case_rate_type => "SURGICAL",:case_rate => "Radiotherapy",:all_session => true, :compute => true, :save => true)
  end
  it"Philhealth multiple sessions - Claim history" do # to do when fixed

  end
  it"Philhealth multiple sessions - View and Reprinting" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH MULTIPLE SESSION", :search_options => "PIN",:entry => @@oss_pin,:view_and_reprinting => true).should be_true
  end
  it"Philhealth multiple sessions - View and Reprinting - Search option/s field contains" do
    (slmc.get_text"searchOptions").should == "VISIT NUMBER DOCUMENT NUMBER DOCUMENT DATE PIN"
  end
  it"Philhealth multiple sessions - View and Reprinting - table contains" do
    (slmc.get_text"css=#documentSearchResults>table>thead>tr").should == "Reference No. Member's Name Patient's Name Confinement No. Document Date Claim Type Status Actions"
  end
  it"Philhealth multiple sessions - View and Reprinting - Document  number" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH MULTIPLE SESSION", :search_options => "DOCUMENT NUMBER",:entry => @@ph_ref,:view_and_reprinting => true).should be_true
  end
  it"Philhealth multiple sessions - View and Reprinting - Document  date" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH MULTIPLE SESSION", :search_options => "DOCUMENT DATE",:view_and_reprinting => true).should be_true
  end
  it"Philhealth multiple sessions - View and Reprinting - Action column" do
    slmc.get_text('css=#philhealthTableBody>tr.even>td:nth-child(8)').should == "Reprint PhilHealth Form Reprint Prooflist Display Details"
  end
  it"Philhealth multiple sessions - View and Reprinting - Reprint Philhealth Form" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH MULTIPLE SESSION", :search_options => "DOCUMENT NUMBER",:entry => @@ph_ref,:view_and_reprinting => true).should be_true
    slmc.go_to_page_using_reference_number("Reprint PhilHealth Form", @@ph_ref)
  end
  it"Philhealth multiple sessions - View and Reprinting - Display Details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH MULTIPLE SESSION", :search_options => "DOCUMENT NUMBER",:entry => @@ph_ref,:view_and_reprinting => true).should be_true
    slmc.go_to_page_using_reference_number("Display Details", @@ph_ref)
  end
  it"Philhealth multiple sessions - View and Reprinting - Same result is obtained when re-computed." do #after display details
    slmc.click"btnEdit"
    sleep 1
    slmc.click"btnCompute", :wait_for => :page
    (slmc.get_text"//html/body/div/div[2]/div[2]/form/div[11]/div[2]/div/table/tbody/tr[3]/td[3]").gsub(',','').should == @benefit_amount
  end
  it"Philhealth multiple sessions - View and Reprinting - Changing rvu not allowed." do
    slmc.click"btnEdit"
    sleep 5
    slmc.oss_rvu(:rvu_key => "10080").should be_true
    slmc.click"btnCompute", :wait_for => :page
    (slmc.get_text"//html/body/div/div[2]/div[2]/form/div[11]/div[2]/div/table/tbody/tr[3]/td[3]").gsub(',','').should == @benefit_amount
  end
  it"Philhealth multiple sessions - View and Reprinting - Changing rvu allowed when or/ci is deleted." do #to be continued
    slmc.click"btnEdit"
    sleep 1
    slmc.click"#{@@or_no}delBtn"
    sleep 1
    slmc.oss_rvu(:rvu_key => "10080").should be_true
    slmc.click"btnCompute", :wait_for => :page
    (slmc.get_text"//html/body/div/div[2]/div[2]/form/div[11]/div[2]/div/table/tbody/tr[3]/td[3]").gsub(',','').should == "1200.00"
  end
  it"Philhealth multiple session - Hemodialysis" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(Admission.generate_data).gsub(' ', '').should be_true
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @@oss_pin)
    slmc.click_outpatient_order.should be_true
    slmc.oss_add_guarantor(:guarantor_type => "HMO", :guarantor_code => "ASALUS (INTELLICARE)", :coverage_choice => "percent", :coverage_amount => 50, :guarantor_add => true )

    slmc.oss_order(:order_add => true, :item_code => "010001822", :quantity => 40, :doctor => "5979")

    amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
    slmc.oss_add_payment(:amount => amount, :type => "CASH")
    (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
    sleep 2
    @@visit_no = slmc.get_visit_number_using_pin(@@oss_pin) #sometimes submitting or/ci hang
    @@or_no = slmc.access_from_database(:what => "OR_NUMBER", :table => "TXN_PBA_PAYMENT_HDR", :column1 => "VISIT_NO", :condition1 => @@visit_no)

    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation(:philhealth_multiple_session => true)
    slmc.oss_rvu(:rvu_key => "Hemodialysis").should be_true
    slmc.click_add_reference(:pin => @@oss_pin,:reference_no=>@@or_no).should be_true

    @@ph = slmc.ph_multiple_session(:case_type => "ORDINARY CASE", :case_rate_type => "SURGICAL",:case_rate => "Hemodialysis",:session => "0", :compute => true)
    #fixed amount
    @@ph[:actual_operation_benefit_claim].should == @benefit_amount1
    @@ph[:total_actual_benefit_claim].should == @benefit_amount1
    slmc.click"btnSave", :wait_for => :page
    (slmc.is_text_present"The PhilHealth form is saved successfully.")
  end
  it"Philhealth multiple session - Hemodialysis - details save in database" do
    @@ph_ref = slmc.get_text"//html/body/div/div[2]/div[2]/form/div[2]/div/div[2]/label"
    @@ph_ref.should == slmc.access_from_database(:what => "PH_REF_NO", :table => "TXN_PBA_PH_HDR", :column1 => "PH_REF_NO", :condition1 => @@ph_ref)
    @@ph_ref.should == slmc.access_from_database(:what => "PH_REF_NO", :table => "TXN_PBA_PH_DTL", :column1 => "PH_REF_NO", :condition1 => @@ph_ref)
    @@ph_ref.should == slmc.access_from_database(:what => "PH_REF_NO", :table => "TXN_PBA_PH_HISTORY", :column1 => "PH_REF_NO", :condition1 => @@ph_ref)
    @@ph_ref.should == slmc.access_from_database(:what => "PH_REF_NO", :table => "TXN_PBA_PH_OR_CI_RECORD", :column1 => "PH_REF_NO", :condition1 => @@ph_ref)
    @@ph_ref.should == slmc.access_from_database(:what => "PH_REF_NO", :table => "TXN_PBA_PH_RB", :column1 => "PH_REF_NO", :condition1 => @@ph_ref)
  end
end
