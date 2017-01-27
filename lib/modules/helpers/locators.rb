#!/bin/env ruby
# encoding: utf-8
module Locators

  module Login
		def self.username
    	#'j_username'
    	'id=username'
		end
		def self.password
	#	'j_password'
		'id=password'
		end
		def self.button
#			'button'
		'name=submit'
  #    'id=button'
   #   "id=errorTryAgain"
	#	'id=submit'


		end
	end
  module LandingPage
    def self.home
      "link=Home"
    end
    def self.healthcare_pages
      "link=Healthcare Pages"
    end
    def self.arms_admin_menu
      "link=ARMS Admin Menu"
    end
    def self.edit_profile
      "link=Edit Profile"
    end
    def self.logout
      "link=Logout"
    end

    #file maintenance submenu
    def self.services_and_rates
      "link=Services and Rates"
    end
  end
  module Registration
    def self.admission_pin
      "css=div.inputGroup>div>div.fieldContent"
    end
		def self.pin
		#	"css=div.inputHolder>div.fieldContent"
#      "//html/body/div[1]/div[2]/div[2]/div[7]/div[2]/div/div"
      #"//html/body/div[1]/div[2]/div[2]/div[7]/div[2]/div/div"
     # "//html/body/div[1]/div[2]/div[2]/div[7]/div[1]/div[2]/div/div"
	 "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[3]/div[1]/div"

		end
    def self.oss_op_pin
      #"//form[@id='patient']/div[2]/div[1]/label[2]"
      "//html/body/div/div[2]/div[2]/form/div[2]/div/label[2]"
    end
    def self.outpatient_pin
      #"//div[@id='admissionInfo']/div[3]/div[1]/div"
      "//html/body/div/div[2]/div[2]/form/div[2]/div[3]/div/div"
    end
    def self.occupancy_list_pin
      "//html/body/div/div[2]/div[2]/table/tbody/tr/td[2]"
    end

    def self.wellness_pin
      "//form[@id='patient']/div[2]/div[1]/label[2]"
    end
	end
  module Admission
    def self.nb_room_bed
      "css=#rbf_finder_table_body>tr>td:nth-child(2)>a"
    end
    def self.or_room_bed
      "//html/body/div/div[2]/div[2]/div[9]/div[2]/div[2]/div[2]/table/tbody/tr/td[2]/a"
    end
    def self.room_bed(options={})
      if options[:random]
        "css=#rbf_finder_table_body>tr:nth-child(#{options[:random]})>td:nth-child(2)>a"
      else
        "css=#rbf_finder_table_body>tr.even>td:nth-child(2)>a"
      end
    end
    def self.pending_patients
      '//*[@id="pendingOutAdmCount"]'
    end
    def self.first_doctor_dialog_search
      "//tbody[@id='finder_table_body']/tr/td[2]/div"
    end
    def self.or_admission_search_results_pin
      'css=table[id="results"] tr[class="even"] td:nth-child(2)'
    end
    def self.admission_search_results_pin
      #'css=table[id="results"] tr[class="even"] td:nth-child(3)' #07/01 => mpi off
      'css=table[id="results"] tr[class="odd"] td:nth-child(4)' #07/01 => mpi on
    end
    def self.admission_reg_pin
      'css=table[id="results"] tr[class="odd"] td:nth-child(4)' #07/01 => mpi on
    end
    def self.admission_search_results_newborn_pin
      #'css=table[id="results"] tr[class="even"] td:nth-child(2)' #07/01 => mpi off
      'css=table[id="results"] tr[class="even"] td:nth-child(3)' #07/01 => mpi on
    end
    def self.admission_search_results_name
      'css=table[id="results"] tr[class="even"] td:nth-child(3)'
    end
    def self.admission_search_results_reg_name
#      'css=table[id="results"] tr[class="even"] td:nth-child(4)' #07/01 => mpi off
      'css=table[id="results"] tr[class="odd"] td:nth-child(5)' #07/01 => mpi on
    end
    def self.admission_search_results_gender
#      'css=table[id="results"] tr[class="even"] td:nth-child(5)'
      'css=table[id="results"] tr[class="odd"] td:nth-child(6)'   #07/01 => mpi on
    end
    def self.admission_search_results_birthday
      'css=table[id="results"] tr[class="odd"] td:nth-child(7)'#07/06 => mpi on registration spec
    end
    def self.admission_search_results_age
      'css=table[id="results"] tr[class="odd"] td:nth-child(8)'#07/11 => mpi on registration spec
    end
    def self.admission_reg_search_results_age
