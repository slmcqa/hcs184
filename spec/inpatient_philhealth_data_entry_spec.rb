#!/bin/env ruby
# encoding: utf-8


require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  

#require File.dirname(__FILE__) + '/../lib/slmc'

require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "SLMC :: Inpatient - Philhealth Data Entry" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    #@password = "123qweuser"
    #@user = "sel_adm4"

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
    

      @password = "123qweuser"
    
    
    
    
    

    @patient1 = Admission.generate_data

    @drugs =  {"040004334" => 1}
    @ancillary = {"010000003" => 1}
    @supplies = {"080200000" => 1}

#    @membership_type = ["SSS", "GSIS", "OWWA", "LIFETIME MEMBER", "SELF EMPLOYED/INDIVIDUAL PAYING MEMBER", "INDIGENT"]
    @membership_type = ["SSS", "GSIS", "OWWA"]#, "LIFETIME MEMBER", "SELF EMPLOYED/INDIVIDUAL PAYING MEMBER", "INDIGENT"]
#    @membership_relation = ["", "MEMBER", "SPOUSE", "CHILD", "PARENTS"]
    @membership_relation = ["", "MEMBER", "DEPENDENT"]#, "CHILD", "PARENTS"]

  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it "Creates Test Patient - Inpatient" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin = slmc.create_new_patient(@patient1).gsub(" ", "")
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin)
    slmc.create_new_admission(:account_class => "INDIVIDUAL", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "3325").should == "Patient admission details successfully saved."
  end

  it "Clinical Discharge Patient" do
    slmc.login(@gu_user_0287, @password).should be_true
    slmc.go_to_general_units_page
    slmc.clinically_discharge_patient(:pin => @@pin, :pf_type => "COLLECT", :no_pending_order => true, :pf_amount => '1000', :type => "standard", :save => true).should be_true
  end

  it "Go to PhilHealth page" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
  end

  it "Checks if PhilHealth Data Entry fields are in the page" do
    slmc.is_text_present("PhilHealth Reference No.:").should be_true
    slmc.get_selected_label("claimType").should == "ACCOUNTS RECEIVABLE"
    slmc.select("claimType", "REFUND")
    slmc.get_selected_label("claimType").should == "REFUND"
    slmc.get_text("banner.fullName").should == (@patient1[:last_name]).upcase + ", " + @patient1[:first_name] + " " + @patient1[:middle_name]
    slmc.is_text_present("Confinement Period").should be_true
    slmc.is_element_present("confinementPeriodSection").should be_true
    slmc.is_text_present("Complete Final Diagnosis").should be_true
    slmc.is_element_present("diagnosisSection").should be_true
    slmc.is_text_present("Membership Details").should be_true
    slmc.is_element_present("membershipDetailsSection").should be_true
    slmc.is_text_present("Employer Details").should be_true
    slmc.is_element_present("employerDetailsSection").should be_true
    slmc.is_text_present("Operation").should be_true
   # slmc.is_element_present("operationSection").should be_true
    slmc.is_text_present("Benefit Summary").should be_true
    slmc.is_element_present("benefitSummarySection").should be_true
    slmc.is_text_present("Maximum Benefits").should be_true
    slmc.is_element_present("benefitsSection").should be_true
    slmc.is_text_present("Claims").should be_true
    slmc.is_element_present("claimsSection").should be_true
    slmc.is_text_present("PF Claims").should be_true
    slmc.is_element_present("pfClaimsSection").should be_true
    slmc.is_text_present("Claims History").should be_true
    slmc.is_element_present("claimHistorySection").should be_true
    slmc.is_element_present("btnMainPage").should be_true
    slmc.is_element_present("btnCompute").should be_true
    slmc.is_element_present("btnEdit").should be_true
    slmc.is_element_present("btnSave").should be_true
    slmc.is_element_present("btnCancel").should be_true
    slmc.is_element_present("btnClear").should be_true
    slmc.is_element_present("btnPrint").should be_true
    slmc.is_element_present("btnViewDetails").should be_true
    slmc.get_text("css=#diagnosisSection>div:nth-child(2)>div>label").include?("*").should be_true
    slmc.get_text("css=#membershipDetailsSection>div:nth-child(4)>div>div>label").include?("*").should be_true
    #slmc.get_text("css=#employerDetailsSection>div:nth-child(2)>div>div>label").include?("*").should be_true # comment out since g2ix is employer in slmc.create_new_patient
    #slmc.get_text("css=#employerDetailsSection>div:nth-child(3)>div:nth-child(2)>label").include?("*").should be_true
    #slmc.get_text("css=#employerDetailsSection>div:nth-child(4)>div>div>label").include?("*").should be_true
  end

  it "Info is displayed under Patient Details" do
    slmc.is_text_present("Confinement No.:").should be_true
    slmc.is_text_present("CI / OR No.:").should be_true
    slmc.is_text_present("PIN:").should be_true
    slmc.is_text_present("Patient Name:").should be_true
    slmc.is_text_present("Date of Birth:").should be_true
    slmc.is_text_present("Civil Status:").should be_true
    slmc.is_text_present("Admitting Diagnosis:").should be_true
    slmc.is_text_present("Age:").should be_true
    slmc.is_text_present("Gender:").should be_true
    slmc.is_element_present("visitNumber").should be_true
    slmc.is_element_present("receiptNumber").should be_true
    slmc.is_element_present("pin").should be_true
    slmc.is_element_present("patientName.lastName").should be_true
    slmc.is_element_present("patientName.firstName").should be_true
    slmc.is_element_present("patientName.middleName").should be_true
    slmc.is_element_present("memberInfo.birthDate").should be_true
    slmc.is_element_present("age").should be_true
    slmc.is_element_present("gender").should be_true
    slmc.is_element_present("txtDiagnosisCode").should be_true
    slmc.is_element_present("txtDiagnosisDesc").should be_true
  end

  it "All fields are Read Only except CI / OR No. Field" do
    slmc.is_editable("receiptNumber").should be_true
    #slmc.is_editable("visitNumber").should be_false
    slmc.is_editable("pin").should be_false
    slmc.is_editable("patientName.lastName").should be_false
    slmc.is_editable("patientName.firstName").should be_false
    slmc.is_editable("patientName.middleName").should be_false
    #slmc.is_editable("memberInfo.birthDate").should be_false
    slmc.is_editable("age").should be_false
    slmc.is_editable("gender").should be_false
    slmc.is_editable("txtDiagnosisCode").should be_false
    slmc.is_editable("txtDiagnosisDesc").should be_false
  end

  it "Info is displayed under Confinement Period" do
    slmc.is_text_present("Date Admitted:").should be_true
    slmc.is_text_present("Discharge Date:").should be_true
    slmc.is_text_present("Death Date:").should be_true
    slmc.is_text_present("Time Admitted:").should be_true
    slmc.is_text_present("Discharge Time:").should be_true
    slmc.is_text_present("Death Time:").should be_true
    slmc.is_element_present("admissionDate").should be_true
    slmc.is_element_present("admissionHour").should be_true
    slmc.is_element_present("admissionMinute").should be_true
    slmc.is_element_present("admissionMeridiem").should be_true
    slmc.is_element_present("dischargeDate").should be_true
    slmc.is_element_present("dischargeHour").should be_true
    slmc.is_element_present("dischargeMinute").should be_true
    slmc.is_element_present("dischargeMeridiem").should be_true
    slmc.is_element_present("deathDate").should be_true
    slmc.is_element_present("memberInfo.deathHour").should be_true
    slmc.is_element_present("memberInfo.deathMinute").should be_true
    slmc.is_element_present("memberInfo.deathMeridiem").should be_true
  end

  it "Date Admitted and Time Admitted are read only, also for Discharge" do
    slmc.is_editable("admissionDate").should be_false
    slmc.is_editable("admissionHour").should be_false
    slmc.is_editable("admissionMinute").should be_false
    slmc.is_editable("admissionMeridiem").should be_false
    slmc.is_editable("dischargeDate").should be_false
    slmc.is_editable("dischargeHour").should be_false
    slmc.is_editable("dischargeMinute").should be_false
    slmc.is_editable("dischargeMeridiem").should be_false
  end

  it "NOT APPLICABLE - Case Type can be selected from the drop down list: Ordinary Case, Intensive Case, Catastrophic Case and Super Catastrophic Case - " do
 #   (slmc.get_select_options("medicalCaseType").count).should == 4
  end

  it "Selected Final Diagnosis will be added to the list with Diagnosis Code and Description" do
    slmc.is_element_present("btnDiagnosisLookup").should be_true
    diagnosis = "GLAUCOMA"
    slmc.click "btnDiagnosisLookup", :wait_for => :element, :element => "icd10_entity_finder_key"
    slmc.type "icd10_entity_finder_key", diagnosis
    slmc.click "//input[@value='Search' and @type='button' and @onclick='Icd10Finder.search();']", :wait_for => :element, :element => "link=#{diagnosis}"
    slmc.click "link=#{diagnosis}", :wait_for => :not_visible, :element => "link=#{diagnosis}"
    slmc.is_element_present("diagnosis_table_body").should be_true
    slmc.get_text("diagnosisDescription").should == "GLAUCOMA"
  end

  it "Info is displayed under Membership Details" do
    slmc.is_text_present("Membership Type:").should be_true
    slmc.is_text_present("Relationship to member:").should be_true
    slmc.is_text_present("PhilHealth Number:").should be_true
    slmc.is_text_present("Member Name:").should be_true
    slmc.is_text_present("Last Name:").should be_true
    slmc.is_text_present("First Name:").should be_true
    slmc.is_text_present("Middle Name:").should be_true
    slmc.is_text_present("Member Address:").should be_true
    slmc.is_text_present("Number and Street:").should be_true
    slmc.is_text_present("City/Town").should be_true
    slmc.is_text_present("Province").should be_true
    slmc.is_text_present("Country").should be_true
    slmc.is_text_present("Postal Code").should be_true
  end

  it "Checks Membership Type" do
    slmc.get_select_options("memberInfo.guarantor").should == @membership_type
  end

  it "Checks relation to member" do
    slmc.get_select_options("memberInfo.membershipType").should == @membership_relation
  end

  it "Checks member name if it displays by default" do
    slmc.get_value("memberInfo.memberName.lastName").should == @patient1[:last_name]
    slmc.get_value("memberInfo.memberName.firstName").should == @patient1[:first_name]
    slmc.get_value("memberInfo.memberName.middleName").should == @patient1[:middle_name]
  end

  it "Checks member adddress if it displays by default" do
    slmc.get_value("memberInfo.memberAddress").should == @patient1[:address]
  end

  it "Member name and address are editable" do
    slmc.is_editable("memberInfo.memberName.lastName").should be_true
    slmc.is_editable("memberInfo.memberName.firstName").should be_true
    slmc.is_editable("memberInfo.memberName.middleName").should be_true
    slmc.is_editable("memberInfo.memberAddress").should be_true
  end

  it "When valid Philippine postal code is entered, City, Province, and Country will be filled out automatically" do
    slmc.get_value("memberInfo.memberCity").should == ""
    slmc.get_value("memberInfo.memberProvince").should == ""
    slmc.type("memberInfo.memberPostalCode", "1201") #makati
    sleep 5
    slmc.get_value("memberInfo.memberCity").should == "MAKATI CITY"
    slmc.get_value("memberInfo.memberProvince").should == "METRO MANILA"
  end

  it "Info is displayed under Employer Details" do
    slmc.is_text_present("Employer Name:").should be_true
    slmc.is_text_present("Employer Address:").should be_true
    slmc.is_text_present("Philhealth Employer Number:").should be_true
    slmc.is_element_present("memberInfo.employerName").should be_true
    slmc.is_element_present("memberInfo.employerAddress.address").should be_true
    slmc.is_element_present("memberInfo.employerAddress.city").should be_true
    slmc.is_element_present("memberInfo.employerAddress.province").should be_true
    slmc.is_element_present("memberInfo.employerAddress.country").should be_true
    slmc.is_element_present("memberInfo.employerAddress.postalCode").should be_true
    slmc.is_element_present("memberInfo.employerMembershipID").should be_true
  end

  it "Fields on Employer Details are editable" do
    slmc.is_editable("memberInfo.employerName").should be_true
    slmc.is_editable("memberInfo.employerAddress.address").should be_true
    slmc.is_editable("memberInfo.employerAddress.city").should be_true
    slmc.is_editable("memberInfo.employerAddress.province").should be_true
    slmc.is_editable("memberInfo.employerAddress.country").should be_true
    slmc.is_editable("memberInfo.employerAddress.postalCode").should be_true
    slmc.is_editable("memberInfo.employerMembershipID").should be_true
  end

  it "When valid Philippine postal code is entered, City, Province and Country will be filled out automatically" do
    slmc.get_value("memberInfo.employerAddress.city").should == ""
    slmc.get_value("memberInfo.employerAddress.province").should == ""
    slmc.type("memberInfo.employerAddress.postalCode", "1201") #makati
    sleep 5
    slmc.get_value("memberInfo.employerAddress.city").should == "MAKATI CITY"
    slmc.get_value("memberInfo.employerAddress.province").should == "METRO MANILA"
  end

  it "By default, Operation is set to No" do
   # slmc.get_selected_label("withOperation").should == "No"
  end

  it "Operation Case and Operation Case Type fields are read only" do
    #slmc.is_editable("operationCasetypeLabel").should be_false
    #slmc.is_editable("rvu.operationCaseType").should be_false
  end

  it "RVU is required when set to Yes" do
