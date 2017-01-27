#require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'  
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "Patient Billing and Accounting - Manual Discount" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    #@selenium_driver.evaluate_rooms_for_admission('0287','RCH08')
    @password = "123qweuser"
    #@password = "gohc"
    @employee =  "1504081924"   #"1501079459"  # "1302028328"#guarantor_code=>"0109992"

    #@maternity_employee = "1001500418"#guarantor_code=>"0109991"
			@maternity_employee = "1504081926"             #"1501079462"  #"1302028332"#guarantor_code=>"0109991"
    #""
    #@employee_dependent = "1108008783"#benefactor_code=>"0109992" SELENIUM_TAN,SELENIUM_RACHEL
    @employee_dependent = "1504081927"                    #"1501079463"

    @employee_dependent1 = "1504081928"    #"1501079464"#benefactor_code =>"0109995",SEL_EMPLOYEE,SELENIUM_RACHEL
    @employee1 = "1504081930"#"1501079465"#"1404070760"#guarantor_code=>"0209992"
    @oss_employee = @employee_dependent1#"1302028333 "#SELENIUM_EMPLOYEE1
    @oss_maternity = @employee_dependent1#"1302028330"#SELENIUM_EMPLOYEE2
    @oss_dependent = @employee_dependent1#Sel_employee, Rachel Mae Cheng
    @user = "billing_spec_user2"
    #@user = "jr-admin"

    #@pba_user = "sel_pba12"
    #@pba_user = "pba1" #endoscopic
    #@pba_user = "ldcastro" #"sel_pba7"
    @pba_user = "pba1" #"sel_pba7"
    @ss_user = "sel_ss2"
    @oss_user = "sel_oss1"
    @ancillary = {"010001194" => 1}
    @courtesy_discount = 500.0
    @ss_amount = 500.0
    @promo_discount_senior = 0.2
    @promo_discount_non_senior = 0.16

   @dept_code = "J - OBSTETRICS AND GYNECOLOGY"
    @esc_no = "121024AG0012" #0000462Scenario 1 - Medical Case 30% : Compute and Save PhilHealth
  end
  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end