#      'css=table[id="results"] tr[class="even"] td:nth-child(6)' #07/01 => mpi off
      'css=table[id="results"] tr[class="even"] td:nth-child(7)' #07/01 => mpi on
    end
    def self.admission_search_results_admission_status
      #'css=table[id="results"] tr[class="even"] td:nth-child(8)' #07/01 => mpi off
      'css=table[id="results"] tbody tr[class="odd"] td:nth-child(9)' #07/01 => mpi on
    end
    # admitted patient checkbox is unchecked
    def self.admission_search_results_actions_column
      #'css=table[id="results"] tbody tr[class="even"] td:nth-child(9)' #07/01 => mpi off
      'css=table[id="results"] tbody tr[class="odd"] td:nth-child(10)' #07/01 => mpi on
    end
    def self.admission_reg_search_results_actions_column
      #'css=table[id="results"] tbody tr[class="even"] td:nth-child(8)' #07/01 => mpi off
      'css=table[id="results"] tbody tr[class="even"] td:nth-child(9)' #07/01 => mpi on
    end
    def self.admission_reg_actions_column
      #'css=table[id="results"] tbody tr[class="even"] td:nth-child(10)' #07/01 => mpi on
      "//table[@id='results']/tbody/tr[@class='odd']/td[10]"
    end
    # admitted patient checkbox is checked
    def self.admission_search_results_nursing_unit
      'css=table[id="results"] tbody tr[class="even"] td:nth-child(12)'
    end
    def self.admission_search_results_room_bed
      'css=table[id="results"] tbody tr[class="even"] td:nth-child(10)'
    end
    def self.admission_search_results_date_of_admission
      'css=table[id="results"] tbody tr[class="even"] td:nth-child(11)'
    end
    def self.admission_search_results_actions
      'css=table[id="results"] tbody tr[class="even"] td:nth-child(12)'
    end
    # patient search page
    def self.search_textbox
      "criteria"
    end
    def self.search_button
      "//input[@type='submit' and @value='Search' and @name='action']" #"search"
    end
    def self.admitted_checkbox
      "admitted"
    end
    def self.advanced_search_link
      "slide-fade"
    end
    # page menus
    def self.update_patient_info
      "link=Update Patient Info"
    end
    def self.register_patient
      "link=Register Patient"
    end
    # advanced search elements
    def self.search_firstname
      "fName"
    end
    def self.search_middlename
      "mName"
    end
    def self.search_birthday
      "dateOfBirth"
    end
    def self.search_gender
      "gender"
    end
    # links
    def self.create_new_patient
      "link=New Patient"
    end
    def self.room_bed_reprint
      "link=Room/Bed Reprint"
    end
    def self.view_print_room_transfer_history
      "link=View/Print Room Transfer History"
    end
    # registration page
    def self.create_new_admission
      "//input[@name='action' and @value='Create New Admission']"
    end
    def self.preview
      "//input[@value='Preview' and @type='button']"
    end
    def self.save_patient
      "//input[@type='submit' and @value='Save Patient']"
    end
    def self.cancel
      "//input[@value='Cancel' and @type='button']"
    end
    # admission form
    def self.preview_action
      "previewAction"
    end
    def self.preview_reg_action
#      "//input[@type='button' and @value='Preview' and @onclick='submitForm(this);']"
         "name=action"

    end
    def self.cancel_admission
      "//input[@value='Cancel Admission']"
    end
    def self.cancel_action
      "//input[@type='button' and @value='Cancel' and @onclick='submitForm(this);']"
    end
    # admission preview
    def self.revise
      "action"
    end
    def self.save_admission
      "//input[@name='action' and @value='Save Admission']"
    end
    def self.save_and_print_admission
      "//input[@name='action' and @value='Save and Print Admission']"
    end
  end
  module NursingGeneralUnits
    def self.searched_item_code
      '//*[@id="itemCodeDisplay"]'
    end
    def self.searched_item_code_clinical_ordering
      "//html/body/div/div[2]/div[2]/div[8]/div[2]/div/table/tbody/tr/td/div/a"
    end
    def self.searched_item_description
      '//*[@id="itemDesc"]'
    end
    def self.submit_button
      'css=td.ctrlButtons>input[value="Submit"]'
    end
    def self.pending_orders
      '//*[@id="g_pending_orders_count"]' #{}//html/body/div/div[2]/div[2]/div/div[2]/div/a" #"//a[contains(text(),'pending\norders')]"  //*[@id="g_pending_orders_count"]
    end
    def self.package_suite_radio_button
      "//html/body/div/div[2]/div[2]/form/div[3]/div/div/div[2]/table/tbody/tr/td[2]/input"
    end
    def self.searched_item_status
      "//html/body/div/div[2]/div[2]/table/tbody/tr/td[5]"
    end
    def self.add_package_order
      "//input[@id='add']"
    end
    def self.dismiss_all_button
      "btnClinicalOrderDismissAll"
    end
    def self.add_pf
      sleep 1
      "btnAddPf"
    end
    def self.waiting_time
      10
    end
    def self.create_patient_waiting_time
      0
    end
    def self.print_label_sticker
      "//img[@title='Print Label Sticker']"
    end
  end
  module FNB
    def self.searched_item_code
      "itemCodeDisplay"
    end
    def self.searched_item_description
      "itemDesc"
    end
  end
  module NursingSpecialUnits
    def self.spu_print_gate_pass
      "physout"
    end
    # admission form
    def self.revise_button
      "action"
    end
    def self.preview
      "previewAction"
    end
    def self.cancel_registration