#    slmc.select("withOperation", "Yes")
#    slmc.click("btnCompute", :wait_for => :page)
#    slmc.is_text_present("RVU Value is required for operational case.").should be_true
  end

  it "Select With Operation Yes or No" do
#    slmc.get_select_options("withOperation").should == ["No", "Yes"]
  end

  it "Three buttons are available in RVU search: Search, Reset, and close" do
#    slmc.click("btnRVULookup")
#    sleep 3
#    slmc.is_element_present("//input[@type='button' and @onclick='RVU.search();' and @value='Search']").should be_true
#    slmc.is_element_present("//input[@type='button' and @onclick='RVU.reset();' and @value='Reset']").should be_true
#    slmc.is_element_present("//input[@type='button' and @onclick='RVU.close();' and @value='Close']").should be_true
  end

  it "When Reset button is clicked search will be reset/cleared" do
    slmc.click("//input[@type='button' and @onclick='RVU.search();' and @value='Search']")
    sleep 3
    slmc.get_css_count("css=#rvu_finder_table_body>tr").should_not == 0
    slmc.click("//input[@type='button' and @onclick='RVU.reset();' and @value='Reset']")
    sleep 3
    slmc.get_css_count("css=#rvu_finder_table_body>tr").should == 0
  end

  it "Close button would enable the user to exit from RVU search" do