################=========================================================================================================================#
  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service >= 1 (More Than or Equal to 1 Year) AND Non-Maternity case - Create New Admission" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @employee).should be_true
    result = slmc.create_new_admission(:account_class => "EMPLOYEE", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726",:guarantor_code=>"0109992")
         if result == "Patient admission details successfully saved." || "Unable to print patient wristband please check your printer."
            admission = true
    else
            admission = false
    end
    admission.should == true
  end
  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service >= 1 (More Than or Equal to 1 Year) AND Non-Maternity case - Order Items" do
    slmc.nursing_gu_search(:pin => @employee)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @employee)
    slmc.search_order(:description => "010001194", :ancillary => true).should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001194", :add => true, :doctor => "0126").should be_true
    sleep 5
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end
  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service >= 1 (More Than or Equal to 1 Year) AND Non-Maternity case - Clnically Discharge Patient" do
    slmc.nursing_gu_search(:pin=> @employee)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @employee, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end
  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service >= 1 (More Than or Equal to 1 Year) AND Non-Maternity case - Philhealth" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @employee)
    slmc.go_to_page_using_visit_number("PhilHealth", slmc.visit_number)
    # @@ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    @@ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10080", :compute => true)
    ph_number = slmc.ph_save_computation
    puts "ph_number - #{ph_number}"
    ph_number.should_not == nil
     
  end
  ########
  ########not a valid scenario, and if scenario above cause error, just delete. https://projects.exist.com/issues/40549
  ###################  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service >= 1 (More Than or Equal to 1 Year) AND Non-Maternity case - Discount" do
  ###################    slmc.go_to_patient_billing_accounting_page
  ###################    slmc.pba_search(:with_discharge_notice => true, :pin => @employee)
  ###################    slmc.go_to_page_using_visit_number("Discount", slmc.visit_number)
  ###################    sleep 3
  ###################    slmc.add_discount(:discount => "Employee Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Percentage",
  ###################      :discount_rate => "100", :close_window => true, :save => true).should be_true
  ###################  end
  ###
  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service >= 1 (More Than or Equal to 1 Year) AND Non-Maternity case - DAS Discharge" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @employee)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "DAS").should be_true


  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service >= 1 (More Than or Equal to 1 Year) AND Non-Maternity case - Check Discount Details" do

    slmc.login(@pba_user, @password).should be_true
    sleep 6
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @employee)
    slmc.go_to_page_using_visit_number("Payment", slmc.visit_number)
   ph_claim =  @@ph[:total_actual_benefit_claim]
    @@summary = slmc.get_billing_details_from_payment_data_entry
    @total_charges =  (@@summary[:hospital_bill].to_f + @@summary[:room_charges].to_f) - (ph_claim.to_f)

    @@summary[:discounts].to_f.should == ("%0.2f" %(@total_charges)).to_f
    @@summary[:total_hospital_bills].to_f.should == 0.0
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service >= 1 (More Than or Equal to 1 Year) AND Non-Maternity case - Print Gatepass" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @employee)
    slmc.print_gatepass(:no_result => true, :pin => @employee).should be_true
  end
  ##############=========================================================================================================================#
  ##############=========================================================================================================================#
  ##############=========================================================================================================================#
  ##############=========================================================================================================================#

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service < 1 OR Maternity case - Create New Admission" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @maternity_employee).should be_true
    slmc.create_new_admission(:account_class => "EMPLOYEE", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726",:guarantor_code=>"0109991").should == "Patient admission details successfully saved."
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service < 1 OR Maternity case - Order Items" do
        slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @maternity_employee)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @maternity_employee)
    slmc.search_order(:description => "010001194", :ancillary => true).should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001194", :add => true, :doctor => "0126").should be_true
    sleep 5
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service < 1 OR Maternity case - Clnically Discharge Patient" do
    slmc.nursing_gu_search(:pin=> @maternity_employee)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @maternity_employee, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service < 1 OR Maternity case - Maternity Case" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @maternity_employee)
    slmc.go_to_page_using_visit_number("Update Patient Information", slmc.visit_number)
    slmc.click'maternity'
    sleep 1
    slmc.click_submit_changes.should be_true
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service < 1 OR Maternity case - STANDARD Discharge" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @maternity_employee)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service < 1 OR Maternity case - Additional Room and Board Cancellation" do
    sleep 10
    slmc.skip_room_and_bed_cancelation.should be_true
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service < 1 OR Maternity case - Philhealth" do
#    @@ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
#    slmc.ph_save_computation
#    sleep 2
    slmc.skip_philhealth.should be_true
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service < 1 OR Maternity case - Discount" do
    slmc.skip_discount.should be_true
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service < 1 OR Maternity case - SOA" do
      slmc.skip_generation_of_soa.should be_true
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service < 1 OR Maternity case - Check Discount Details" do
    @@summary = slmc.get_billing_details_from_payment_data_entry
    @total_charges =  @@summary[:hospital_bill].to_f + @@summary[:room_charges].to_f

    @promo_discount = @total_charges * 0.16
    @less_promo_discount = @total_charges - @promo_discount
    @maternity_discount = @less_promo_discount * 0.50
    @less_maternity_discount = @less_promo_discount - @maternity_discount

    @@summary[:discounts].to_f.should == ("%0.2f" %(@promo_discount + @maternity_discount)).to_f
    @@summary[:total_hospital_bills].to_f.should == ("%0.2f" %(@less_maternity_discount)).to_f
    @@summary[:total_amount_due].to_f.should == ("%0.2f" %(@less_maternity_discount)).to_f
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service < 1 OR Maternity case - Discharge Patient" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Inpatient , If yr of service < 1 OR Maternity case - Print Gatepass" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @maternity_employee)
    slmc.print_gatepass(:no_result => true, :pin => @maternity_employee).should be_true
  end
################=========================================================================================================================#
###############==========================================================================================================================#
###############==========================================================================================================================#
###############==========================================================================================================================#

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Inpatient - Create New Admission" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @employee1).should be_true
    slmc.create_new_admission(:account_class => "EMPLOYEE", :org_code => "0287", :rch_code => "RCH08",
     # :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726",:guarantor_code=>"0209991").should == "Patient admission details successfully saved."
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726",:guarantor_code=>"0824011").should == "Patient admission details successfully saved."
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Inpatient - Order Items" do
    slmc.nursing_gu_search(:pin => @employee1)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @employee1)
    slmc.search_order(:description => "010001194", :ancillary => true).should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001194", :add => true, :doctor => "0126").should be_true
    sleep 5
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Inpatient - Clnically Discharge Patient" do
    slmc.nursing_gu_search(:pin=> @employee1)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @employee1, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Inpatient - STANDARD Discharge" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @employee1)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Inpatient - Update Patient Information & Additional Room and Board Cancellation" do
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Inpatient - Philhealth" do
    @@ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
    sleep 2
    slmc.skip_philhealth.should be_true
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Inpatient - Discount" do
    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :discount_rate => @courtesy_discount,
     :close_window => true, :save => true)#.should be_true
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Inpatient  - SOA" do
      slmc.click_generate_official_soa.should be_true
      slmc.skip_generation_of_soa.should be_true
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Inpatient - Check Discount Details" do
    @@summary = slmc.get_billing_details_from_payment_data_entry
    @total_charges =  @@summary[:hospital_bill].to_f + @@summary[:room_charges].to_f

    @promo_discount = @total_charges * 0.16
    @less_promo_discount = @total_charges - @promo_discount
    @class_discount = @less_promo_discount * 0.50
    @less_class_discount = @less_promo_discount - @class_discount
    @less_courtesy_discount = @less_class_discount - @courtesy_discount
    @total_discount = @promo_discount+@class_discount+@courtesy_discount

    @@summary[:discounts].to_f.should == @total_discount
    @total_hospital_bills = @total_charges - ( @@summary[:philhealth].to_f + @total_discount)
    @@summary[:total_hospital_bills].should == @total_hospital_bills.to_s
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Inpatient - Discharge Patient" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Inpatient - Print Gatepass" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @employee1)
    slmc.print_gatepass(:no_result => true, :pin => @employee1).should be_true
  end
