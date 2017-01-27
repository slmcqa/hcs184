#!/bin/env ruby
# encoding: utf-8
require 'faker'
require File.dirname(__FILE__) + '/helpers/admission_helper'
require File.dirname(__FILE__) + '/helpers/locators'

module OutpatientOrdering
	include Locators::Registration
  include Locators::Admission
  include AdmissionHelper

 def outpatient_wellness(options = {})
    click "link=Outpatient Registration", :wait_for => :page
    type "name.lastName",  options[:last_name]
    type "name.firstName", options[:first_name]
    type "name.middleName", options[:middle_name]
    select "suffix.code", "label=#{options[:suffix]}" if options[:suffix]
    type "birthDate", options[:birth_day]
    gender = options[:gender]
    click 'gender1' if gender == "M"
    click 'gender2' if gender == "F"
    click "//input[@name='action' and @value='Save']", :wait_for => :page
    is_text_present "Patient successfully saved."
    if is_element_present(Locators::Registration.wellness_pin)
      self.last_name = options[:last_name]
      self.first_name = options[:first_name]
      self.middle_name = options[:middle_name]
      self.pin = get_text(Locators::Registration.wellness_pin)
      return pin
    else
      return get_text("errorMessages")
    end
  end
end