#    slmc.is_visible("rvuFinderForm").should be_true
#    slmc.click("//input[@type='button' and @onclick='RVU.close();' and @value='Close']")
#    sleep 3
#    slmc.is_visible("rvuFinderForm").should be_false
  end

  it "Message will be displayed when no record is found." do
#    slmc.click("btnRVULookup")
#    sleep 3
#    slmc.type("rvu_entity_finder_key", "SAMPLEINVALID")
#    slmc.click("//input[@type='button' and @onclick='RVU.search();' and @value='Search']")
#    sleep 5
#    slmc.get_css_count("css=#rvu_finder_table_body>tr").should == 0
#    slmc.is_text_present("0 item(s). Displaying 0 to 0.").should be_true
#    slmc.click("//input[@type='button' and @onclick='RVU.close();' and @value='Close']")
#    sleep 3
  end

  it "When Search button is clicked, results will display all records that match the search criteria" do
#    slmc.click("btnRVULookup")
#    sleep 3
#    slmc.type("rvu_entity_finder_key", "10060")
#    slmc.click("//input[@type='button' and @onclick='RVU.search();' and @value='Search']")
#    sleep 5
#    slmc.get_css_count("css=#rvu_finder_table_body>tr").should_not == 0
#    slmc.click "css=#rvu_finder_table_body>tr>td>div"
#    sleep 5
#    slmc.is_visible("rvu_finder_table_body").should be_false
  end

  it "Patient's previous PhilHealth claims will be displayed" do
    slmc.get_css_count("css=#claimHistorySection>div:nth-child(2)>table>tbody>tr>td").should == 1
    slmc.get_text("css=#claimHistorySection>div:nth-child(2)>table>tbody>tr>td").should == "Nothing found to display."
  end

  it "When required fields are not filled out, error message will be displayed" do
        sleep 6
    slmc.go_to_patient_billing_accounting_page
    @@visit_no = slmc.pba_search(:with_discharge_notice => true, :pin => @@pin)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