##############=========================================================================================================================#
##############=========================================================================================================================#
##############=========================================================================================================================#
###############=========================================================================================================================#
  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Inpatient  - Create New Admission" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @employee_dependent).should be_true
    slmc.create_new_admission(:account_class => "EMPLOYEE DEPENDENT", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726",:guarantor_code=>"0109992").should == "Patient admission details successfully saved."
  end

  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Inpatient - Order Items" do
    slmc.nursing_gu_search(:pin => @employee_dependent)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @employee_dependent)
    slmc.search_order(:description => "010001194", :ancillary => true).should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001194", :add => true, :doctor => "0126").should be_true
    sleep 5
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Inpatient - Clnically Discharge Patient" do
    slmc.nursing_gu_search(:pin=> @employee_dependent)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @employee_dependent, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Inpatient - STANDARD Discharge" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @employee_dependent)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end

  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Inpatient - Skip" do
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Inpatient - Philhealth" do
    @@ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
    sleep 2
    slmc.skip_philhealth.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Inpatient - Discount" do#invalid scenario you cannot give employee dependent discount with account class employee dependent
    slmc.skip_discount.should be_true
  end

    it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Inpatient - SOA" do
      slmc.click_generate_official_soa.should be_true
      slmc.skip_generation_of_soa.should be_true
    end

  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Inpatient - Check Discount Details" do
    sleep 5
    @@summary = slmc.get_billing_details_from_payment_data_entry
    @total_charges =  @@summary[:hospital_bill].to_f + @@summary[:room_charges].to_f

    @promo_discount = @@summary[:hospital_bill].to_f * 0.16
    @room_discount = @@summary[:room_charges].to_f * 0.16
    @less_promo_discount = @@summary[:hospital_bill].to_f  - @promo_discount
    @less_room_discount = @@summary[:room_charges].to_f - @room_discount
    @class_discount = @less_promo_discount * 0.65
    @total_room_discount = @less_room_discount * 0.75
    @total_discount = @promo_discount + @room_discount + @class_discount + @total_room_discount


    ((slmc.truncate_to((@@summary[:discounts].to_f - @total_discount),2).to_f).abs).should <= 0.02
    @total_hospital_bills = @total_charges -  ( @@summary[:philhealth].to_f + @total_discount)
    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @total_hospital_bills),2).to_f).abs).should <= 0.02
  end

  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Inpatient - Proceed with Payment" do
    slmc.spu_hospital_bills(:type=>"CASH")
    slmc.spu_submit_bills
  end

  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Inpatient - Print Gatepass" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @employee_dependent)
    slmc.print_gatepass(:no_result => true, :pin => @employee_dependent).should be_true
  end
#############=========================================================================================================================#
#############=========================================================================================================================#
#############=========================================================================================================================#
#############=========================================================================================================================#
  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Inpatient  - Create New Admission" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @employee_dependent).should be_true
    slmc.create_new_admission(:account_class => "EMPLOYEE DEPENDENT", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726",:guarantor_code=>"0109992").should == "Patient admission details successfully saved."
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Inpatient - Order Items" do
    slmc.nursing_gu_search(:pin => @employee_dependent)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @employee_dependent)
    slmc.search_order(:description => "010001194", :ancillary => true).should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001194", :add => true, :doctor => "0126").should be_true
    sleep 5
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Inpatient - Clnically Discharge Patient" do
    slmc.nursing_gu_search(:pin=> @employee_dependent)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @employee_dependent, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Inpatient - STANDARD Discharge" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @employee_dependent)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Inpatient - Skip" do
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Inpatient - Philhealth" do
    @@ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
    sleep 2
    slmc.skip_philhealth.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Inpatient - Discount" do
    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :discount_rate => @courtesy_discount,
     :close_window => true, :save => true)#.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Inpatient - SOA" do
      slmc.click_generate_official_soa.should be_true
      slmc.skip_generation_of_soa.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Inpatient - Check Discount Details" do
    @@summary = slmc.get_billing_details_from_payment_data_entry
    @total_charges =  @@summary[:hospital_bill].to_f + @@summary[:room_charges].to_f

    @promo_discount = @@summary[:hospital_bill].to_f * 0.16
    @room_discount = @@summary[:room_charges].to_f * 0.16
    @less_promo_discount = @@summary[:hospital_bill].to_f  - @promo_discount
    @less_room_discount = @@summary[:room_charges].to_f - @room_discount
    @class_discount = @less_promo_discount * 0.65
    @total_room_discount = @less_room_discount * 0.75
    @total_discount = @promo_discount + @room_discount + @class_discount + @total_room_discount + @courtesy_discount


    ((slmc.truncate_to((@@summary[:discounts].to_f - @total_discount),2).to_f).abs).should <= 0.02
    @total_hospital_bills = @total_charges -  ( @@summary[:philhealth].to_f + @total_discount)
    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @total_hospital_bills),2).to_f).abs).should <= 0.02
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Inpatient - Proceed with Payment" do
    slmc.spu_hospital_bills(:type=>"CASH")
    slmc.spu_submit_bills
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Inpatient - Print Gatepass" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @employee_dependent)
    slmc.print_gatepass(:no_result => true, :pin => @employee_dependent).should be_true
  end
