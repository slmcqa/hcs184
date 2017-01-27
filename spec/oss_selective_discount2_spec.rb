#!/bin/env ruby
# encoding: utf-8

require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
#require File.dirname(__FILE__) + '/../lib/slmc'
require 'spec_helper'
require 'yaml'

USERS = YAML.load_file File.dirname(__FILE__) + '/../spec_users.yml'

describe "OSS SELECTIVE DISCOUNT (EMPLOYEE & HMO)" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @oss_user = "jtsalang"
    @selective_patient = "1505083556"#"1304029924" #SELENIUM_SELECTIVE,0824011
    @selective_patient2 = "1505083558" #SELENIUM_SELECTIVE_EM,0824013
    @drugs =  "049000075"
    @orders = {"010001662" => 1,
                        "010001525" => 1,
                        "010000007" => 1,
                        "010000008" => 1,
                        "010002460" => 1,
                        "010001460" => 1,
                        "010000009" => 1}
    @doctors = ["6726","0126","6793","7065","6726","0126","6793","7065"]
    @fixed_discount = 1000.0
    @fixed_discount1 = 5000.0
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end

  it"OSS - EMPLOYEE - Scenario 1 - Patient Information" do
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => "test")
      slmc.patient_pin_search(:pin => @selective_patient)
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:maternity => true)
  end

  it"OSS - EMPLOYEE - Scenario 1 - Guarantor" do
       slmc.oss_add_guarantor(:guarantor_type =>  'EMPLOYEE', :acct_class => 'EMPLOYEE', :guarantor_code => "9907553", :guarantor_add => true)
  end

  it"OSS - EMPLOYEE - Scenario 1 - Order" do
        n = 0
        @orders.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
        n += 1
        end
  end

  #it"OSS - EMPLOYEE - Scenario 1 - Philhealth" do #https://projects.exist.com/issues/41167
  #     @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :compute => true)
  #end

  it"OSS - EMPLOYEE - Scenario 1 - PER DEPARTMENT → COURTESY DISCOUNT → 10%" do
      slmc.oss_add_discount(:discount_type => "Courtesy Discount", :scope => "dept", :type =>"percent",:amount=>"10")
  end

  it"OSS - EMPLOYEE - Scenario 1 - Check Order Table Information" do
      @@summary = slmc.get_summary_totals

      (("%0.2f" %(slmc.oss_order_amount_per_item)).to_f).should == @@summary[:total_gross_amount].to_f
      slmc.oss_promo_amount(:promo => 0.16).should be_true
      sleep 6
      slmc.oss_net_of_promo(:class_discount => 0.75).should be_true
  end

  it"OSS - EMPLOYEE - Scenario 1 - Check Discount Table Information" do
      slmc.oss_discount_table(:percent => 0.10).should be_true
  end

  it"OSS - EMPLOYEE - Scenario 1 - Payment Details" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      @@oss_summary = slmc.oss_billing_details

      (((@@oss_summary[:discount_amount].to_f)) - (slmc.get_value("additionalDiscountTotalDisplay").gsub(',','').to_f)).should <= 0.03
      ((@@summary[:total_net_amount].to_f) - (@@oss_summary[:total_net_amount].to_f)).should <= 0.03
  end

  it"OSS - EMPLOYEE - Scenario 2 - Patient Information" do
      sleep 6
      slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @selective_patient2)
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
  end

  it"OSS - EMPLOYEE - Scenario 2 - Guarantor" do
      slmc.oss_add_guarantor(:guarantor_type =>  'EMPLOYEE', :acct_class => 'EMPLOYEE', :guarantor_code => "0824013", :guarantor_add => true)
  end

  it"OSS - EMPLOYEE - Scenario 2 - Order" do
        n = 0
        @orders.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
        n += 1
        end
  end

  it"OSS - EMPLOYEE - Scenario 2 - Philhealth" do
       @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :compute => true, :rvu_code => "10080")
  end

  it"OSS - EMPLOYEE - Scenario 2 - PER DEPARTMENT → EMPLOYEE DISCOUNT → 10%" do
   #   slmc.oss_add_discount(:discount_type => "Employee Discount", :scope => "dept", :type =>"percent",:amount=>"10")
      slmc.oss_add_discount(:discount_type => "Courtesy Discount", :scope => "dept", :type =>"percent",:amount=>"10")
  end

  it"OSS - EMPLOYEE - Scenario 2 - Check Order Table Information" do
      @@summary = slmc.get_summary_totals

      (("%0.2f" %(slmc.oss_order_amount_per_item)).to_f).should == @@summary[:total_gross_amount].to_f
      slmc.oss_promo_amount(:promo => 0.16).should be_true
      slmc.oss_net_of_promo(:class_discount => 0.50).should be_true
  end

  it"OSS - EMPLOYEE - Scenario 2 - Check Discount Table Information" do
      slmc.oss_discount_table(:percent => 0.10).should be_true
  end

  it"OSS - EMPLOYEE - Scenario 2 - Payment Details" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      @@oss_summary = slmc.oss_billing_details

      ((@@oss_summary[:discount_amount].to_f) - (slmc.get_value("additionalDiscountTotalDisplay").gsub(',','').to_f)).should <= 0.03
      @@summary[:total_net_amount].should == @@oss_summary[:total_net_amount]

      sleep 8
     (slmc.oss_submit_order("yes")).should == "The ORWITHCI was successfully updated with printTag = 'Y'."
  end

  it"OSS - EMPLOYEE - Scenario 3 - Patient Information" do
     slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @selective_patient2)
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
  end

  it"OSS - EMPLOYEE - Scenario 3 - Guarantor" do
      slmc.oss_add_guarantor(:guarantor_type =>  'EMPLOYEE', :acct_class => 'EMPLOYEE', :guarantor_code => "0824013", :guarantor_add => true)
  end

  it"OSS - EMPLOYEE - Scenario 3 - Order" do
        n = 0
        @orders.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
        n += 1
        end
  end

  it"OSS - EMPLOYEE - Scenario 3 - Philhealth" do
       @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :compute => true)
  end

  it"OSS - EMPLOYEE - Scenario 3 - ADD A ANCILLARY → EMPLOYEE DISCOUNT → 1000" do
      slmc.oss_add_discount(:discount_type => "Employee Discount", :scope => "ancillary", :type =>"fixed",:amount=>@fixed_discount)
  end

  it"OSS - EMPLOYEE - Scenario 3 - Check Order Table Information" do
      @@summary = slmc.get_summary_totals

      (("%0.2f" %(slmc.oss_order_amount_per_item)).to_f).should == @@summary[:total_gross_amount].to_f
      slmc.oss_promo_amount(:promo => 0.16).should be_true
      slmc.oss_net_of_promo(:class_discount => 0.50).should be_true
  end

  it"OSS - EMPLOYEE - Scenario 3 - Check Discount Table Information" do
      slmc.oss_discount_table.should == @fixed_discount
  end

  it"OSS - EMPLOYEE - Scenario 3 - Payment Details" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      @@oss_summary = slmc.oss_billing_details

      (@@oss_summary[:discount_amount].to_f).should == @fixed_discount
      @@summary[:total_net_amount].should == @@oss_summary[:total_net_amount]
  end

  it"OSS - EMPLOYEE - Scenario 4 - Patient Information" do
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @selective_patient2)
      slmc.click_outpatient_order.should be_true
  end

  it"OSS - EMPLOYEE - Scenario 4 - Guarantor" do
      slmc.oss_add_guarantor(:guarantor_type =>  'EMPLOYEE', :acct_class => 'EMPLOYEE', :guarantor_code => "0824013", :guarantor_add => true)
  end

  it"OSS - EMPLOYEE - Scenario 4 - Order" do
        n = 0
        @orders.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
        sleep 1
        n += 1
        end
  end

  it"OSS - EMPLOYEE - Scenario 4 - Check Order Table Information" do
      @@summary = slmc.get_summary_totals

      (("%0.2f" %(slmc.oss_order_amount_per_item)).to_f).should == @@summary[:total_gross_amount].to_f
      slmc.oss_promo_amount(:promo => 0.16).should be_true
      slmc.oss_net_of_promo(:class_discount => 0.50).should be_true
  end

  it"OSS - EMPLOYEE - Scenario 4 - ADD A PER SERVICE → COURTESY DISCOUNT → 1000" do
      slmc.oss_order(:order_add => true, :item_code => @drugs,:quantity => "5", :doctor => "0126")
      slmc.oss_add_discount(:discount_type => "Courtesy Discount", :scope => "service", :type =>"fixed",:amount=>@fixed_discount)
  end

  it"OSS - EMPLOYEE - Scenario 4 - Check Discount Table Information" do
      slmc.oss_discount_table.should == @fixed_discount
  end

  it"OSS - EMPLOYEE - Scenario 4 - Payment Details" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      @@oss_summary = slmc.oss_billing_details

      (@@oss_summary[:discount_amount].to_f).should == slmc.get_value("additionalDiscountTotalDisplay").gsub(',','').to_f
  end

  it"OSS - HMO - Scenario 1 - Patient Information" do
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => "test")
      slmc.click_outpatient_registration.should be_true
      @@oss_pin = slmc.oss_outpatient_registration(Admission.generate_data(:not_senior => true).merge(:gender => 'M')).gsub(' ','').should be_true
            slmc.login(@oss_user, @password).should be_true
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@oss_pin)
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
  end

  it"OSS - HMO - Scenario 1 - Guarantor" do
      slmc.oss_add_guarantor(:guarantor_type =>  'HMO', :acct_class => 'HMO',:guarantor_code => "ASAL002", :coverage_choice => 'max_amount',:coverage_amount=>100000.0, :guarantor_add => true)
  end

  it"OSS - HMO - Scenario 1 - Order" do
        n = 0
        @orders.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
        n += 1
        end
  end

  it"OSS - HMO - Scenario 1 - Philhealth" do
       @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :compute => true)
  end

  it"OSS - HMO - Scenario 1 - Check Order Table Information" do
      @@summary = slmc.get_summary_totals

      (("%0.2f" %(slmc.oss_order_amount_per_item)).to_f).should == @@summary[:total_gross_amount].to_f
      slmc.oss_promo_amount(:promo => 0.16).should be_true
      slmc.oss_net_of_promo(:class_discount => 0).should be_true
  end

  it"OSS - HMO - Scenario 1 - ADD A PER SERVICE → COURTESY DISCOUNT → 1000" do
    @drugs =
      slmc.oss_order(:order_add => true, :item_code => @drugs,:quantity => "5", :doctor => "0126")
      slmc.oss_add_discount(:discount_type => "Courtesy Discount", :scope => "service", :type =>"fixed",:amount=>@fixed_discount)
  end

  it"OSS - HMO - Scenario 1 - Check Discount Table Information" do
      slmc.oss_discount_table.should == @fixed_discount
  end

  it"OSS - HMO - Scenario 1 - Payment Details" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      @@oss_summary = slmc.oss_billing_details

      (@@oss_summary[:discount_amount].to_f).should == slmc.get_value("additionalDiscountTotalDisplay").gsub(',','').to_f
  end

  it"OSS - HMO - Scenario 2 - Patient Information" do
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@oss_pin)
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
  end

  it"OSS - HMO - Scenario 2 - Guarantor" do
      slmc.oss_add_guarantor(:guarantor_type =>  'HMO', :acct_class => 'HMO',:guarantor_code => "ASAL002", :coverage_choice => 'max_amount',:coverage_amount=>100000.0, :guarantor_add => true)
  end

  it"OSS - HMO - Scenario 2 - Order" do
        n = 0
        @orders.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
        n += 1
        end
  end

  it"OSS - HMO - Scenario 2 - Philhealth" do
       @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :compute => true)
  end

  it"OSS - HMO - Scenario 2 - ADD A ANCILLARY → COURTESY DISCOUNT → 50%" do
      slmc.oss_add_discount(:discount_type => "Courtesy Discount", :scope => "ancillary", :type =>"percent",:amount=>"50")
  end

  it"OSS - HMO - Scenario 2 - Check Order Table Information" do
      @@summary = slmc.get_summary_totals

      (("%0.2f" %(slmc.oss_order_amount_per_item)).to_f).should == @@summary[:total_gross_amount].to_f
      slmc.oss_promo_amount(:promo => 0.16).should be_true
      slmc.oss_net_of_promo(:class_discount => 0).should be_true
  end

  it"OSS - HMO - Scenario 2 - Check Discount Table Information" do
      slmc.oss_discount_table(:percent => 0.50).should be_true
  end

  it"OSS - HMO - Scenario 2 - Payment Details" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      @@oss_summary = slmc.oss_billing_details

      (@@oss_summary[:discount_amount].to_f).should == slmc.get_value("additionalDiscountTotalDisplay").gsub(',','').to_f
  end

  it"OSS - HMO - Scenario 3 - Patient Information" do
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@oss_pin)
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
  end

  it"OSS - HMO - Scenario 3 - Guarantor" do
      slmc.oss_add_guarantor(:guarantor_type =>  'HMO', :acct_class => 'HMO',:guarantor_code => "ASAL002", :coverage_choice => 'percent',:coverage_amount=>"50", :guarantor_add => true)
  end

  it"OSS - HMO - Scenario 3 - Order" do
        n = 0
        @orders.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
        n += 1
        end
  end

  it"OSS - HMO - Scenario 3 - Philhealth" do
       @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :compute => true)
  end

  it"OSS - HMO - Scenario 3 - Check Order Table Information" do
      @@summary = slmc.get_summary_totals

      (("%0.2f" %(slmc.oss_order_amount_per_item)).to_f).should == @@summary[:total_gross_amount].to_f
      slmc.oss_promo_amount(:promo => 0.16).should be_true
      slmc.oss_net_of_promo(:class_discount => 0).should be_true
  end

  it"OSS - HMO - Scenario 3 - ADD A PER SERVICE → COURTESY DISCOUNT → 25%" do
      slmc.oss_order(:order_add => true, :item_code => @drugs,:quantity => "5", :doctor => "0126")
      slmc.oss_add_discount(:discount_type => "Courtesy Discount", :scope => "service", :type =>"percent",:amount=>"25")
  end

  it"OSS - HMO - Scenario 3 - Check Discount Table Information" do
      slmc.oss_discount_table(:percent => 0.25).should be_true
  end

  it"OSS - HMO - Scenario 3 - Payment Details" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      @@oss_summary = slmc.oss_billing_details

      (@@oss_summary[:discount_amount].to_f).should == slmc.get_value("additionalDiscountTotalDisplay").gsub(',','').to_f
  end

  it"OSS - HMO - Scenario 4 - Patient Information" do
      slmc.go_to_das_oss
      slmc.patient_pin_search(:pin => @@oss_pin)
      slmc.click_outpatient_order.should be_true
      slmc.oss_patient_info(:philhealth => true)
  end

  it"OSS - HMO - Scenario 4 - Guarantor" do
      slmc.oss_add_guarantor(:guarantor_type =>  'HMO', :acct_class => 'HMO',:guarantor_code => "ASAL002", :coverage_choice => 'percent',:coverage_amount=>"100", :guarantor_add => true)
  end

  it"OSS - HMO - Scenario 4 - Order" do
        n = 0
        @orders.each do |item, q|
        slmc.oss_order(:order_add => true, :item_code => item, :quantity => q, :doctor => @doctors[n])
        n += 1
        end
  end

  it"OSS - HMO - Scenario 4 - Philhealth" do
       @@ph = slmc.oss_input_philhealth(:case_type => "ORDINARY CASE", :diagnosis => "CHOLERA", :philhealth_id => "12345", :compute => true)
  end

  it"OSS - HMO - Scenario 4 - ADD A PER DEPARTMENT → COURTESY DISCOUNT → 5000" do
      slmc.oss_add_discount(:discount_type => "Courtesy Discount", :scope => "dept", :type =>"fixed",:amount=>@fixed_discount1)
  end

  it"OSS - HMO - Scenario 4 - Check Order Table Information" do
      @@summary = slmc.get_summary_totals

      (("%0.2f" %(slmc.oss_order_amount_per_item)).to_f).should == @@summary[:total_gross_amount].to_f
      slmc.oss_promo_amount(:promo => 0.16).should be_true
      slmc.oss_net_of_promo(:class_discount => 0).should be_true
  end

  it"OSS - HMO - Scenario 4 - Check Discount Table Information" do
     computed_discount =  slmc.oss_discount_table
     (@fixed_discount1.to_f - computed_discount.to_f).should <= 0.02
  end

  it"OSS - HMO - Scenario 4 - Payment Details" do
      amount = slmc.get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','').to_s
      slmc.oss_add_payment(:amount => amount, :type => "CASH")
      @@oss_summary = slmc.oss_billing_details

      (@@oss_summary[:discount_amount].to_f).should == slmc.get_value("additionalDiscountTotalDisplay").gsub(',','').to_f
  end

end

