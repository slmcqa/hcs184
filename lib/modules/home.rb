#!/bin/env ruby
# encoding: utf-8
#require File.dirname(__FILE__) + '/helpers/locators'

require File.expand_path(File.dirname(__FILE__)) + '/helpers/locators'

module Home
  include Locators::Login

  def logout
#    open '/logout.jsp'
    sleep 2
    click "//div[10]/div/div/a/span" if is_element_present("//div[10]/div/div/a/span")
    open "/" if !is_element_present "link=Logout"
    sleep 10
    click "link=Logout" if is_element_present "link=Logout"
    sleep 10
  end
  def login(username, password)
     sleep 10
    logout

    type Locators::Login.username, username
    type Locators::Login.password, password
    click Locators::Login.button, :wait_for => :page
    if is_text_present("Please Change your Password to Proceed.")
      type("password", password)
      type("confirmPassword", password)
#      click("btnUserSubmit", :wait_for => :page)
      click("name=submit", :wait_for => :page)
     sleep 10

    end
    if is_text_present("Your CAS credentials were rejected")
      click("css=a", :wait_for => :page);
    end
    
     if is_text_present("Central Authentication Service")
     #  key_press("F5" )
       open("/mainMenu.html")
    end
    if username != "casadmin"
        sleep 6
            if is_element_present("css=img.img-responsive") and is_text_present("Healthcare System GC")
               #  open ("css=img.img-responsive")
			 #  open "http://192.168.137.126:2010/mainMenu.html"
			 sleep 4
                open "/"
                  # sleep 6