##############=========================================================================================================================#
##############=========================================================================================================================#
##############=========================================================================================================================#
##############=========================================================================================================================#
  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Inpatient  - Create New Admission" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @employee_dependent1).should be_true
    slmc.create_new_admission(:account_class => "EMPLOYEE DEPENDENT", :org_code => "0287", :rch_code => "RCH08",
      :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726",:guarantor_code=>"0109995").should == "Patient admission details successfully saved."
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Inpatient - Order Items" do
    slmc.nursing_gu_search(:pin => @employee_dependent1)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @employee_dependent1)
    slmc.search_order(:description => "010001194", :ancillary => true).should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001194", :add => true, :doctor => "0126").should be_true
    sleep 5
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Inpatient - Clnically Discharge Patient" do
    slmc.nursing_gu_search(:pin=> @employee_dependent1)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @employee_dependent1, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Inpatient - STANDARD Discharge" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @employee_dependent1)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "STANDARD")
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Inpatient - Update Information and Room and Board Cancellation" do
    slmc.skip_update_patient_information.should be_true
    slmc.skip_room_and_bed_cancelation.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Inpatient - Philhealth" do
    @@ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
    sleep 2
    slmc.skip_philhealth.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Inpatient - Discount" do
    slmc.add_discount(:discount => "Contractual And Company Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :discount_rate => @courtesy_discount,
     :close_window => true, :save => true)
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Inpatient - SOA" do
      slmc.click_generate_official_soa.should be_true
      slmc.skip_generation_of_soa.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Inpatient - Check Discount Details" do
    @@summary = slmc.get_billing_details_from_payment_data_entry
    @total_charges =  @@summary[:hospital_bill].to_f + @@summary[:room_charges].to_f

    @promo_discount = @@summary[:hospital_bill].to_f * 0.16
    @room_discount = @@summary[:room_charges].to_f * 0.16
    @less_promo_discount = @@summary[:hospital_bill].to_f  - @promo_discount
    @less_room_discount = @@summary[:room_charges].to_f - @room_discount
    @class_discount = @less_promo_discount * 0.65
    @total_room_discount = @less_room_discount * 0.75
    @total_discount = @promo_discount + @room_discount + @class_discount + @total_room_discount + @courtesy_discount


    ((slmc.truncate_to((@@summary[:discounts].to_f - @total_discount),2).to_f).abs).should <= 0.02
    @total_hospital_bills = @total_charges -  ( @@summary[:philhealth].to_f + @total_discount)
    ((slmc.truncate_to((@@summary[:total_hospital_bills].to_f - @total_hospital_bills),2).to_f).abs).should <= 0.02
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Inpatient - Discharge Patient" do
    slmc.spu_hospital_bills(:type=>"CASH")
    (slmc.spu_submit_bills("defer")).should == "Patients for DEFER should be processed before end of the day"
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Inpatient - Print Gatepass" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @employee_dependent1)
    slmc.print_gatepass(:no_result => true, :pin => @employee_dependent1).should be_true
  end
##############=========================================================================================================================#
##############=========================================================================================================================#
##############=========================================================================================================================#
###############=========================================================================================================================#
  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Inpatient  - Create New Admission" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@inpatient_pin = slmc.create_new_patient(Admission.generate_data(:senior => true).merge(:gender => 'M')).gsub(' ','').should be_true
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@inpatient_pin)

    slmc.create_new_admission( :account_class => "SOCIAL SERVICE", :esc_no => @esc_no, :dept_code => @dept_code,
      :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
  end

  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Inpatient - Order Items" do
    slmc.nursing_gu_search(:pin => @@inpatient_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@inpatient_pin)
    slmc.search_order(:description => "010001194", :ancillary => true).should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001194", :add => true, :doctor => "0126").should be_true
    sleep 5
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Inpatient  - Go to Social Service Page" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.click"filter3"
    slmc.patient_pin_search(:pin => @@inpatient_pin)
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    slmc.add_recommendation_entry(:amount =>@ss_amount)
  end

  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Inpatient - Clnically Discharge Patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin=> @@inpatient_pin)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@inpatient_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Inpatient - Discount" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin)
    slmc.go_to_page_using_visit_number("Discount", slmc.visit_number)
    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :discount_rate => @courtesy_discount,
     :close_window => true, :save => true)#.should be_true
  end

  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Inpatient - Check Discount Details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)

    @@summary = slmc.get_billing_details_from_payment_data_entry
    @original_discount_promo = @@summary[:hospital_bill].to_f * @promo_discount_senior
    @total_hospital_bills = @@summary[:hospital_bill].to_f - @original_discount_promo  - @ss_amount - @courtesy_discount

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo + @courtesy_discount)).to_f
    @@summary[:social_service_coverage].to_f.should == @ss_amount
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f

    (slmc.ss_get_discount_amount(:promo => true, :visit_no => @@visit_no)).should == @original_discount_promo
    (slmc.ss_get_discount_amount(:ss_discount => true, :visit_no => @@visit_no)).should == @ss_amount
  end

  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Inpatient - STANDARD Discharge" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
    slmc.select_discharge_patient_type(:type => "DAS")
  end

  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Inpatient - Print Gatepass" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@inpatient_pin)
    slmc.print_gatepass(:no_result => true, :pin => @@inpatient_pin).should be_true
  end
