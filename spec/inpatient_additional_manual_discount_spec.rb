#require File.dirname(__FILE__) + '/../lib/slmc'

require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
require 'spec_helper'
require 'yaml'

describe "SLMC :: Inpatient Manual Discount Type" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session

    @individual_patient = Admission.generate_data
    @hmo_patient = Admission.generate_data
    @company_patient = Admission.generate_data
    @social_service_patient = Admission.generate_data
    @womens_board_member_patient = Admission.generate_data
    @womens_board_dependent_patient = Admission.generate_data

    @user = "gu_spec_user8"
    @password = "123qweuser"

    @drugs = {"040000357" => 1}
    @ancillary = {"010000003" => 1}
    @supplies = {"080100021" => 1}

#    @@employee = "1303029188"
#    @@employee_dependent = "1301028163"
#    @@board_member = "1303029195"
#    @@board_member_dependent = "1303029082"
#    @@doctor = "1301028149"
#    @@doctor_dependent = "1307040088"
    #@esc_no = "0004589"
    
@esc_no= "121024AG0012"


#    @@employee = "1006513839"
#    @@employee_dependent = "1502080612" "1504081720"
#    @@board_member ="1501078980"
#    @@board_member_dependent = "1501078984"
#    @@doctor ="1501078985"
#    @@doctor_dependent = "1501078813"  #conflict with discount outpatient spec

    @@employee = "1006513839"
    @@employee_dependent =  "1504081720"  #"1502080612"
    @@board_member =  "1504081734" #"1501078980"
    @@board_member_dependent = "1504081736" #"1501078984"
    @@doctor = "1504081738"   #"1501078985"
    @@doctor_dependent =  "1504081732"  #"1501078813" #conflict with discount outpatient spec


#       @@employee = "1006513839"
#    @@employee_dependent =  "1602026899"  #"1502080612"
#    @@board_member =  "1602026882" #"1501078980"
#    @@board_member_dependent = "1602026883" #"1501078984"
#    @@doctor = "1602026884"   #"1501078985"
#    @@doctor_dependent =  "1202173093"  #"1501078813" #conflict with discount outpatient spec
#    
 
    
@individual_discount_type =   ["", "Courtesy Discount", "Contractual And Company Discount", "Employee Discount", "Social Service", "Doctor Discount", "Board Member", "Women's Board Discount", "Package Discount", "Employee Dependent Discount", "Doctor Dependent Discount", "Room And Board Special Discount", "Citi Mercury Discount"]
    #@individual_discount_type = ["", "Courtesy Discount", "Contractual And Company Discount", "Employee Discount", "Social Service", "Doctor Discount", "Board Member", "Women's Board Discount", "Package Discount", "Employee Dependent Discount", "Doctor Dependent Discount", "Early Bird Promo Discount"]
    #@employee_discount_type = ["", "Courtesy Discount", "Employee Discount"] # as per Erlyn, employee and courtesy discount
     @employee_discount_type = ["", "Courtesy Discount", "Employee Discount", "Room And Board Special Discount"]
#    @employee_dependent_discount_type =["", "Courtesy Discount", "Contractual And Company Discount", "Employee Dependent Discount"]
    @employee_dependent_discount_type =["", "Courtesy Discount", "Contractual And Company Discount", "Employee Dependent Discount", "Room And Board Special Discount"]

    #@hmo_discount_type = ["", "Courtesy Discount", "Contractual And Company Discount", "Doctor Discount", "Package Discount", "Employee Dependent Discount", "Doctor Dependent Discount"]
    @hmo_discount_type = ["", "Courtesy Discount", "Contractual And Company Discount", "Anniversary Week Promo", "Room And Board Special Discount", "Early Bird Promo Discount"]
    #@company_discount_type = ["", "Courtesy Discount", "Contractual And Company Discount", "Social Service", "Package Discount", "Employee Dependent Discount", "Doctor Dependent Discount", "Early Bird Promo Discount"]
    @company_discount_type = ["", "Courtesy Discount", "Contractual And Company Discount", "Anniversary Week Promo", "Room And Board Special Discount", "Early Bird Promo Discount"]
#    @doctor_discount_type = ["", "Courtesy Discount", "Doctor Discount"]
    @doctor_discount_type = ["", "Courtesy Discount", "Doctor Discount", "Room And Board Special Discount"]
    #@doctor_dependent_discount_type = ["", "Courtesy Discount", "Contractual And Company Discount", "Doctor Dependent Discount"]
     #@doctor_dependent_discount_type  =  ["", "Courtesy Discount", "Doctor Dependent Discount", "Room And Board Special Discount"]
     @doctor_dependent_discount_type  =  ["", "Courtesy Discount", "Contractual And Company Discount", "Doctor Dependent Discount", "Room And Board Special Discount"]
    #@board_member_discount_type = ["", "Courtesy Discount", "Contractual And Company Discount", "Board Member"] #["", "Courtesy Discount"]
    @board_member_discount_type = ["", "Courtesy Discount", "Board Member", "Room And Board Special Discount"]