#      '//input[@type="button" and  @value="Cancel Registration"]'
      "cancelAdmission"
    end
    def self.oss_op_reg_save_button
      "//html/body/div/div[2]/div[2]/form/div[2]/div[4]/input[2]"
    end
    def self.or_op_reg_save_button
      "//input[@name='action' and @value='Save']"
    end
    def self.admin_reg_save_button
      "//input[@type='button' and @value='Save' and @onclick='submitForm(this);']"
    end
    def self.er_pin
    #  "//div[@id='admissionInfo']/div[3]/div[1]/div"
     # "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[4]/div[1]/div"
    #  "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[3]/div[1]/div"s
     # "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[4]/div[1]/div"
    "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[3]/div[1]/div"
	#  "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[4]/div[1]/div"
    end
    def self.pin
                 "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[4]/div[1]/div"
#	 pinn =  get_text("//html/body/div[1]/div[2]/div[2]/form/div[2]/div[4]/div[1]/div")
#	 pinn = pinn.to_s
#	 puts "pinn - #{pinn}"	 
#	 pinn = pinn[1]
#	 puts "pinn - #{pinn}"
#	 pinn = pinn.to_s
#	 if pinn != "1"
#		 pin =  "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[3]/div[1]/div"
#	 else
#		 pin = "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[4]/div[1]/div"
#	 end
#	 	 pin = "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[4]/div[1]/div"
#	 return pin
#  "//div[@id='admissionInfo']/div[3]/div[1]/div"get_text
     # "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[4]/div[1]/div"
    #  "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[3]/div[1]/div"s
     # "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[4]/div[1]/div"
   #   "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[3]/div[1]/div"
	#  "//html/body/div[1]/div[2]/div[2]/form/div[2]/div[4]/div[1]/div"
    end		
    def self.room_bed
      "//html/body/div/div[2]/div[2]/div[9]/div[2]/div[2]/table/tbody/tr/td/a"  || "//html/body/div/div[2]/div[2]/div[10]/div[2]/div[2]/table/tbody/tr/td[2]/a"
    end
    def self.er_room_bed
      "css=#rbf_finder_table_body>tr>td:nth-child(2)>a"
    end
    def self.submit_button
      "//html/body/div/div[2]/div[2]/table/tbody/tr/td[7]/input"
    end
    def self.fnb_submit_button
      "//html/body/div/div[2]/div[2]/table/tbody/tr/td[10]/div/input"
    end
    def self.submit_button_gu
      "//html/body/div/div[2]/div[2]/table/tbody/tr[2]/td[6]/input"
    end
    def self.submit_button_spu