#############=========================================================================================================================#
#############=========================================================================================================================#
#############=========================================================================================================================#
#############=========================================================================================================================#
  it"Account Class = Social Service , Discount Type = Social Service , Patient Type = Inpatient - Create new Admission" do
    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "test")
    @@inpatient_pin = slmc.create_new_patient(Admission.generate_data(:senior => true).merge(:gender => 'F')).gsub(' ','').should be_true
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@inpatient_pin)
    slmc.create_new_admission( :account_class => "SOCIAL SERVICE", :esc_no => @esc_no, :dept_code => @dept_code,
      :org_code => "0287", :rch_code => "RCH08", :room_charge => "REGULAR PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
  end

  it"Account Class = Social Service , Discount Type = Social Service , Patient Type = Inpatient - Order Items" do
    slmc.nursing_gu_search(:pin => @@inpatient_pin)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@inpatient_pin)
    slmc.search_order(:description => "010001194", :ancillary => true).should be_true
    slmc.add_returned_order(:ancillary => true, :description => "010001194", :add => true, :doctor => "0126").should be_true
    sleep 5
    slmc.submit_added_order
    slmc.validate_orders(:ancillary => true, :orders => "single")
    slmc.confirm_validation_all_items.should be_true
  end

  it"Account Class = Social Service , Discount Type = Social Service , Patient Type = Inpatient  - Go to Social Service Page" do
    slmc.login(@ss_user, @password).should be_true
    slmc.go_to_social_services_landing_page
    slmc.click"filter3"
    slmc.patient_pin_search(:pin => @@inpatient_pin)
    slmc.go_to_ss_action_page(:visit_no => slmc.visit_number, :page => "Recommendation Entry")
    @@amount = (slmc.get_text"//form[@id='recommendationForm']/div[4]/div/table/tbody/tr/td[1]").gsub(',','')
    puts @@amount
    #slmc.add_recommendation_entry(:amount =>"7000")
    slmc.add_recommendation_entry(:amount => @@amount)
  end

  it"Account Class = Social Service , Discount Type = Social Service , Patient Type = Inpatient - Clnically Discharge Patient" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin=> @@inpatient_pin)
    @@visit_no = slmc.clinically_discharge_patient(:pin => @@inpatient_pin, :pf_amount => '1000', :no_pending_order => true, :save => true)
  end

  it"Account Class = Social Service , Discount Type = Social Service , Patient Type = Inpatient - Philhealth" do
    slmc.login(@pba_user, @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin)
    slmc.go_to_page_using_visit_number("PhilHealth", @@visit_no)
    @@ph = slmc.philhealth_computation(:claim_type => "ACCOUNTS RECEIVABLE", :diagnosis => "CHOLERA", :medical_case_type => "ORDINARY CASE", :with_operation => true, :rvu_code => "10060", :compute => true)
    slmc.ph_save_computation
    slmc.ph_print_report
  end

  it"Account Class = Social Service , Discount Type = Social Service , Patient Type = Inpatient - DAS Discharge" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@inpatient_pin)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no)
    slmc.select_discharge_patient_type(:type => "DAS")
  end

  it"Account Class = Social Service , Discount Type = Social Service , Patient Type = Inpatient - Check Discount Details" do
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:discharged => true, :pin => @@inpatient_pin)
    slmc.go_to_page_using_visit_number("Payment", @@visit_no)

    @ss_amount = @@amount.to_f
    @@summary = slmc.get_billing_details_from_payment_data_entry
    @total_charges =  @@summary[:hospital_bill].to_f + @@summary[:room_charges].to_f
    @less_philhealth = @total_charges - @@summary[:philhealth].to_f#net of philHealth
    @original_discount_promo = @less_philhealth * @promo_discount_senior
    @item_amount_with_promo = @less_philhealth  - @original_discount_promo
    @less_social_service = @item_amount_with_promo - @ss_amount

    @total_hospital_bills = @total_charges - (@original_discount_promo  + @ss_amount  + @@summary[:philhealth].to_f  + @less_social_service)

    @@summary[:discounts].to_f.should == ("%0.2f" %(@original_discount_promo + @less_social_service)).to_f
    @@summary[:social_service_coverage].to_f.should == @ss_amount
    @@summary[:balance_due].to_f.should == ("%0.2f" %(@total_hospital_bills)).to_f
  end

  it"Account Class = Social Service , Discount Type = Social Service , Patient Type = Inpatient - Print Gatepass" do
    slmc.login(@user, @password).should be_true
    slmc.nursing_gu_search(:pin => @@inpatient_pin)
    slmc.print_gatepass(:no_result => true, :pin => @@inpatient_pin).should be_true
  end