#   @board_member_dependent_discount_type = ["", "Courtesy Discount","Board Member"]
      @board_member_dependent_discount_type =  ["", "Courtesy Discount", "Board Member", "Room And Board Special Discount"]
      
    #@social_service_discount_type = ["", "Courtesy Discount", "Social Service", "Women's Board Discount"] #["", "Courtesy Discount", "Social Service"]
    @social_service_discount_type = ["", "Courtesy Discount", "Social Service"] #["", "Courtesy Discount", "Social Service"]
    @womens_board_member_discount_type = ["", "Courtesy Discount", "Women's Board Discount"]
    @womens_board_member_dependent_discount_type = ["", "Courtesy Discount", "Women's Board Discount"]
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end


#  it "Account Class : Individual - Create and Admits patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@individual = slmc.create_new_patient(@individual_patient)
#        slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@individual)
#    slmc.create_new_admission(:room_charge => "DELUXE PRIVATE", :rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
# puts @@individual
#  end
#
#  it "Account Class : Individual - Order items" do
#    slmc.nursing_gu_search(:pin => @@individual)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@individual)
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
#    slmc.validate_orders(:drugs => true, :multiple => true).should == 1
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Account Class : Individual - Clinical Discharge patient" do
#    slmc.go_to_general_units_page
#    @@visit_no1 = slmc.clinically_discharge_patient(:pin => @@individual, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Account Class : Individual - Goes to Discount Page and Verifies Discount Type" do
#    slmc.login("ldcastro", @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@individual)
#    slmc.go_to_page_using_visit_number("Discount", @@visit_no1)
#
#    type = slmc.get_select_options("discountType")
#    type.should == @individual_discount_type
#   # (type.count).should == 12 # includes null + 11 original
#    (type.count).should == 13 # includes null + 11 original
#
#  end
#
#  it "Account Class : Employee - Create Patient and Admit patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@employee)
#    slmc.print_gatepass(:no_result => true, :pin => @@employee)
#    slmc.admission_search(:pin => @@employee)
#    if (slmc.get_text("results").gsub(' ', '').include? @@employee) && slmc.is_element_present("link=Admit Patient")
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "EMPLOYEE", :guarantor_code => "0109092").should == "Patient admission details successfully saved."
#    else
#      if slmc.is_text_present("NO PATIENT FOUND")
#        @@employee = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "Tan", :first_name => "Peter Carlo", :middle_name => "Go", :birth_day => "08/01/1986", :gender => "F"))
#      else
#        if slmc.verify_gu_patient_status(@@employee) != "Clinically Discharged"
#          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@employee, :validate => true, :username => "sel_0278_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
#          slmc.go_to_general_units_page
#          slmc.clinically_discharge_patient(:pin => @@employee, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#        end
#        slmc.login("ldcastro", @password).should be_true
#        slmc.go_to_patient_billing_accounting_page
#        slmc.pba_search(:with_discharge_notice => true, :pin => @@employee)
#        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#        slmc.select_discharge_patient_type(:type => "DAS").should be_true
#
#        slmc.login(@user, @password).should be_true
#        slmc.go_to_general_units_page
#        slmc.patient_pin_search(:pin => @@employee)
#        slmc.print_gatepass(:no_result => true, :pin => @@employee).should be_true
#      end
#      slmc.admission_search(:pin => @@employee)
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "EMPLOYEE", :guarantor_code => "0109092").should == "Patient admission details successfully saved."
#    end
#  end
#
#  it "Account Class : Employee - Order items" do
#    slmc.nursing_gu_search(:pin => @@employee)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@employee)
#    @drugs.each do |drug, q|
#      slmc.search_order(:description => drug, :drugs => true).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :supplies => true, :multiple => true).should == 1
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Account Class : Employee - Clinical Discharge patient" do
#    slmc.go_to_general_units_page
#    @@visit_no2 = slmc.clinically_discharge_patient(:pin => @@employee, :pf_amount => "1000", :no_pending_order => true, :save => true)
#  end
#
#  it "Account Class : Employee - Goes to Discount Page and Verifies Discount Type" do
#    slmc.login("ldcastro", @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@employee)
#    slmc.go_to_page_using_visit_number("Discount", @@visit_no2)
#
#    type = slmc.get_select_options("discountType")
#    type.should == @employee_discount_type
#   # (type.count).should == 3 # includes null + 2 original
#    (type.count).should == 4 # includes null + 2 original
#  end
#
#  it "Account Class : Employee Dependent - Create and Admit patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@employee_dependent)
#    slmc.print_gatepass(:no_result => true, :pin => @@employee_dependent)
#    slmc.admission_search(:pin => @@employee_dependent)
#    if (slmc.get_text("results").gsub(' ', '').include? @@employee_dependent) && slmc.is_element_present("link=Admit Patient")
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "EMPLOYEE DEPENDENT", :guarantor_code => "0109092").should == "Patient admission details successfully saved."
#    else
#      if slmc.is_text_present("NO PATIENT FOUND")
#        @@employee_dependent = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "Tan", :first_name => "Rachel Mae", :middle_name => "Go", :birth_day => "07/26/1987", :gender => "F"))
#      else
#        if slmc.verify_gu_patient_status(@@employee_dependent) != "Clinically Discharged"
#          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@employee_dependent, :validate => true, :username => "sel_0278_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
#          slmc.go_to_general_units_page
#          slmc.clinically_discharge_patient(:pin => @@employee_dependent, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#        end
#        slmc.login("ldcastro", @password).should be_true
#        slmc.go_to_patient_billing_accounting_page
#        slmc.pba_search(:with_discharge_notice => true, :pin => @@employee_dependent)
#        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#        slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#        slmc.discharge_to_payment.should be_true
#
#        slmc.login(@user, @password).should be_true
#        slmc.go_to_general_units_page
#        slmc.patient_pin_search(:pin => @@employee_dependent)
#        slmc.print_gatepass(:no_result => true, :pin => @@employee_dependent).should be_true
#      end
#      slmc.admission_search(:pin => @@employee_dependent)
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "EMPLOYEE DEPENDENT", :guarantor_code => "0109092").should == "Patient admission details successfully saved."
#    end
#  end
#
#  it "Account Class : Employee Dependent - Order items" do
#    slmc.nursing_gu_search(:pin => @@employee_dependent)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@employee_dependent)
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
#    slmc.validate_orders(:drugs => true, :multiple => true).should == 1
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Account Class : Employee Dependent - Clinical Discharge patient" do
#    slmc.go_to_general_units_page
#    @@visit_no3 = slmc.clinically_discharge_patient(:pin => @@employee_dependent, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Account Class : Employee Dependent - Goes to Discount Page and Verifies Discount Type" do
#    slmc.login("ldcastro", @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_disharge_notice => true, :pin => @@employee_dependent)
#    slmc.go_to_page_using_visit_number("Discount", @@visit_no3)
#
#    type = slmc.get_select_options("discountType")
#    type.should == @employee_dependent_discount_type
#    #(type.count).should == 4 # includes null + 3 original
#    (type.count).should == 5 # includes null + 3 original
#  end
#
#  it "Account Class : HMO - Create and Admit patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@hmo = slmc.create_new_patient(@hmo_patient)
#        slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@hmo)
#    slmc.create_new_admission(:account_class => "HMO", :room_charge => "DELUXE PRIVATE", :rch_code => "RCH07", :org_code => "0287", :guarantor_code => "ASAL002", :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
#  end
#
#  it "Account Class : HMO - Order items" do
#    slmc.nursing_gu_search(:pin => @@hmo)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@hmo)
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:drugs => true, :description => drug, :quantity => q, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
#    slmc.validate_orders(:drugs => true, :multiple => true).should == 1
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Account Class : HMO - Clinical Discharge patient" do
#    slmc.go_to_general_units_page
#    @@visit_no4 = slmc.clinically_discharge_patient(:pin => @@hmo, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Account Class : HMO - Goes to Discount Page and Verifies Discount Type" do
#    slmc.login("ldcastro", @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@hmo)
#    slmc.go_to_page_using_visit_number("Discount", @@visit_no4)
#
#    type = slmc.get_select_options("discountType")
#    type.should == @hmo_discount_type
##    (type.count).should == 7 # includes null + 6 original
#    (type.count).should == 6 # includes null + 6 original
#  end
#
#  it "Account Class : Company - Create and Admit patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@company = slmc.create_new_patient(@company_patient)
#        slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@company)
#    slmc.create_new_admission(:account_class => "COMPANY", :room_charge => "DELUXE PRIVATE", :rch_code => "RCH07", :org_code => "0287", :guarantor_code => "ABSC001", :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
#  end
#
#  it "Account Class : Company - Order items" do
#    slmc.nursing_gu_search(:pin => @@company)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@company)
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:drugs => true, :description => drug, :quantity => q, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
#    slmc.validate_orders(:drugs => true, :multiple => true).should == 1
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Account Class : Company - Clinical Discharge patient" do
#    slmc.go_to_general_units_page
#    @@visit_no5 = slmc.clinically_discharge_patient(:pin => @@company, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Account Class : Company - Goes to Discount Page and Verifies Discount Type" do
#    slmc.login("ldcastro", @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@company)
#    slmc.go_to_page_using_visit_number("Discount", @@visit_no5)
#
#    type = slmc.get_select_options("discountType")
#    type.should == @company_discount_type
#    #(type.count).should == 8 # includes null + 6 original
#    (type.count).should == 6 # includes null + 6 original
#  end
#
#  it "Account Class : Doctor - Create and Admit patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@doctor)
#    slmc.print_gatepass(:no_result => true, :pin => @@doctor)
#    slmc.admission_search(:pin => @@doctor)
#    if (slmc.get_text("results").gsub(' ', '').include? @@doctor) && slmc.is_element_present("link=Admit Patient")
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS", :account_class => "DOCTOR", :guarantor_code => "6055").should == "Patient admission details successfully saved."
#    else
#      if slmc.is_text_present("NO PATIENT FOUND")
#        @@doctor = slmc.create_new_patient(@pba_patient5.merge!(:last_name => "CARLOS", :first_name => "MARIE ARLENE", :middle_name => "DUMANDAN", :birth_day => "06/27/1973", :gender => "F"))
#      else
#        if slmc.verify_gu_patient_status(@@doctor) != "Clinically Discharged"
#          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@doctor, :validate => true, :username => "sel_0278_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
#          slmc.go_to_general_units_page
#          slmc.clinically_discharge_patient(:pin => @@doctor, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#        end
#        slmc.login("ldcastro", @password).should be_true
#        slmc.go_to_patient_billing_accounting_page
#        slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor)
#        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#        slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#        slmc.discharge_to_payment.should be_true
#
#        slmc.login(@user, @password).should be_true
#        slmc.go_to_general_units_page
#        slmc.patient_pin_search(:pin => @@doctor)
#        slmc.print_gatepass(:no_result => true, :pin => @@doctor).should be_true
#      end
#      slmc.admission_search(:pin => @@doctor)
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS", :account_class => "DOCTOR", :guarantor_code => "6055").should == "Patient admission details successfully saved."
#    end
#  end
#
#  it "Account Class : Doctor - Order items" do
#    slmc.nursing_gu_search(:pin => @@doctor)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@doctor)
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:drugs => true, :description => drug, :quantity => q, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
#    slmc.validate_orders(:drugs => true, :multiple => true).should == 1
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Account Class : Doctor - Clinical Discharge patient" do
#    slmc.go_to_general_units_page
#    @@visit_no6 = slmc.clinically_discharge_patient(:pin => @@doctor, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Account Class : Doctor - Goes to Discount Page and Verifies Discount Type" do
#    slmc.login("ldcastro", @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor)
#    slmc.go_to_page_using_visit_number("Discount", @@visit_no6)
#
#    type = slmc.get_select_options("discountType")
#    type.should == @doctor_discount_type
#    #(type.count).should == 3 # includes null + 2 original
#    (type.count).should == 4 # includes null + 2 original
#  end
#
#  it "Account Class : Doctor Dependent - Create and Admit patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@doctor_dependent)
#    slmc.print_gatepass(:no_result => true, :pin => @@doctor_dependent)
#    slmc.admission_search(:pin => @@doctor_dependent)
#    if (slmc.get_text("results").gsub(' ', '').include? @@doctor_dependent) && slmc.is_element_present("link=Admit Patient")
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "DOCTOR DEPENDENT", :guarantor_code => "3325").should == "Patient admission details successfully saved."
#    else
#      if slmc.is_text_present("NO PATIENT FOUND")
#        @@doctor_dependent = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "CARINO", :first_name => "GRACE", :middle_name => "L", :birth_day => "12/17/1956", :gender => "F"))
#      else
#        if slmc.verify_gu_patient_status(@@doctor_dependent) != "Clinically Discharged"
#          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@doctor_dependent, :validate => true, :username => "sel_0278_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
#          slmc.go_to_general_units_page
#          slmc.clinically_discharge_patient(:pin => @@doctor_dependent, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#        end
#        slmc.login("ldcastro", @password).should be_true
#        slmc.go_to_patient_billing_accounting_page
#        slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
#        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#        slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
#        slmc.discharge_to_payment.should be_true
#
#        slmc.login(@user, @password).should be_true
#        slmc.nursing_gu_search(:pin => @@doctor_dependent)
#        slmc.print_gatepass(:no_result => true, :pin => @@doctor_dependent).should be_true
#      end
#      slmc.admission_search(:pin => @@doctor_dependent)
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "DOCTOR DEPENDENT", :guarantor_code => "3325").should == "Patient admission details successfully saved."
#    end
#  end
#
#  it "Account Class : Doctor Dependent - Order items" do
#    slmc.nursing_gu_search(:pin => @@doctor_dependent)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@doctor_dependent)
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:drugs => true, :description => drug, :quantity => q, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
#    slmc.validate_orders(:drugs => true, :multiple => true).should == 1
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Account Class : Doctor Dependent - Clinical Discharge patient" do
#    slmc.go_to_general_units_page
#    @@visit_no7 = slmc.clinically_discharge_patient(:pin => @@doctor_dependent, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Account Class : Doctor Dependent - Goes to Discount Page and Verifies Discount Type" do
#    slmc.login("ldcastro", @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@doctor_dependent)
#    slmc.go_to_page_using_visit_number("Discount", @@visit_no7)
#
#    type = slmc.get_select_options("discountType")
#    type.should == @doctor_dependent_discount_type # this might get an error, as per steven in REF_DISCOUNT_CLASS, someone may change the settings
##    (type.count).should == 4 # includes null + 2 original
#    (type.count).should == 5 # includes null + 2 original
#
#  end
#
#  it "Account Class : Board Member - Create and Admit patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@board_member)
#    slmc.print_gatepass(:no_result => true, :pin => @@board_member)
#    slmc.admission_search(:pin => @@board_member)
#    if (slmc.get_text("results").gsub(' ', '').include? @@board_member) && slmc.is_element_present("link=Admit Patient")
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS", :account_class => "BOARD MEMBER", :guarantor_code => "BMAA001").should == "Patient admission details successfully saved."
#    else
#      if slmc.is_text_present("NO PATIENT FOUND")
#        @@board_member = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "ANCHETA", :first_name => "ALONZO", :middle_name => "Q", :birth_day => "10/30/1992", :gender => "M"))
#        @@board_member.should be_true
#      else
#        if slmc.verify_gu_patient_status(@@board_member) != "Clinically Discharged"
#          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@board_member, :validate => true, :username => "sel_0278_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
#          slmc.go_to_general_units_page
#          slmc.clinically_discharge_patient(:pin => @@board_member, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#        end
#        slmc.login("ldcastro", @password).should be_true
#        slmc.go_to_patient_billing_accounting_page
#        slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member)
#        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#        slmc.select_discharge_patient_type(:type => "DAS").should be_true
#
#        slmc.login(@user, @password).should be_true
#        slmc.go_to_general_units_page
#        slmc.patient_pin_search(:pin => @@board_member)
#        slmc.print_gatepass(:no_result => true, :pin => @@board_member)
#      end
#      slmc.admission_search(:pin => @@board_member)
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS", :account_class => "BOARD MEMBER", :guarantor_code => "BMAA001").should == "Patient admission details successfully saved."
#    end
#  end
#
#  it "Account Class : Board Member - Order items" do
#    slmc.nursing_gu_search(:pin => @@board_member)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@board_member)
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:drugs => true, :description => drug, :quantity => q, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
#    slmc.validate_orders(:drugs => true, :multiple => true).should == 1
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Account Class : Board Member - Clinical Discharge patient" do
#    slmc.go_to_general_units_page
#    @@visit_no8 = slmc.clinically_discharge_patient(:pin => @@board_member, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Account Class : Board Member - Goes to Discount Page and Verifies Discount Type" do
#    slmc.login("ldcastro", @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member)
#    slmc.go_to_page_using_visit_number("Discount", @@visit_no8)
#
#    type = slmc.get_select_options("discountType")
#    type.should == @board_member_discount_type
#    (type.count).should == 4 # includes null + 1 original
#  end
#
#  it "Account Class : Board Member Dependent - Create and Admit patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@board_member_dependent)
#    slmc.print_gatepass(:no_result => true, :pin => @@board_member_dependent)
#    slmc.admission_search(:pin => @@board_member_dependent)
#    if (slmc.get_text("results").gsub(' ', '').include? @@board_member_dependent) && slmc.is_element_present("link=Admit Patient")
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "BOARD MEMBER DEPENDENT", :guarantor_code => "BMAA001").should == "Patient admission details successfully saved."
#    else
#      if slmc.is_text_present("NO PATIENT FOUND")
#        @@board_member_dependent = slmc.create_new_patient(Admission.generate_data.merge(:last_name => "ANCHETA", :first_name => "BELLA", :middle_name => "CARIDAD", :birth_day => "09/25/1933", :gender => "F",:id_type1 => "SENIOR CITIZEN ID"))
#      else
#        if slmc.verify_gu_patient_status(@@board_member_dependent) != "Clinically Discharged"
#          slmc.validate_incomplete_orders(:inpatient => true, :pin => @@board_member_dependent, :validate => true, :username => "sel_0278_validator", :drugs => true, :ancillary => true, :supplies => true, :orders => "multiple")
#          slmc.go_to_general_units_page
#          slmc.clinically_discharge_patient(:pin => @@board_member_dependent, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#        end
#        slmc.login("ldcastro", @password).should be_true
#        slmc.go_to_patient_billing_accounting_page
#        slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member_dependent)
#        slmc.go_to_page_using_visit_number("Discharge Patient", slmc.visit_number)
#        slmc.select_discharge_patient_type(:type => "DAS").should be_true # BMDI 100% discount percentage
#
#        slmc.login(@user, @password).should be_true
#        slmc.nursing_gu_search(:pin => @@board_member_dependent)
#        slmc.print_gatepass(:no_result => true, :pin => @@board_member_dependent).should be_true
#      end
#      slmc.admission_search(:pin => @@board_member_dependent)
#      slmc.create_new_admission(:rch_code => "RCH07", :org_code => "0287", :diagnosis => "ULCER", :account_class => "BOARD MEMBER DEPENDENT", :guarantor_code => "BMAA001").should == "Patient admission details successfully saved."
#    end
#  end
#
#  it "Account Class : Board Member Dependent - Order items" do
#    slmc.nursing_gu_search(:pin => @@board_member_dependent)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@board_member_dependent)
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:drugs => true, :description => drug, :quantity => q, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
#    slmc.validate_orders(:drugs => true, :multiple => true).should == 1
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Account Class : Board Member Dependent - Clinical Discharge patient" do
#    slmc.go_to_general_units_page
#    @@visit_no9 = slmc.clinically_discharge_patient(:pin => @@board_member_dependent, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Account Class : Board Member Dependent - Goes to Discount Page and Verifies Discount Type" do
#    slmc.login("ldcastro", @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@board_member_dependent)
#    slmc.go_to_page_using_visit_number("Discount", @@visit_no9)
#
#    type = slmc.get_select_options("discountType")
#    type.should == @board_member_dependent_discount_type
#    #(type.count).should == 3 # includes null + 1 original
#    (type.count).should == 4 # includes null + 1 original
#  end
#
#  it "Account Class : Social Service - Admit and Creates patient" do
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@social_service = slmc.create_new_patient(@social_service_patient)
#        slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@social_service)
#    slmc.create_new_admission(:account_class => "SOCIAL SERVICE", :org_code => "0287", :rch_code => "RCH07", :room_charge => "DELUXE PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726", :esc_no => @esc_no).should == "Patient admission details successfully saved."
#  end
#
#  it "Account Class : Social Service - Order items" do
#    slmc.nursing_gu_search(:pin => @@social_service)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@social_service)
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:drugs => true, :description => drug, :quantity => q, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
#    slmc.validate_orders(:drugs => true, :multiple => true).should == 1
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Account Class : Social Service - Clinical Discharge patient" do
#    slmc.go_to_general_units_page
#    @@visit_no10 = slmc.clinically_discharge_patient(:pin => @@social_service, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Account Class : Social Service - Goes to Discount Page and Verifies Discount Type" do
#    slmc.login("ldcastro", @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@social_service)
#    slmc.go_to_page_using_visit_number("Discount", @@visit_no10)
#
#    type = slmc.get_select_options("discountType")
#    type.should == @social_service_discount_type
#   # (type.count).should == 4 # includes null + 3 original
#    (type.count).should == 3 # includes null + 3 original
#
#  end
#
#
###########  it "Account Class : Women's Board Member - Admit and Creates patient" do
###########    slmc.login(@user, @password).should be_true
###########    slmc.admission_search(:pin => "1")
###########    @@womens_board_member = slmc.create_new_patient(@womens_board_member_patient)
###########        slmc.login(@user, @password).should be_true
###########    slmc.admission_search(:pin => @@womens_board_member)
###########    slmc.create_new_admission(:account_class => "WOMEN'S BOARD MEMBER", :org_code => "0287", :rch_code => "RCH07", :room_charge => "DELUXE PRIVATE",
###########      :guarantor_code => "WOMB001", :diagnosis => "GASTRITIS", :doctor_code => "6726").should == "Patient admission details successfully saved."
###########  end
###########
###########  it "Account Class : Women's Board Member - Order items" do
###########    slmc.nursing_gu_search(:pin => @@womens_board_member)
###########    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@womens_board_member)
###########    @drugs.each do |drug, q|
###########      slmc.search_order(:drugs => true, :code => drug).should be_true
###########      slmc.add_returned_order(:drugs => true, :description => drug, :quantity => q, :frequency => "ONCE A WEEK", :add => true).should be_true
###########    end
###########    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
###########    slmc.validate_orders(:drugs => true, :multiple => true).should == 1
###########    slmc.confirm_validation_all_items.should be_true
###########  end
###########
###########  it "Account Class : Women's Board Member - Clinical Discharge patient" do
###########    slmc.go_to_general_units_page
###########    @@visit_no11 = slmc.clinically_discharge_patient(:pin => @@womens_board_member, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
###########  end
###########
###########  it "Account Class : Women's Board Member - Goes to Discount Page and Verifies Discount Type" do
###########    slmc.login("ldcastro", @password).should be_true
###########    slmc.go_to_patient_billing_accounting_page
###########    slmc.pba_search(:with_discharge_notice => true, :pin => @@womens_board_member)
###########    slmc.go_to_page_using_visit_number("Discount", @@visit_no11)
###########
###########    type = slmc.get_select_options("discountType")
###########    type.should == @womens_board_member_discount_type
###########    (type.count).should == 3 # includes null + 2 original
###########  end
###########
###########  it "Account Class : Women's Board Member Dependent - Admit and Creates patient" do
###########    slmc.login(@user, @password).should be_true
###########    slmc.admission_search(:pin => "1")
###########    @@womens_board_dependent = slmc.create_new_patient(@womens_board_dependent_patient)
###########        slmc.login(@user, @password).should be_true
###########    slmc.admission_search(:pin => @@womens_board_dependent)
###########    slmc.create_new_admission(:account_class => "WOMEN'S BOARD DEPENDENT", :org_code => "0287", :rch_code => "RCH07",
###########    :room_charge => "DELUXE PRIVATE", :diagnosis => "GASTRITIS", :doctor_code => "6726",  :guarantor_code => "WOMB001").should == "Patient admission details successfully saved."
###########  end
###########
###########  it "Account Class : Women's Board Member Dependent - Order items" do
###########    slmc.nursing_gu_search(:pin => @@womens_board_dependent)
###########    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@womens_board_dependent)
###########    @drugs.each do |drug, q|
###########      slmc.search_order(:drugs => true, :code => drug).should be_true
###########      slmc.add_returned_order(:drugs => true, :description => drug, :quantity => q, :frequency => "ONCE A WEEK", :add => true).should be_true
###########    end
###########    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
###########    slmc.validate_orders(:drugs => true, :multiple => true).should == 1
###########    slmc.confirm_validation_all_items.should be_true
###########  end
###########
###########  it "Account Class : Women's Board Member Dependent - Clinical Discharge patient" do
###########    slmc.go_to_general_units_page
###########    @@visit_no12 = slmc.clinically_discharge_patient(:pin => @@womens_board_dependent, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
###########  end
###########
###########  it "Account Class : Women's Board Member Dependent - Goes to Discount Page and Verifies Discount Type" do
###########    slmc.login("ldcastro", @password).should be_true
###########    slmc.go_to_patient_billing_accounting_page
###########    slmc.pba_search(:with_discharge_notice => true, :pin => @@womens_board_dependent)
###########    slmc.go_to_page_using_visit_number("Discount", @@visit_no12)
###########
###########    type = slmc.get_select_options("discountType")
###########    type.should == @womens_board_member_dependent_discount_type
###########    (type.count).should == 3 # includes null + 2 original
###########  end
#
### ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
#
#  it "Individual - Create and Admit patient" do
#    puts "\nAdd the same discount type that has been added to the list \n"
#
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pin1 = slmc.create_new_patient(Admission.generate_data)
#        slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin1)
#    slmc.create_new_admission(:room_charge => "DELUXE PRIVATE", :rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
#  end
#
#  it "Individual - Order items" do
#    slmc.nursing_gu_search(:pin => @@pin1)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin1)
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
#    slmc.validate_orders(:drugs => true, :multiple => true).should == 1
#    slmc.confirm_validation_all_items.should be_true
#  end
#
#  it "Individual - Clinical Discharge patient" do
#    slmc.go_to_general_units_page
#    @@visit_no13 = slmc.clinically_discharge_patient(:pin => @@pin1, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
#  end
#
#  it "Individual - Add First Discount (Courtesy Discount = 5000)" do
#    slmc.login("ldcastro", @password).should be_true
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin1)
#    slmc.go_to_page_using_visit_number("Discount", @@visit_no13)
#    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :discount_rate => "500", :close_window => true, :save => true).should be_true
#  end
#
#  it "Individual - Add Second Discount (Courtesy Discount = 50%)" do
#    slmc.go_to_patient_billing_accounting_page
#    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin1)
#    slmc.go_to_page_using_visit_number("Discount", @@visit_no13)
#    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_rate => 50, :close_window => true, :save => true, :validator => true).should be_true
#  end

 ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
  it "Individual : Add Discount without Clinical Discharge - Admit and Create patient" do
    puts "Add additional discount before clinical discharge \n"

    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin2 = slmc.create_new_patient(Admission.generate_data)
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin2)
    slmc.create_new_admission(:room_charge => "DELUXE PRIVATE", :rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it "Individual : Add Discount without Clinical Discharge - Order items" do
    slmc.nursing_gu_search(:pin => @@pin2)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin2)
    @drugs.each do |drug, q|
      slmc.search_order(:drugs => true, :code => drug).should be_true
      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
    end
    slmc.submit_added_order(:validate => true, :username => "sel_0278_validator")
    slmc.validate_orders(:drugs => true, :multiple => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

	
  it "Individual : Add Discount without Clinical Discharge - Should not be able to access Discount Page" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:admitted => true, :pin => @@pin2)
    (slmc.get_select_options("userAction#{slmc.visit_number}").include? "Discount").should be_false # First Assertion
    @dropdown = slmc.get_select_options("userAction#{slmc.visit_number}") # Second Assertion ( same target / goal )
    @dropdown.each do |i|
      if i == "Discount"
        @stat = false
        break
      else
        @stat = true
      end
    end
    @stat.should be_true
  end

  it "Individual : Add Discount without Clinical Discharge - Clinical Discharge patient" do
    slmc.login(@user, @password).should be_true
    slmc.go_to_general_units_page
    @@visit_no14 = slmc.clinically_discharge_patient(:pin => @@pin2, :pf_amount => "1000", :no_pending_order => true, :save => true).should be_true
  end

  it "Individual : Add Discount without Clinical Discharge - Search patient in PBA page" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
    (slmc.get_select_options("userAction#{@@visit_no14}").include? "Discount").should be_true # First Assertion
    @dropdown = slmc.get_select_options("userAction#{@@visit_no14}") # Second Assertion ( same target / goal )
    @dropdown.each do |i|
      if i == "Discount"
        @stat = false
        break
      else
        @stat = true
      end
    end
    @stat.should be_false
  end

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
  it "Individual - Login as PBA and discharge patient" do
    puts "Add additional discount after patient has been discharged \n"

    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin2)
    slmc.go_to_page_using_visit_number("Discharge Patient", @@visit_no14)
    slmc.select_discharge_patient_type(:type => "STANDARD", :pf_paid => true).should be_true
    slmc.discharge_to_payment.should be_true
  end

  it "Individual - Print Gatepass of patient" do
    slmc.login("gu_spec_user7", @password).should be_true
    slmc.nursing_gu_search(:pin => @@pin2)
    slmc.print_gatepass(:no_result => true, :pin => @@pin2).should be_true
  end

  it "Individual - Search patient in General Units by ticking Discharge radio button" do
    slmc.nursing_gu_search(:pin => @@pin2, :discharged => true) # ROLE_GU_NURSING_MANAGER needed and ROLE_LATE_TRANSACTION
		 puts @@pin2
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin2)
    @ancillary.each do |anc, q|
      slmc.search_order(:description => anc, :ancillary => true ).should be_true
      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
    end
    slmc.submit_added_order
    (slmc.validate_orders(:ancillary => true, :multiple => true).should == 1) if (slmc.is_checked("cartDetailNumber") == false)
    slmc.confirm_validation_all_items
    slmc.is_text_present("Order Cart Page").should be_true
    slmc.is_text_present("Order Page").should be_true
  end

  it "Individual - Search for LATE_FLAG in database should be 1" do
    slmc.access_from_database(
      :table => "TXN_PBA_DISC_DTL",
      :column1 => "REFERENCE_NO",
      :condition1 => @@visit_no14,
      :gate => "and",
      :column2 => "LATE_FLAG",
      :condition2 => "Y").should == 1
  end

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
  it "Individual - Create and Admit patient with Special Order" do
    puts "Add discount to items that are no longer included for additional discount \n"

    slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => "1")
    @@pin3 = slmc.create_new_patient(Admission.generate_data)
        slmc.login(@user, @password).should be_true
    slmc.admission_search(:pin => @@pin3)
    slmc.create_new_admission(:room_charge => "DELUXE PRIVATE", :rch_code => "RCH07", :org_code => "0287", :diagnosis => "GASTRITIS").should == "Patient admission details successfully saved."
  end

  it "Individual - Order items that are not included for additional discounts" do
    slmc.nursing_gu_search(:pin => @@pin3)
    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin3)
    slmc.search_order(:special => true)
    slmc.add_returned_order(:special_description => "Sample item", :special => true, :add => true)
    slmc.submit_added_order
    slmc.validate_orders(:special => true, :multiple => true).should == 1
    slmc.confirm_validation_all_items.should be_true
  end

  it "Individual - Clinical Discharge patient" do
    slmc.go_to_general_units_page
    @@visit_no15 = slmc.clinically_discharge_patient(:pin => @@pin3, :no_pending_order => true, :pf_amount => "1000", :save => true).should be_true
  end

  it "Individual - Goes to Discount Page" do
    slmc.login("ldcastro", @password).should be_true
    slmc.go_to_patient_billing_accounting_page
    slmc.pba_search(:with_discharge_notice => true, :pin => @@pin3)
    slmc.go_to_page_using_visit_number("Discount", @@visit_no15)
  end

  it "Individual - Additional Discount is not allowed since ordered item is special" do
    slmc.add_discount(:discount => "Courtesy Discount", :discount_scope => "ACROSS THE BOARD", :discount_type => "Fixed", :discount_rate => "5000").should be_true
    slmc.exclude_item(:save => true).should == "Fixed discount is greater than the sum of included net amount(s)"
  end

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
  it "Individual - Clicks Cancel button and Save Discount" do
    puts "Add fixed discount amount that is greater than the total amount of services \n"

    slmc.click("//input[@value='Cancel']")
    sleep 3
    slmc.click("saveBtn", :wait_for => :page)
    slmc.is_text_present("Discount Scope table is empty.").should be_true
  end

end