#      "//td[@class='ctrlButtons']/input[@type='button' and @value='Submit']"
      "//td[@class='ctrlButtons']/input[@type='button' and @value='Submit']"
    end
    def self.submit_button_package
      "//html/body/div/div[2]/div[2]/table/tbody/tr/td[6]/input"
    end
    def self.checklist_order
      "//tbody[@id='clo_tbody']/tr/td[2]"
    end
    def self.ci_number
      "//html/body/div/div[2]/div[2]/div[5]/div/table/tbody/tr/td/a"
    end
    def self.order_adjustment_searched_service_code
      "//html/body/div/div[2]/div[2]/div[9]/div[3]/div/table/tbody/tr/td/div/a"
    end
    def self.order_adjustment_searched_service_description
      "//html/body/div/div[2]/div[2]/div[9]/div[3]/div/table/tbody/tr/td[2]/div/a"
    end
    def self.order_adjustment_added_procedure_2nd_row
      "//html/body/div/div[2]/div[2]/form/div[2]/div[2]/table/tbody/tr[2]/td[2]"
    end
    def self.total_amount_label
      "//html/body/div/div[2]/div[2]/form/div[3]/span/label"
    end
    def self.searched_service_code
      "css=#oif_finder_table_body>tr>td>div>a"
    end
    def self.searched_service_description
      "//html/body/div/div[2]/div[2]/div[8]/div[3]/div/div/div/table/tbody/tr/td[2]/div/a"
    end
    def self.or_searched_doctor
      "//html/body/div/div[2]/div[2]/div[3]/div[2]/div[2]/table/tbody/tr/td[2]/div"
    end
    def self.nb_searched_doctor
      "//html/body/div/div[2]/div[2]/div[4]/div[2]/div[2]/table/tbody/tr/td[2]/div"
    end
    #Checklist Order
    def self.add_item_button
      #"//html/body/div/div[2]/div[2]/form/div/div[2]/div[5]/input"
      '//input[@type="button" and @value="Add"]'
    end
    def self.find_anaesthesiologist
      "//input[@value='Find']"
    end
    def self.find_surgeon
      #"//html/body/div/div[2]/div[2]/form/div[2]/div[2]/div[6]/input[3]"
     "//html/body/div/div[2]/div[2]/form/div/div[2]/div[2]/input[3]"
    end
    def self.search_doctors_textbox
      "entity_finder_key"
    end
    def self.cancel_registration_button
      "//input[@name='action' and @value='Cancel Registration']"
    end
    def self.cancel_registration_link
      "link=Cancel Registration"
    end 
    def self.update_registration_link
      "link=Update Registration"
    end
    def self.cancel_reason
      "reason"
    end
    def self.cancel_admission
      "//button[@type='button' and @style='']"  #"//input[@name='admissionCancelFormAction']"
    end
  end
  module PBA
    def self.submit_button
      "//html/body/div/div[2]/div[2]/div[5]/table/tbody/tr/td[9]/input" # old xpath
      #"//html/body/div/div[2]/div[2]/div[7]/table/tbody/tr/td[9]/input" # new xpath
    end
    def self.guarantor_code_info
      "//html/body/div/div[2]/div[2]/div[4]/table/tbody/tr/td[2]"
    end
    def self.processed_discounts
      "//a[@title='Cancelled Discounts']"
    end
    def self.adjusted_discounts
      "//a[@title='Adjusted Discounts']"
    end
    def self.cancelled_discounts
      "//a[@title='Cancelled Discounts']"
    end
  end
  module AdditionalRoomAndBoardCancellation
    def self.cancel_reason_text_field_first_row
      "//form[@id='roomBedCancellationFormBean']/table/tbody/tr[2]/td[9]/input"
    end
    def self.cancel_reason_text_field_second_row
      "//form[@id='roomBedCancellationFormBean']/table/tbody/tr[3]/td[9]/input"
    end
  end
  module ARMS
    # Order list page
    def self.results_data_entry
      "link=Results Data Entry"
    end
    def self.results_retrieval
      "link=Results Retrieval"
    end
    def self.document_status_list
      "//html/body/div/div[2]/div[2]/form/div[3]/table/tbody/tr/td[9]"
    end
    def self.ci_number_list
      "//html/body/div/div[2]/div[2]/form/div[3]/table/tbody/tr/td[6]"
    end
    # Results data entry form
    def self.specimen
      "PARAM::006200000000115::SPECIMEN"
    end
    def self.remarks
      "PARAM::006200000000115::REMARKS"
    end
    def self.signatory1
      "//img[@alt='Search']"
      #"//input[@type='button' and @onclick='DSF1.show();']"
    end
    def self.signatory2
      "//form[@id='resultDataEntryBean']/div[14]/span[4]/a/img"
      #"//input[@type='button' and @onclick='DSF2.show();']"
    end
    def self.signatory1_id
      "sf1_entity_finder_key"
    end
    def self.signatory2_id
      "sf2_entity_finder_key"
    end
    def self.signatory_fullname
      "//html/body/div/div[2]/div[2]/div[3]/div[2]/div[2]/div[2]/table/tbody/tr/td[2]/a"
    end
    def self.search_signatory1
      "//input[@value='Search']"
    end
    def self.search_signatory2
      "//input[@value='Search' and @type='button' and @onclick='DSF2.search();']"
    end
    def self.save
      "//html/body/div/div[2]/div[2]/form/div[15]/span/input[2]"
    end
    def self.document_status
      "//html/body/div/div[2]/div[2]/form/div[3]/span[3]"
    end
    def self.queue_for_validation
      "//html/body/div/div[2]/div[2]/form/div[5]/span/input[3]"
      #"a_queue1"
    end
    def self.validate
      "//html/body/div/div[2]/div[2]/form/div[5]/span/input[3]"
      #"//input[@name='a_validate1' and @value='Validate']"
    end
    def self.username
      "validateUsername"
    end
    def self.password
      "validatePassword"
    end
    def self.submit
      "//input[@value='Submit']"
    end
    def self.tag_as_official
      "//html/body/div/div[2]/div[2]/form/div[5]/span/input[3]"
      #"//input[@name='a_official1']"
    end
    def self.cancel_credentials
      "btnValidationCancel"
    end
    #medical records
    def self.medical_fullname
      "//html/body/div/div[2]/div[2]/div[4]/div[2]/table/tbody/tr/td[3]/a"
    end
    #doctor ancillary records
    def self.document_action_list
      "//html/body/div/div[2]/div[2]/table/tbody/tr/td[9]"
    end
  end
  module Philhealth
    # Charges
    def self.room_and_board_actual_charges
     "//div[@id='benefitSummarySection']/div[2]/div/table/tbody/tr[1]/td[2]"
    end
    def self.rb_availed_actual_charges
      "//div[@id='benefitSummarySection']/div[2]/div/table/tbody/tr[2]/td[2]"
      
    end
    def self.actual_medicine_charges
      "//div[@id='benefitSummarySection']/div[2]/div/table/tbody/tr[3]/td[2]"

    end
    def self.actual_lab_charges
      "//div[@id='benefitSummarySection']/div[2]/div/table/tbody/tr[4]/td[2]"
    end
    def self.actual_operation_charges
      "//div[@id='benefitSummarySection']/div[2]/div/table/tbody/tr[5]/td[2]"
    end
    def self.total_actual_charges
      "//div[@id='benefitSummarySection']/div[2]/div/table/tbody/tr[6]/td[2]"
    end
    # Benefits
    def self.room_and_board_actual_benefit_claim
      "//div[@id='benefitSummarySection']/div[2]/div/table/tbody/tr[1]/td[3]"
    end
    def self.rb_availed_actual_benefit_claim
      "//div[@id='benefitSummarySection']/div[2]/div/table/tbody/tr[2]/td[3]"
    end
    def self.actual_medicine_benefit_claim
      "//div[@id='benefitSummarySection']/div[2]/div/table/tbody/tr[3]/td[3]"
    end
    def self.actual_lab_benefit_claim
      "//div[@id='benefitSummarySection']/div[2]/div/table/tbody/tr[4]/td[3]"
    end
    def self.actual_operation_benefit
      "//div[@id='benefitSummarySection']/div[2]/div/table/tbody/tr[5]/td[3]"
    end
    def self.total_actual_benefit_claim
      "//div[@id='benefitSummarySection']/div[2]/div/table/tbody/tr[6]/td[3]"
    end
    # Maximum Benefits
    def self.max_benefit_drugs
      "//div[@id='benefitsSection']/div[2]/div/table/tbody/tr[1]/td[2]"
    end
    def self.max_benefit_xray_lab_others
      "//div[@id='benefitsSection']/div[2]/div/table/tbody/tr[2]/td[2]"
    end
    def self.max_benefit_operation
      "//div[@id='benefitsSection']/div[2]/div/table/tbody/tr[3]/td[2]"
    end
    def self.max_benefit_rb
      "//div[@id='benefitsSection']/div[3]/div/table/tbody/tr[1]/td[2]"
    end
    def self.max_benefit_rb_amt_per_day
      "//div[@id='benefitsSection']/div[3]/div/table/tbody/tr[2]/td[2]"
    end
    def self.max_benefit_rb_total_amt
      "//div[@id='benefitsSection']/div[3]/div/table/tbody/tr[3]/td[2]"
    end
    def self.max_benefit_rb_consumed
      "//div[@id='benefitsSection']/div[3]/div/table/tbody/tr[4]/td[2]"
    end
    def self.deduction_from_previous_confinements_total
      "//div[@id='benefitsSection']/div[3]/div/table/tbody/tr[1]/td[3]"
    end
    def self.deduction_from_previous_confinements_amt_per_day
      "//div[@id='benefitsSection']/div[3]/div/table/tbody/tr[2]/td[3]"
    end
    def self.deduction_from_previous_confinements_total_amount
      "//div[@id='benefitsSection']/div[3]/div/table/tbody/tr[3]/td[3]"
    end
    def self.deduction_from_previous_confinements_consumed
      "//div[@id='benefitsSection']/div[3]/div/table/tbody/tr[4]/td[3]"
    end
    # Claims
    def self.deductions_drugs
      "//div[@id='claimsSection']/div[2]/div/table/tbody/tr[1]/td[2]"
    end
    def self.deductions_xray_lab_others
      "//div[@id='claimsSection']/div[2]/div/table/tbody/tr[2]/td[2]"
    end
    def self.remaining_operation_deductions
      "//div[@id='claimsSection']/div[2]/div/table/tbody/tr[3]/td[2]"
    end
    def self.deductions_room_and_board
      "//div[@id='claimsSection']/div[2]/div/table/tbody/tr[4]/td[2]"
    end
    def self.remaining_drug_benefits
      "//div[@id='claimsSection']/div[2]/div/table/tbody/tr[1]/td[3]"
    end
    def self.remaining_xray_lab_others_benefits
      "//div[@id='claimsSection']/div[2]/div/table/tbody/tr[2]/td[3]"
    end
    def self.remaining_operation_benefits
      "//div[@id='claimsSection']/div[2]/div/table/tbody/tr[3]/td[3]"
    end
    def self.remaining_room_and_board
      "//div[@id='claimsSection']/div[2]/div/table/tbody/tr[4]/td[3]"
    end
    def self.reference_number_label1
      "css=#philHealthForm>div.row>div>div"
    end
    def self.reference_number_label2
      "css=#philHealthForm>div.row>div>div:nth-child(2)"
    end
    def self.reference_number_label3
              "//html/body/div/div[2]/div[2]/form/div[2]/div/div[2]/label"
    end
    # PF Claims
    def self.surgeon_actual_charges
      "css=#pfClaimsSection>div.row>#row>tbody>tr>td:nth-child(4)"
    end
    def self.surgeon_benefit_claim