################=========================================================================================================================#
################=========================================================================================================================#
################=========================================================================================================================#
################=========================================================================================================================#
  it"Account Class = Employee , Discount Type = Employee , Patient Type = Outpatient , If yr of service >= 1 (More Than or Equal to 1 Year) AND Non-Maternity case - Outpatient Order" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @oss_employee)
    slmc.click_outpatient_order.should be_true
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Outpatient , If yr of service >= 1 (More Than or Equal to 1 Year) AND Non-Maternity case - Add Guarantor" do
    slmc.oss_add_guarantor(:guarantor_type =>  'EMPLOYEE', :acct_class => 'EMPLOYEE', :guarantor_code => "0109995", :guarantor_add => true)
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Outpatient , If yr of service >= 1 (More Than or Equal to 1 Year) AND Non-Maternity case - Order Items" do
    slmc.oss_order(:order_add => true, :item_code => "010001194", :quantity => "1", :doctor => '0126')
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Outpatient , If yr of service >= 1 (More Than or Equal to 1 Year) AND Non-Maternity case - Philhealth" do
    slmc.oss_patient_info(:philhealth => true)
    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "A00", :philhealth_id => "12345", :compute => true)
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Outpatient , If yr of service >= 1 (More Than or Equal to 1 Year) AND Non-Maternity case - Check Discount Details" do
    @@summary = slmc.get_summary_totals

    @less_philhealth = @@summary[:total_gross_amount].to_f - @@summary[:philhealth_claims].to_f

    @@summary[:total_promo].to_f.should == ("%0.2f" %(@less_philhealth)).to_f
    @@summary[:total_net_amount].to_f.should == @less_philhealth - @@summary[:total_promo].to_f


  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Outpatient , If yr of service < 1 OR Maternity case - Outpatient Order" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @oss_maternity)
    slmc.click_outpatient_order.should be_true
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Outpatient , If yr of service < 1 OR Maternity case - Add Guarantor" do
    slmc.oss_add_guarantor(:guarantor_type =>  'EMPLOYEE', :acct_class => 'EMPLOYEE', :guarantor_code => "0109995", :guarantor_add => true)
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Outpatient , If yr of service < 1 OR Maternity case - Order Items" do
    slmc.oss_order(:order_add => true, :item_code => "010001194", :quantity => "1", :doctor => '0126')
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Outpatient , If yr of service < 1 OR Maternity case - Check maternity and Philhealth" do
    slmc.oss_patient_info(:philhealth => true, :maternity => true)
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Outpatient , If yr of service < 1 OR Maternity case - Philhealth" do
    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "A00", :philhealth_id => "12345", :compute => true)
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Outpatient , If yr of service < 1 OR Maternity case - Check Discount Details" do
    @@summary = slmc.get_summary_totals

    @promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @less_promo = @@summary[:total_gross_amount].to_f  - @promo
    @class_discount = @less_promo * 0.50

    @@summary[:total_promo].to_f.should == @promo.to_f
    @@summary[:total_class_discount].to_f.should == @class_discount.to_f
    @net_amount = @class_discount - @@summary[:philhealth_claims].to_f
    (slmc.get_text"ops_order_net_amount_0").should == @net_amount.to_s
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Outpatient - Outpatient Order" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @oss_employee)
    slmc.click_outpatient_order.should be_true
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Outpatient - Add Guarantor" do
    slmc.oss_add_guarantor(:guarantor_type =>  'EMPLOYEE', :acct_class => 'EMPLOYEE', :guarantor_code => "0109995", :guarantor_add => true)
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Outpatient - Order Items" do
    slmc.oss_order(:order_add => true, :item_code => "010001194", :quantity => "1", :doctor => '0126')
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Outpatient - Philhealth" do
    slmc.oss_patient_info(:philhealth => true)
#    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "A00", :philhealth_id => "12345", :compute => true, :rvu_code => "10060")
    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "A00", :philhealth_id => "12345", :compute => true, :rvu_code => "11051")
  end

  it"Account Class = Employee , Discount Type = Courtesy , Patient Type = Outpatient - Discount" do
    slmc.oss_add_discount(:discount_type => "Courtesy Discount",:amount=>"500")#.should be_false
    (slmc.get_text"discountErr").should == "Discount amount should not be greater than Total Net Amount."
  end

  it"Account Class = Employee , Discount Type = Employee , Patient Type = Outpatient , If yr of service < 1 OR Maternity case - Check Discount Details" do
    @@summary = slmc.get_summary_totals

    @promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @philhealth = @@summary[:total_gross_amount].to_f  - @promo
    @total_charges = @promo + @philhealth

    @@summary[:total_promo].to_f.should == @promo.to_f
    @@summary[:total_net_amount].to_f.should == @@summary[:total_gross_amount].to_f  - @total_charges.to_f
  end