#    slmc.select("withOperation", "Yes")
    slmc.click "id=1stCaseDoctor-0"
    slmc.click("btnCompute") #:wait_for => :page)
sleep 6
 #   slmc.get_text("errorMessages").should == "Member ID is a required field.\nICD10 is required when saving PhilHealth form.\nOperation Case Type is required for operational case.\nRVU Value is required for operational case."
    slmc.get_text("errorMessages").should == "ICD10 is required when saving PhilHealth form.\nOperation Case Type is required for operational case.\nRVU Value is required for operational case."
   end

  it "Computes PhilHealth as ESTIMATE" do
    slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    @@ph_ref_no = slmc.ph_save_computation
    sleep 5
    @@ph_ref_no = @@ph_ref_no.gsub(" ", "")
   # slmc.get_text("//html/body/div/div[2]/div[2]/div[17]/h2").should == "ESTIMATE"
slmc.is_text_present("ESTIMATE").should be_true

  end

  it "Clicks Clear button" do
    sleep 2
    slmc.ph_edit
    sleep 2
    slmc.ph_clear
#    slmc.select("withOperation", "Yes")
    slmc.click "id=1stCaseDoctor-0"
    slmc.click("btnCompute")
    sleep 5
    #:wait_for => :page)
 #   slmc.get_text("errorMessages").should == "Member ID is a required field.\nICD10 is required when saving PhilHealth form.\nOperation Case Type is required for operational case.\nRVU Value is required for operational case."
    slmc.get_text("errorMessages").should == "ICD10 is required when saving PhilHealth form.\nOperation Case Type is required for operational case.\nRVU Value is required for operational case."
    slmc.get_text("diagnosisDescription").should == ""
    slmc.get_text("memberInfo.membershipID").should == ""
    slmc.get_text("memberInfo.employerName").should == ""
    slmc.get_text("memberInfo.employerMembershipID").should == ""
    @@ph1 = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    @@ph_ref_no = slmc.ph_save_computation
    @@ph_ref_no = @@ph_ref_no.gsub(" ", "")
  end

  it "Click Main Page button" do
    slmc.ph_go_to_mainpage.should be_true
  end

  it "PhilHealth Search – by Visit Number" do
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH", :search_options => "VISIT NUMBER", :entry => @@visit_no).should be_true
  end

  it "PhilHealth Search – by Document Number" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH", :search_options => "DOCUMENT NUMBER", :entry => @@ph_ref_no).should be_true
  end

  it "PhilHealth Search – by Date" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH", :search_options => "DOCUMENT DATE").should be_true
  end

  it "View and Reprint PhilHealth Form" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH", :search_options => "DOCUMENT NUMBER", :entry => @@ph_ref_no).should be_true
    slmc.go_to_page_using_reference_number("Reprint PhilHealth Form",@@ph_ref_no)
    slmc.is_text_present("Patient Billing and Accounting Home › Document Search").should be_true
  end

  it "View and Reprint PhilHealth Prooflist" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH", :search_options => "DOCUMENT NUMBER", :entry => @@ph_ref_no).should be_true
    slmc.go_to_page_using_reference_number("Display Details",@@ph_ref_no)
    slmc.is_text_present("PhilHealth Reference No.: #{@@ph_ref_no}").should be_true
  end

  it "View Computed PhilHealth – Accounts Receivable (Final)" do
    slmc.go_to_patient_billing_accounting_page
    yesterday = ((Date.strptime(Time.now.strftime("%Y-%m-%d"))) - 1).strftime("%m/%d/%Y")
    yesterday = ((Date.strptime(Time.now.strftime("%Y-%m-%d"))) - 3).strftime("%m/%d/%Y") if Time.now.strftime("%A") == "Monday"
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH", :search_options => "DOCUMENT DATE", :entry => yesterday).should be_true
    sleep 3
    count = slmc.get_css_count("css=#philhealthTableBody>tr")
   # count = slmc.get_css_count("//html/body/div/div[2]/div[2]/div[6]/table/tbody")

    count.times do |rows|
      my_row = slmc.get_text("css=#philhealthTableBody>tr:nth-child(#{rows + 1})>td:nth-child(7)")
      if my_row == "Final"
        @stop_row = rows
        break
      end
    end
    if @stop_row == nil
          puts "There are no saved FINAL Philhealth, manually validate this sample"
    else
          puts "@stop_row#{@stop_row}"
          slmc.select("css=#philhealthTableBody>tr:nth-child(#{@stop_row + 1})>td:nth-child(8)>select", "Display Details")
          slmc.click("css=#philhealthTableBody>tr:nth-child(#{@stop_row + 1})>td:nth-child(8)>input", :wait_for => :page)
          slmc.is_text_present("FINAL").should be_true
          slmc.is_text_present("PhilHealth Reference No.:").should be_true
    end
  end

  it "View Computed PhilHealth – Accounts Receivable (Estimate)" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_document_search(:select => "PhilHealth", :doc_type => "PHILHEALTH", :search_options => "DOCUMENT DATE").should be_true
    count = slmc.get_css_count("css=#philhealthTableBody>tr")
    count.times do |rows|
      my_row = slmc.get_text("css=#philhealthTableBody>tr:nth-child(#{rows + 1})>td:nth-child(7)")
      if my_row == "Estimate"
        @stop_row = rows
      end
    end
    slmc.select("css=#philhealthTableBody>tr:nth-child(#{@stop_row + 1})>td:nth-child(8)>select", "Display Details")
    @@ph_ref_no_final = slmc.get_text("css=#philhealthTableBody>tr:nth-child(#{@stop_row + 1})>td")
    slmc.click("css=#philhealthTableBody>tr:nth-child(#{@stop_row + 1})>td:nth-child(8)>input", :wait_for => :page)
    slmc.is_text_present("ESTIMATE").should be_true
    slmc.is_text_present("PhilHealth Reference No.:").should be_true
  end

  it "Search Computed PhilHealth from PhilHealth Outpatient Computation page" do
    slmc.go_to_patient_billing_accounting_page
    slmc.go_to_philhealth_outpatient_computation
    slmc.pba_pin_search(:pin => @@pin)
    slmc.is_text_present("Nothing found to display.").should be_true
    slmc.get_text("css=#results>tbody>tr>td").include?("Nothing found to display.").should be_true
  end

end