#      "css=#pfClaimsSection>div.row>#row>tbody>tr>td:nth-child(5)"
      "//html/body/div/div[2]/div[2]/form/div[6]/div[10]/div[2]/table/tbody/tr/td[9]/label"
    end
    def self.anesthesiologist_actual_charges
      "css=#pfClaimsSection>div.row>#row>tbody>tr:nth-child(2)>td:nth-child(4)"
    end
    def self.anesthesiologist_benefit_claim
      "css=#pfClaimsSection>div.row>#row>tbody>tr:nth-child(2)>td:nth-child(5)"
    end
    def self.inpatient_physician_benefit_claim
      #"css=#row>tbody>tr>td:nth-child(5)"
     # "//html/body/div/div[2]/div[2]/form/div[6]/div[11]/div[2]/table/tbody/tr/td[9]/label"
       "//html/body/div/div[2]/div[2]/form/div[6]/div[12]/div[2]/table/tbody/tr/td[9]/label"
    end
    def self.inpatient_surgeon_benefit_claim
      "css=#row>tbody>tr:nth-child(2)>td:nth-child(5)"
    end
    def self.inpatient_anesthesiologist_benefit_claim
      "css=#row>tbody>tr:nth-child(3)>td:nth-child(5)"
    end
    # Claims History
    def self.first_lab_claim_history
      'css=div[id=claimHistorySection] div[class=row] table[id=row] tr[class=even] td:nth-child(9)'
    end
  end
  module Wellness
    def self.select_package
      "packageOrderCode"
    end
    def self.edit_package
      "//input[@id='edit' and @value='Edit']"
    end
    def self.validate
      "validate"
    end
    def self.switch_link
      "//div[@id='v_10001SR010002375']/span/a[2]/strong"
    end
    def self.switch
      "//div[@id='f_10001SR010002375']/span/a[2]/strong"
    end
    def self.other_package_options
      "otherOption"
    end
    def self.save_package
      "//button[2]"
    end
    def self.switch_validated_item_button
      "switch"
    end
    def self.add_to_cart
      "addToCart"
    end
    def self.order_package
      "add"
    end
    def self.update_order
      "//input[@id='add' and @value='Update Order']"
    end
    def self.order_non_ecu_package
      "//input[@type='button' and @value='Add to Cart']"
    end
    def self.replace_package
      "validate"
    end
    def self.go_to_payment
      "payment"
    end
    def self.delete
      "delete"
    end
    def self.soa_or_reprint_link
      "link=SOA/OR Reprint"
    end
    def self.search_firstname
      "firstName"
    end
    def self.search_pin
      "pin"
    end
    def self.search_or
      "_submit"
    end
    def self.search_soa
      "//input[@name='_submit' and @value='Search SOA']"
    end
    def self.reprint_soa
      "link=Reprint SOA"
    end
    def self.reprint_or
      "link=Reprint OR"
    end
    def self.view_details
      "link=View Details"
    end
    def self.reprint_request_slip
      "link=Reprint Request Slip"
    end
    def self.additional_order
      '//input[@id="clinicalOrder" and @value="Additional Order"]'
    end
    def self.additional_order_save