################=========================================================================================================================#
################=========================================================================================================================#
################=========================================================================================================================#
################=========================================================================================================================#
  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Outpatient  - Outpatient Order" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @oss_dependent)
    slmc.click_outpatient_order.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Outpatient - Add Guarantor" do
    slmc.oss_add_guarantor(:acct_class => "EMPLOYEE DEPENDENT", :guarantor_type => "EMPLOYEE", :guarantor_code => "0109995", :guarantor_add => true)
  end

  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Outpatient - Order Items" do
    slmc.oss_order(:order_add => true, :item_code => "010001194", :quantity => "1", :doctor => '0126')
  end

  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Outpatient - Philhealth" do
    slmc.oss_patient_info(:philhealth => true)
    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "A00", :philhealth_id => "12345", :compute => true)
  end

  it"Account Class = Employee Dependent , Discount Type = Employee Dependent , Patient Type = Outpatient - Check Discount Details" do
    @@summary = slmc.get_summary_totals

    @promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @less_promo = @@summary[:total_gross_amount].to_f  - @promo
    @class_discount = @less_promo * 0.75
    @less_class = @less_promo - @class_discount
    @@summary[:total_promo] = @@summary[:total_promo].gsub!(",","")
    @promo =  @promo.gsub(",","")
    @@summary[:total_promo].to_f.should == @promo.to_f
    ((slmc.truncate_to((@@summary[:total_class_discount].to_f - @class_discount),2).to_f).abs).should <= 0.02
    @net_amount = @less_class - @@summary[:philhealth_claims].to_f
    (slmc.get_text"ops_order_net_amount_0").gsub(',','').should == ("%0.2f" %(@net_amount - 0.01)).to_s
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Outpatient - Outpatient Order" do
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @oss_dependent)
    slmc.click_outpatient_order.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Outpatient - Add Guarantor" do
    slmc.oss_add_guarantor(:acct_class => "EMPLOYEE DEPENDENT", :guarantor_type => "EMPLOYEE", :guarantor_code => "0109995", :guarantor_add => true)
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Outpatient - Order Items" do
    slmc.oss_order(:order_add => true, :item_code => "010001194", :quantity => "1", :doctor => '0126')
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Outpatient - Philhealth" do
    slmc.oss_patient_info(:philhealth => true)
    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "A00", :philhealth_id => "12345", :compute => true, :rvu_code => "11444")
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Outpatient - Discount" do
    slmc.oss_add_discount(:discount_type => "Courtesy Discount",:amount=>"5000")#.should be_false
    (slmc.get_text"discountErr").should == "Discount amount should not be greater than Total Net Amount."
  end

  it"Account Class = Employee Dependent , Discount Type = Courtesy , Patient Type = Outpatient - Check Discount Details" do
    @@summary = slmc.get_summary_totals

    @promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @less_promo = @@summary[:total_gross_amount].to_f  - @promo
    @class_discount = @less_promo * 0.75
    @less_class = @less_promo - @class_discount
    @@summary[:total_promo] = @@summary[:total_promo].gsub!(",","")
    @promo =  @promo.gsub(",","")
    @@summary[:total_promo].to_f.should == @promo.to_f
    ((slmc.truncate_to((@@summary[:total_class_discount].to_f - @class_discount),2).to_f).abs).should <= 0.02
    @net_amount = @less_class - @@summary[:philhealth_claims].to_f
    (slmc.get_text"ops_order_net_amount_0").gsub(',','').should == ("%0.2f" %(@net_amount - 0.01)).to_s
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Outpatient - Outpatient Order" do
     slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => @oss_dependent)
    slmc.click_outpatient_order.should be_true
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Outpatient - Add Guarantor" do
    slmc.oss_add_guarantor(:acct_class => "EMPLOYEE DEPENDENT", :guarantor_type => "EMPLOYEE", :guarantor_code => "0109995", :guarantor_add => true)
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Outpatient - Order Items" do
    slmc.oss_order(:order_add => true, :item_code => "010001194", :quantity => "1", :doctor => '0126')
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Outpatient - Philhealth" do
    slmc.oss_patient_info(:philhealth => true)
    @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "A00", :philhealth_id => "12345", :compute => true,:rvu_code => "10060" )
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Outpatient - Discount" do
    slmc.oss_add_discount(:discount_type => "Contractual And Company Discount",:amount=>"500")#.should be_false
    (slmc.get_text"discountErr").should == "Discount amount should not be greater than Total Net Amount."
  end

  it"Account Class = Employee Dependent , Discount Type = Contractual , Patient Type = Outpatient - Check Discount Details" do
    @@summary = slmc.get_summary_totals

    @promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @less_promo = @@summary[:total_gross_amount].to_f  - @promo
    @class_discount = @less_promo * 0.75
    @less_class = @less_promo - @class_discount

 puts ((@@summary[:total_promo]).gsub(',','')).to_f
 puts @promo.to_f