#                 #   sam = get_xpath_count("//html/body/div[1]/div[3]")
#                  sam1 = get_xpath_count("//html/body/div[1]/div[3]/div")
#                  #puts("sam - #{sam}")
#                  sam1 = sam1.to_i
#                  puts("sam1 - #{sam1}")
#                  if sam1 == 1
#                      click ("css=img.img-responsive")
#                      sleep 6
#                else
#                      while sam1 != 0
#                              if   get_text"//html/body/div[1]/div[3]/div[#{sam1}]/h5" == "Healthcare System GC"
#                                        puts "here"
#                                         click "//div[#{sam1}]/a/img" if is_element_present("//div[#{sam1}]/a/img")
#                                        click("//html/body/div[1]/div[3]/div[#{sam1}]/a/img") if is_element_present("//html/body/div[1]/div[3]/div[#{sam1}]/a/img")
#                                        sam1 = 0
#                              else
#                                        sam1 = sam1-1
#                              end
#                      end
#            end
            end
            sleep 10
    else
   #    click "//div[3]/a/img", :wait_for => :page if is_element_present( "//div[3]/a/img")
    #  put "open"
       open"/"
    end
    sleep 9
    is_text_present "Welcome!  #{username}"
    
  end
  def go_to_page(page)
    click "link=Home", :wait_for => :page
    click "link=#{page}", :wait_for => :page
    get_location
  end
  def go_to_admission_page
    go_to_page("Admission")
  end
  def go_to_general_units_page
    go_to_page("General Units Landing Page")
  end
  def go_to_special_units_page
    go_to_page("Nursing Special Units Landing Page")
  end 
  def go_to_special_units_page
    go_to_page("Special Units Landing Page")
  end
  def go_to_patient_billing_accounting_page
    go_to_page("Patient Billing and Accounting Landing Page")
  end
  def go_to_pba_page
    go_to_page("Patient Billing and Accounting Landing Page")
  end
  def go_to_healthcare_pages
    click "link=View Users", :wait_for => :page
  end
  def go_to_outpatient_nursing_page
    go_to_page("Nursing Special Units Landing Page")
    is_text_present("Special Units Home › Patient Search")
  end
  def go_to_er_page
    go_to_page("E.R. Landing Page")
  end
  def go_to_fnb_landing_page
    go_to_page("FNB Landing Page")
  end
  def go_to_arms_landing_page
    go_to_page("ARMS DAS Technologist")
  end
  def go_to_pharmacy_landing_page
    go_to_page("Pharmacy Landing Page")
  end
  def go_to_compounded_items_update_page
    go_to_page("Compounded Items Update")
  end
  def go_to_pharmacy_page
    click "//table[@id='module']/tbody/tr[3]/td[1]/a", :wait_for => :page
  end
  def go_to_order_adjustment_and_cancellation
    go_to_page("Order Adjustment and Cancellation")
  end
  def go_to_doctor_ancillary
    go_to_page("Doctor Ancillary")
  end
  def go_to_doctor_non_ancillary
    go_to_page("Doctor Non Ancillary")
  end
  def go_to_medical_records
    go_to_page("Medical Records")
  end
  def go_to_er_landing_page
    go_to_page("E.R. Landing Page")
  end
  def go_to_er_billing_page
    go_to_page("E.R. Billing Landing Page")
  end
  def go_to_das_oss
    go_to_page("DAS OSS")
  end
  def go_to_oss_payment_cancellation_and_reprinting
    go_to_page("OSS Payment Cancellation and Reprinting")
  end
  def go_to_das_technologist
    go_to_page("ARMS Das technologist")
  end
  def go_to_wellness_package_ordering_page
    go_to_page("Wellness Package Ordering")
  end
  def go_to_ancillary_clinical_ordering_page
    go_to_page("Ancillary Clinical Ordering")
  end
  def go_to_wellness_package_billing_page
    go_to_page("Wellness Billing")
    #  go_to_page("Wellness Package Ordering")
  end
  def go_to_pos_ordering
   # go_to_page("POS Ordering")
   go_to_page("Outpatient Sales Ordering")
  end
  def go_to_pos_order_cancellation
   # go_to_page("POS Order Cancellation")
    go_to_page("Outpatient Sales Order Cancellation")
  end
  def go_to_in_house_landing_page
    go_to_page("In House Landing Page")
  end
  def go_to_social_services_landing_page
    go_to_page("Social Services Landing Page")
  end
  def go_to_profile
    go_to_page("Edit Profile")
  end
  def go_to_roles
    go_to_page("View Roles")
  end
  def go_to_view_landing_pages
    go_to_page("View Landing Pages")
  end
  def go_to_groups
    go_to_page("View Groups")
  end
  def go_to_view_permissions
    go_to_page("View Permissions")
  end
  def go_to_current_users
    go_to_page("Current Users")
  end
  def go_to_flush_cache
    go_to_page("Flush Cache")
  end
  def go_to_scheduled_batch_run
    go_to_page("Scheduled Batch Run")
  end
  def go_to_printers
    go_to_page("Printers")
  end
  def go_to_jms
    go_to_page("JMS")
  end
  def go_to_constants
    go_to_page("Constants")
  end
  def go_to_project_logging
    go_to_page("Project Logging")
  end
  def go_to_server_logs
    go_to_page("Server Logs")
  end
  def go_to_performance_logs
    go_to_page("Performance Logs")
  end
  def go_to_net_messaging
    go_to_page("Net Messaging")
  end
  def go_to_audit_logs
    go_to_page("Audit Logs")
  end
  def go_to_project_environment
    go_to_page("System Info")
  end
  def go_to_clinical_applications
    go_to_page("Clinical Applications")
  end
  def go_to_services_and_rates
    go_to_page("Services and Rates")
  end
  def go_to_medicines
    go_to_page("Medicines")
  end
  def go_to_doctors
    go_to_page("Doctors")
  end
  def go_to_room_and_board
    go_to_page("Room and Board")
  end
  def go_to_special_ancillary
    go_to_page("Ancillary Special Units Module")
  end
  def go_to_final_diagnosis_review
    go_to_page("Final Diagnosis Review")
  end
  def go_to_readers_fee_page
    go_to_page("Reader's Fee Landing Page")
  end
  def go_to_guest_viewing_landing_page
    click "link=Guest Viewing Landing Page", :wait_for => :page
    is_text_present"Guest List"
  end
  def go_to_clinical_ordering_landing_page
    go_to_page("Clinical Ordering Landing Page")
  end
  def go_to_miscellaneous_payment_page
    go_to_page("Miscellaneous Payment")
  end
  def go_to_icd10_page
    go_to_page("ICD10")
  end
  def go_to_ancillary_su
    go_to_page("Ancillary Special Units Module")
  end

#  def wait_for_page_to_load(timeout)
#      do_command("waitForPageToLoad", [timeout,3])
#  end
end