#      '//div[7]/div[3]/div/button[2]'
        '//div[8]/div[11]/div/button[2]/span'
    end
    def self.additional_order_close
#      '//div[7]/div[3]/div/button[1]'
        '//div[8]/div[11]/div/button'
    end
    def self.non_ecu_switch_link
      "//a[contains(@class,'switch')]"
    end
  end
  module Pharmacy
    def self.searched_document_no
      "//html/body/div/div[2]/div[2]/div[4]/div[2]/table/tbody/tr/td"
    end
  end
  module OrderAdjustmentAndCancellation
    def self.start_date_search
      'startOrderDate'
    end
    def self.end_date_search
      'endOrderDate'
    end
    def self.requesting_unit_search_icon
      "//input[@type='button' and @onclick='OSF.show();']"
    end
    def self.requesting_unit_description
      "requestingUnitDescription"
    end
    def self.search_textbox
      "osf_entity_finder_key"
    end
    def self.search_button
      "//input[@value='Search']"
    end
    def self.ci_search_button
      "search"
    end
    def self.ci_searched_result_description
      "//html/body/div/div[2]/div[2]/div[9]/div[2]/table/tbody/tr/td[4]"
    end
    def self.pending_ecu_cancellation_link
      "ecuCancelCount"
    end
    def self.cancel_item
      "link=Cancel Item"
    end
    def self.confirm_ecu_confirmation
      "proceedCancelOrder"
    end
    def self.cancel_ecu_confirmation
      "closeEcuConfimation"
    end
    def self.clear_item_from_list
      "link=Clear Item from List"
    end
    def self.reprint_item
      "link=Reprint"
    end
    def self.close_ecu_cancellation_popup
      "closeEcuCancelPopup"
    end
    def self.clinical_order
      "link=Clinical Order"
    end
  end
  module OSS_Philhealth

    #Benefit Summary
    def self.actual_rb_availed_charges
      "//div[@id='benefitSummarySection']/div[2]/div/table/tbody/tr/td[2]"
    end
    def self.actual_rb_availed_benefit_claim
      "benefitSummary.actualRoomAndBoardAvailedClaimed"
    end
    def self.actual_medicine_charges
      "benefitSummary.actualMedicalCharges"
    end
    def self.actual_medicine_benefit_claim
      "benefitSummary.actualMedicalBenefitClaim"
    end
    def self.actual_lab_charges
      "benefitSummary.actualLaboratoryCharges"
    end
    def self.actual_lab_benefit_claim
      "benefitSummary.actualLaboratoryBenefitClaim"
    end
    def self.actual_operation_charges
      "benefitSummary.actualOperationCharges"
    end
    def self.actual_operation_benefit_claim
     # "benefitSummary.actualOperationBenefitClaim"
      '//*[@id="benefitSummary.actualOperationBenefitClaim"]'
    end

    def self.actual_total_charges
      "benefitSummary.totalCharges"
    end
    def self.actual_total_benefit_claim
      "benefitSummary.totalBenefitClaim"
    end

    # Maximum Benefits
    def self.max_benefit_drugs
      "maximumBenefits.medicine"
    end

    def self.max_benefit_xray_lab_others
      "maximumBenefits.laboratory"
    end

    # Claims
    def self.drugs_deduction_claims
      "claims.medicineDeduction"
    end
    def self.drugs_remaining_benefit_claims
      "claims.medicineRemainingBenefit"
    end
    def self.lab_deduction_claims
      "claims.laboratoryDeduction"
    end
    def self.lab_remaining_benefit_claims
      "claims.laboratoryRemainingBenefit"
    end
    def self.operation_deduction_claims
      "claims.operationDeduction"
    end

    # PF Claims
    def self.anesthesiologist_actual_charges
      "anesthesiologist.actualCharges"
    end
    def self.anesthesiologist_benefit_claim
      "anesthesiologist.benefitClaim"
    end
    def self.surgeon_actual_charges
      "surgeon.actualCharges"
    end
    def self.surgeon_benefit_claim
      "surgeon.benefitClaim"
    end

    # Claims History
    def self.claims_history
      'css=div[id=claimHistorySection] div[class=row] table[id=row] tbody tr[class=even] td'

    end
    def self.first_total_claim_history
      'css=div[id=claimHistorySection] div[class=row] table[id=row] tbody tr[class=even] td:nth-child(11)'
    end
    def self.second_total_claim_history
      'css=div[id=claimHistorySection] div[class=row] table[id=row] tbody tr[class=odd] td:nth-child(11)'
    end
    def self.third_total_claim_history
      'css=div#claimHistorySection>div.row>table#row>tbody>tr:nth-child(3)>td:nth-child(11)'
    end
    def self.fourth_total_claim_history
      'css=div#claimHistorySection>div.row>table#row>tbody>tr:nth-child(4)>td:nth-child(11)'
    end
    def self.fifth_total_claim_history
      'css=div#claimHistorySection>div.row>table#row>tbody>tr:nth-child(5)>td:nth-child(11)'
    end
    def self.sixth_total_claim_history
      'css=div#claimHistorySection>div.row>table#row>tbody>tr:nth-child(6)>td:nth-child(11)'
    end
    def self.seventh_total_claim_history
      'css=div#claimHistorySection>div.row>table#row>tbody>tr:nth-child(7)>td:nth-child(11)'
    end
    def self.eigth_total_claim_history
      'css=div#claimHistorySection>div.row>table#row>tbody>tr:nth-child(8)>td:nth-child(11)'
    end
  end
  module ER_Philhealth
    # CHARGES
    def self.actual_medicine_charges
      "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(1)>td:nth-child(2)"
    end
    def self.actual_lab_charges
    #  "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(2)>td:nth-child(2)"
      "//html/body/div[1]/div[2]/div[2]/form/div[4]/div[5]/div[2]/div/table/tbody/tr[3]/td[2]"
    end
    def self.actual_operation_charges
      "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(3)>td:nth-child(2)"
    end
    def self.total_actual_charges
      "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(4)>td:nth-child(2)" #
    end
    # BENEFIT
    def self.actual_medicine_benefit_claim
      "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(1)>td:nth-child(3)"
    end
    def self.actual_lab_benefit_claim
      "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(2)>td:nth-child(3)"
    end
    def self.actual_operation_benefit
      "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(3)>td:nth-child(3)"
    end
    def self.total_actual_benefit_claim
    #  "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(4)>td:nth-child(3)"
      "//html/body/div[1]/div[2]/div[2]/form/div[4]/div[5]/div[2]/div/table/tbody/tr[5]/td[3]"
    end
    # Maximum Benefits
    def self.max_benefit_drugs
      "css=#benefitsSection>div:nth-child(2)>div>table>tbody>tr>td:nth-child(2)"
    end
    def self.max_benefit_xray_lab_others
      "css=#benefitsSection>div:nth-child(2)>div>table>tbody>tr:nth-child(2)>td:nth-child(2)"
    end
    def self.max_benefit_operation
      "css=#benefitsSection>div:nth-child(2)>div>table>tbody>tr:nth-child(3)>td:nth-child(2)"
    end
  end
  module OR_Philhealth
    # CHARGES
    def self.rb_availed_charges
      "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(1)>td:nth-child(2)"
    end
    def self.actual_medicine_charges
      #"css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(2)>td:nth-child(2)"
      '//*[@id="actualMedicalCharges"]'
    end
    def self.actual_lab_charges
      #"css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(3)>td:nth-child(2)"
      #"//html/body/div/div[2]/div[2]/form/div[4]/div[6]/div[2]/div/table/tbody/tr[3]/td[2]"
      "//html/body/div/div[2]/div[2]/form/div[4]/div[5]/div[2]/div/table/tbody/tr[3]/td[2]"
    end
    def self.actual_operation_charges
