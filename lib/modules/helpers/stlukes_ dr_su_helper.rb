#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/locators'

module StLukesDrSuHelper
  include Locators::NursingSpecialUnits

  def admit_dr_patient(options={})
    click "turnedInpatientFlag1" if options[:for_inpatient]
    account_class = options[:account_class] || "INDIVIDUAL"

    if account_class == "SOCIAL SERVICE"
        type "escNumber", options[:esc_no] || "234"
        type "initialDeposit", options[:ss_amount] || "100"
        select "clinicCode", options[:dept_code] || "MEDICINE"
    end 

    select "accountClass", "label=#{account_class}"
    click "roomNoFinder"
    type "rbf_entity_finder_roomChargeCode", (options[:rch_code] || "RCHSP")
    type "rbf_entity_finder_key", (options[:org_code] || "0170")
    type "rbf_room_no_finder_key", "XST" #admit only on ROOMS with "XST"
    click "//input[@value='Search' and @type='button' and @onclick='RBF.search();']", :wait_for => :element, :element => Locators::Admission.nb_room_bed
    click Locators::Admission.nb_room_bed, :wait_for => :not_visible, :element => Locators::Admission.nb_room_bed
    self.doctor_finder(:doctor => "ABAD")
    select "guarantorTypeCode", "label=#{options[:guarantor_type]}" if options[:guarantor_type]
    if options[:guarantor_code]
      click "searchGuarantorBtn"
      if (account_class == "EMPLOYEE") || (account_class == "EMPLOYEE DEPENDENT")
        type "employee_entity_finder_key", (options[:last_name] if options[:last_name]) || (options[:guarantor_code] if options[:guarantor_code])
        click "//input[@value='Search' and @type='button' and @onclick='EF.search();']"
      elsif account_class == 'INDIVIDUAL'
        type "patient_entity_finder_key", options[:guarantor_code] if options[:guarantor_code]
        click "//input[@value='Search' and @type='button' and @onclick='PF.search();']"
      elsif account_class == "DOCTOR" || (account_class == "DOCTOR DEPENDENT")
        type "ddf_entity_finder_key", options[:guarantor_code] if options[:guarantor_code]
        click "//input[@value='Search' and @type='button' and @onclick='DDF.search();']"
      else
        type "bp_entity_finder_key", options[:guarantor_code] if options[:guarantor_code]
        click "//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']"
      end
    end
    sleep 5
    if is_element_present("link=#{options[:guarantor_code]}")
      click "link=#{options[:guarantor_code]}"
    elsif account_class == "DOCTOR" || (account_class == "DOCTOR DEPENDENT")
      sleep 5
      click "css=#ddf_finder_table_body>tr>td>div" if is_element_present"css=#ddf_finder_table_body>tr>td>div"
    end
    click "previewAction", :wait_for => :page
    if is_text_present "Doctor is a required field."
      self.doctor_finder(:doctor => "ABAD")
    end
    if options[:sap]
      click "//input[@name='action' and @value='Save and Print']", :wait_for => :page
    else
      click "//input[@type='button' and @onclick='submitForm(this);' and @value='Save']", :wait_for => :page
    end
    #click "//input[@type='button' and @value='Save' and @onclick='submitForm(this);']", :wait_for => :page
    is_text_present("Patient admission details successfully saved.")
  end


end