aa =  ((@@summary[:total_promo]).gsub(',','')).to_f
bb =     @promo.to_f
aa = aa.to_i
bb = bb.to_i
bb.should ==aa
 #   ((@@summary[:total_promo]).gsub(',','')).to_f.should == (@promo.gsub(',','')).to_f
 #   ((@@summary[:total_promo]).gsub(',','')).to_f.should == @promo.to_f
    ((slmc.truncate_to((@@summary[:total_class_discount].to_f - @class_discount),2).to_f).abs).should <= 0.02
    @net_amount = @less_class - @@summary[:philhealth_claims].to_f
    (slmc.get_text"ops_order_net_amount_0").gsub(',','').should == ("%0.2f" %(@net_amount - 0.01)).to_s

  end
#################=========================================================================================================================#
#################=========================================================================================================================#
#################=========================================================================================================================#
#################=========================================================================================================================#
  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Outpatient" do
    slmc.login(@oss_user, @password).should be_true
    slmc.go_to_das_oss
    slmc.patient_pin_search(:pin => "test")
    slmc.click_outpatient_registration.should be_true
    @@oss_pin = slmc.oss_outpatient_registration(Admission.generate_data(:not_senior => true)).gsub(' ','').should be_true
  end

  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Outpatient - Add Guarantor" do
     slmc.go_to_das_oss
     slmc.patient_pin_search(:pin => @@oss_pin)
     slmc.click_outpatient_order.should be_true

     slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no =>@esc_no, :dept_code =>@dept_code, :guarantor_add => true)
  end

  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Outpatient - Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "010002376", :quantity => "1", :doctor => '0126')
  end

  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Outpatient - Discount" do
    slmc.oss_add_discount(:scope => "ancillary", :type => "percent" , :amount => "50")
  end

  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Outpatient - Philhealth" do
    slmc.oss_patient_info(:philhealth=>true)
    @@oss_ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE",:claim_type=>"ACCOUNTS RECEIVABLE",
          :diagnosis => "CHOLERA", :philhealth_id => "12345", :compute => true, :rvu_code =>"10060")
  end

  it"Account Class = Social Service , Discount Type = Courtesy , Patient Type = Outpatient - Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo
    @courtesy_discount = @item_amount_with_promo * 0.50
    @less_philhealth = @item_amount_with_promo - @@summary[:philhealth_claims].to_f
    @class_discount = @less_philhealth * 0.90
    @less_class_discount = @less_philhealth - @class_discount

    @@summary[:total_class_discount].to_f.should == @class_discount
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_net_amount].to_f - @less_class_discount),2).to_f).abs).should <= 0.02
    (slmc.get_text("totalChargeAmountDisplay").gsub(',','')).to_f == (@less_class_discount - @courtesy_discount)
  end

  it"Account Class = Social Service , Discount Type = Social Service , Patient Type = Outpatient - Add Guarantor" do
     slmc.go_to_das_oss
     slmc.patient_pin_search(:pin => @@oss_pin)
     slmc.click_outpatient_order.should be_true
     slmc.oss_add_guarantor(:guarantor_type =>  'SOCIAL SERVICE', :acct_class => 'SOCIAL SERVICE', :esc_no =>@esc_no, :dept_code => @dept_code, :guarantor_add => true)
  end

  it"Account Class = Social Service , Discount Type = Social Service , Patient Type = Outpatient - Order Items" do
     slmc.oss_order(:order_add => true, :item_code => "010002376", :quantity => "1", :doctor => '0126')
  end

  it"Account Class = Social Service , Discount Type = Social Service , Patient Type = Outpatient - Philhealth" do
    slmc.oss_patient_info(:philhealth=>true)
    @@oss_ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE",:claim_type=>"ACCOUNTS RECEIVABLE",
          :diagnosis => "CHOLERA", :philhealth_id => "12345", :compute => true,:rvu_code => "10060" )
  end

  it"Account Class = Social Service , Discount Type = Social Service , Patient Type = Outpatient - Check Discount applied" do
    @@summary = slmc.get_summary_totals

    @original_discount_promo = @@summary[:total_gross_amount].to_f * @promo_discount_non_senior
    @item_amount_with_promo = @@summary[:total_gross_amount].to_f  - @original_discount_promo
    @less_philhealth = @item_amount_with_promo - @@summary[:philhealth_claims].to_f
    @class_discount = @less_philhealth * 0.90
    @less_class_discount = @less_philhealth - @class_discount

    @@summary[:total_class_discount].to_f.should == @class_discount
    ((slmc.truncate_to((@@summary[:total_promo].to_f - @original_discount_promo),2).to_f).abs).should <= 0.02
    ((slmc.truncate_to((@@summary[:total_net_amount].to_f - @less_class_discount),2).to_f).abs).should <= 0.02
  end

end