#      "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(4)>td:nth-child(2)"
   #   "//html/body/div/div[2]/div[2]/form/div[4]/div[6]/div[2]/div/table/tbody/tr[4]/td[2]"
   #  "//html/body/div/div[2]/div[2]/form/div[4]/div[6]/div[2]/div/table/tbody/tr[3]/td[2]"
     "//html/body/div[1]/div[2]/div[2]/form/div[4]/div[5]/div[2]/div/table/tbody/tr[4]/td[2]"
    end
    def self.total_actual_charges
      #"css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(5)>td:nth-child(2)"
    #  "//html/body/div/div[2]/div[2]/form/div[4]/div[6]/div[2]/div/table/tbody/tr[5]/td[2]"
      "//html/body/div/div[2]/div[2]/form/div[4]/div[5]/div[2]/div/table/tbody/tr[5]/td[2]"
    end
    # BENEFIT
    def self.rb_availed_benefit_claim
      "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(1)>td:nth-child(3)"
    end
    def self.actual_medicine_benefit_claim
      "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(2)>td:nth-child(3)"
      #"//html/body/div/div[2]/div[2]/form/div[4]/div[6]/div[2]/div/table/tbody/tr[2]/td[3]"
    end
    def self.actual_lab_benefit_claim
      "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(3)>td:nth-child(3)"
      #"//html/body/div/div[2]/div[2]/form/div[4]/div[6]/div[2]/div/table/tbody/tr[3]/td[3]"
    end
    def self.actual_operation_benefit
      #"css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(4)>td:nth-child(3)"
      #"//html/body/div/div[2]/div[2]/form/div[4]/div[6]/div[2]/div/table/tbody/tr[4]/td[3]"
    #  "//html/body/div/div[2]/div[2]/form/div[4]/div[5]/div[2]/div/table/tbody/tr[4]/td[2]"
      "//html/body/div[1]/div[2]/div[2]/form/div[4]/div[5]/div[2]/div/table/tbody/tr[4]/td[3]"
    end
    def self.total_actual_benefit_claim
      "css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(5)>td:nth-child(3)"
      #"//html/body/div/div[2]/div[2]/form/div[4]/div[6]/div[2]/div/table/tbody/tr[5]/td[3]"
     # "//html/body/div/div[2]/div[2]/form/div[4]/div[5]/div[2]/div/table/tbody/tr[5]/td[3]"
    end
    # Maximum Benefits
    def self.max_benefit_drugs
      "css=#benefitsSection>div:nth-child(2)>div>table>tbody>tr>td:nth-child(2)"
      #"//html/body/div/div[2]/div[2]/form/div[4]/div[7]/div[2]/div/table/tbody/tr/td[2]"
    end
    def self.max_benefit_xray_lab_others
      "css=#benefitsSection>div:nth-child(2)>div>table>tbody>tr:nth-child(2)>td:nth-child(2)"
      #"//html/body/div/div[2]/div[2]/form/div[4]/div[7]/div[2]/div/table/tbody/tr[2]/td[2]"
    end
    def self.max_benefit_operation
      "css=#benefitsSection>div:nth-child(2)>div>table>tbody>tr:nth-child(3)>td:nth-child(2)"
#"//html/body/div/div[2]/div[2]/form/div[4]/div[7]/div[2]/div/table/tbody/tr[3]/td[2]"
    end
    def self.or_pf_physician_fee
     "//html/body/div/div[2]/div[2]/form/div[4]/div[8]/div[2]/table/tbody/tr/td[9]/label"
    end
  end
  module Inhouse
    def self.inhouse_submit_button
      'css=input[value="Submit"]'
    end
    def self.remarks
      'redTagRemarks'
    end
    def self.save
      'saveRedTagPatient'
    end
    def self.exit
      'closeRedTagPopup'
    end
    def self.flag
      'redTagFlag'
    end
  end
  module FileMaintenance
    def self.update_button
      "//div[6]/div[3]/div/button"
    end
  end
end
