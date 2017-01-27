
#require File.dirname(__FILE__) + '/../lib/slmc.rb'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
require 'spec_helper'
require 'yaml'

describe "Serialized Order Number by Performing Unit" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
    @selenium_driver = SLMC.new
    @selenium_driver.start_new_browser_session
    @password = "123qweuser"
    @patient = Admission.generate_data
    @oss_patient = Admission.generate_data
    @or_patient = Admission.generate_data
    @dr_patient = Admission.generate_data
    @er_patient = Admission.generate_data
    @wellness_patient1 = Admission.generate_data
    @wellness_patient2 = Admission.generate_data

    @@promo_discount = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@patient[:age])
    @@promo_discount2 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@oss_patient[:age])
    @@promo_discount3 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@or_patient[:age])
    @@promo_discount4 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@dr_patient[:age])
    @@promo_discount5 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@er_patient[:age])
    @@promo_discount6 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@wellness_patient1[:age])
    @@promo_discount7 = PatientBillingAccountingHelper::Philhealth.calculate_promo_discount_based_on_age(@wellness_patient2[:age])
    
    #"5c456b0314b9013d321e5f917a3a4aa3d6235dab"

    @user = "ldvoropesa"  #"billing_spec_user3"  #admission_login#
    @pba_user = "ldcastro" #"sel_pba7"
    @or_user =  "slaquino"     #"or21"
    @oss_user = "jtsalang"  #"sel_oss7"
    @dr_user = "jpnabong" #"sel_dr4"
    @er_user =  "jtabesamis"   #"sel_er4"
    @wellness_user = "ragarcia-wellness" # "sel_wellness2"
    @gu_user_0287 = "gycapalungan"

    @room_rate = 4167.0
    @drugs = {"040000357" => 1} #ORT02 discount_scheme = 'COMIPLDT001' walang ORT02
    @ancillary = {"010000003" => 1} #ORT01
    @sel_dr_validator = "msgepte"
  end

  after(:all) do
    slmc.logout
    slmc.close_current_browser_session
  end
#
#  it "Validate Serialized Order Number In GU - Order page" do
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => "1")
#    @@pin = slmc.create_new_patient(@patient)
#    slmc.login(@user, @password).should be_true
#    slmc.admission_search(:pin => @@pin)
#    puts @@pin
#    slmc.create_new_admission(:rch_code => "RCH08", :org_code => "0287", :account_class => "COMPANY", :diagnosis => "GASTRITIS", :guarantor_code => "ABSC001").should == "Patient admission details successfully saved."
#
#    slmc.login(@gu_user_0287, @password).should be_true
#    slmc.nursing_gu_search(:pin => @@pin)
#    slmc.go_to_gu_page_for_a_given_pin("Order Page", @@pin)
#    @@visit_no = slmc.get_text("//html/body/div[1]/div[2]/div[2]/div[8]/div[2]/div[3]/div[1]/label")
#    @@visit_no = @@visit_no.gsub(' ','')
#
#    @drugs.each do |drug, q|
#      slmc.search_order(:drugs => true, :code => drug).should be_true
#      slmc.add_returned_order(:description => drug, :quantity => "1.0", :drugs => true, :frequency => "ONCE A WEEK", :add => true).should be_true
#    end
#    @ancillary.each do |anc, q|
#      slmc.search_order(:description => anc, :ancillary => true ).should be_true
#      slmc.add_returned_order(:description => anc, :ancillary => true, :add => true).should be_true
#    end
#    slmc.submit_added_order(:validate => true, :username => "sel_0287_validator")
#    slmc.validate_orders(:drugs => true, :ancillary => true, :multiple => true).should == 2
#    max_ci_no = Database.get_max_ci_no(:username => @gu_user_0287)
#    slmc.confirm_validation_all_items.should be_true
#    or_number = max_ci_no + 1
#    Database.connect
#               l  = "SELECT B.CI_NO FROM SLMC.TXN_OM_ORDER_DTL A JOIN SLMC.TXN_OM_ORDER_GRP B ON A.ORDER_GRP_NO = B.ORDER_GRP_NO WHERE B.VISIT_NO = '#{@@visit_no}'"
#               l1 = Database.select_all_statement l
#    Database.logoff
#    l1[0].should == or_number
#
#  end
  it"Validated The Sequence Of The  CI In Database" do
        Database.connect
               a = "SELECT PERFORMING_UNIT FROM SLMC.MY_CI_TABLE GROUP BY PERFORMING_UNIT"
               ary = Database.select_all_rows a
        Database.logoff
        xxxx  = ary
        #xxxx = '0004'
        yyyy = Time.now.strftime("%Y")
        check_dup = true
        xxxx.each do |anc|
           #      mm = Time.now.strftime("%m")
                    if anc != ""
                              mm = ("05")
                              nnnnnn = "000001"
                              puts anc
                              xxxxyyyymm = anc+ yyyy + mm
                              all_ci = Database.get_details_my_ci(:date =>'02/01/2015', :org_code =>anc )
                              #all_ci = Database.get_details_my_ci(:date =>'02/01/2015 12:00 AM', :org_code =>anc)
                              total_count = all_ci[:ci_no].count
                              current_row = 0
                              while total_count != 0
                                      ci_no = xxxxyyyymm + nnnnnn
                                      ci_from_db = all_ci[:ci_no][current_row]
                                      ci_from_db = ci_from_db.to_s
             #                       ci_from_db.should == ci_no.to_s
                                      if ci_no == "0036201502000019" || ci_no == "0004201502000048" || ci_no == "0008201502000206"
                                                  if ci_from_db != ci_no.to_s
                                                        puts "ci_from_db - #{ci_from_db}"
                                                        puts "EXPECTED ci_no - #{ci_no.to_s}"
            #                                      else
            #                                          puts "list ci_from_db - #{ci_from_db}"
                                                  end
                                                  if check_dup == true
                                                          Database.connect
                                                               a = "SELECT COUNT(*) FROM SLMC.MY_CI_TABLE WHERE CI_NO = '#{ci_from_db}' "
                                                              ary = Database.select_statement a
                                                          Database.logoff
                                                          ci_count  = ary.to_i
                                                  end
                                                  if ci_count  != 1
                                                       nnnnnn = nnnnnn
                                                       ci_count  = ci_count - 1
                                                       check_dup = false
                                                  else
                                                       nnnnnn = nnnnnn.next
                                                       check_dup = true
                                                  end
                                      end
                                      current_row = current_row + 1
                                      total_count = total_count - 1
                              end
                    end
        end
end
#  it"Validated The Sequence Of The  CI In Database2" do
#        Database.connect
#               a = "SELECT PERFORMING_UNIT FROM SLMC.MY_CI_TABLE GROUP BY PERFORMING_UNIT"
#               ary = Database.select_all_rows a
#        Database.logoff
#        xxxx  = ary
##xxxx = '0173'
#        yyyy = Time.now.strftime("%Y")
#        check_dup = true
#        xxxx.each do |anc|
#           #      mm = Time.now.strftime("%m")
#                    if anc != ""
#                              mm = ("01")
#                              nnnnnn = "000001"
#                              puts anc
#                              xxxxyyyymm = anc+ yyyy + mm
#                              all_ci = Database.get_details_my_ci(:date =>'01/26/2015 11:28 AM', :org_code =>anc )
#                              #all_ci = Database.get_details_my_ci(:date =>'02/01/2015 12:00 AM', :org_code =>anc)
#                              total_count = all_ci[:ci_no].count
#                             # current_row = 0
#                             # while total_count != 0
#                                for current_row in 0 .. total_count
#                                      ci_no = xxxxyyyymm + nnnnnn
#                                      ci_from_db = all_ci[:ci_no][current_row]
#                                      ci_from_db = ci_from_db.to_s
#   #                                   ci_from_db.should == ci_no.to_s
#                                      if ci_from_db != ci_no.to_s
#                                            puts "ci_from_db - #{ci_from_db}"
#                                            puts "ci_no - #{ci_no.to_s}"
#                                            next
#                                      end
#                                      if check_dup == true
#                                              Database.connect
#                                                   a = "SELECT COUNT(*) FROM SLMC.MY_CI_TABLE WHERE CI_NO = '#{ci_from_db}' "
#                                                  ary = Database.select_statement a
#                                              Database.logoff
#                                              ci_count  = ary.to_i
#                                      end
#                                      if ci_count  != 1
#                                           nnnnnn = nnnnnn
#                                           ci_count  = ci_count - 1
#                                           check_dup = false
#                                      else
#                                           nnnnnn = nnnnnn.next
#                                           check_dup = true
#                                      end
#
#                                      current_row = current_row + 1
#                                      total_count = total_count - 1
#                              end
#                    end
#        end
#end
#  it"Validated The Sequence Of The  CI In Database3" do
##        Database.connect
##               a = "SELECT PERFORMING_UNIT FROM SLMC.MY_CI_TABLE GROUP BY PERFORMING_UNIT"
##               ary = Database.select_all_rows a
##        Database.logoff
##        xxxx  = ary
#        xxxx = '0173'
#        yyyy = Time.now.strftime("%Y")
#        check_dup = true
#        xxxx.each do |anc|
#
#           #      mm = Time.now.strftime("%m")
#                    if anc != ""
#                              mm = ("01")
#                              nnnnnn = "000001"
#                              puts anc
#                              xxxxyyyymm = anc+ yyyy + mm
#                              all_ci = Database.get_details_my_ci(:date =>'01/26/2015', :org_code =>anc )
#                              #all_ci = Database.get_details_my_ci(:date =>'02/01/2015 12:00 AM', :org_code =>anc)
#                              total_count = all_ci[:ci_no].count
#                              current_row = 0
#                              while total_count != 0
#                                      ci_no = xxxxyyyymm + nnnnnn
#                                      ci_from_db = all_ci[:ci_no][current_row]
#                                      ci_from_db = ci_from_db.to_s
#       #                               ci_from_db.should == ci_no.to_s
#                                      if ci_from_db != ci_no.to_s
#                                            puts "ci_from_db - #{ci_from_db}"
#                                            puts "ci_no - #{ci_no.to_s}"
#                                            next
#                                      end
#                                      if check_dup == true
#                                              Database.connect
#                                                   a = "SELECT COUNT(*) FROM SLMC.MY_CI_TABLE WHERE CI_NO = '#{ci_from_db}' "
#                                                  ary = Database.select_statement a
#                                              Database.logoff
#                                              ci_count  = ary.to_i
#                                      end
#                                      if ci_count  != 1
#                                           nnnnnn = nnnnnn
#                                           ci_count  = ci_count - 1
#                                           check_dup = false
#                                      else
#                                           nnnnnn = nnnnnn.next
#                                           check_dup = true
#                                      end
#
#                                      current_row = current_row + 1
#                                      total_count = total_count - 1
#                              end
#                    end
#        end
#end

end

#1. GU - Order page   === TXN_OM_ORDER_GRP
#2. GU - Package Management   === TXN_OM_ORDER_GRP
#3. SPU - Order page === TXN_OM_ORDER_GRP
#4. SPU - Checklist Order === TXN_OM_ORDER_GRP
#5. DAS OSS - Outpatient Order === TXN_OM_ORDER_GRP
#6. Ancillary Clinical Ordering - Order page === TXN_OM_ORDER_GRP
#7. Ancillary Special Units Module - Order page === TXN_OM_ORDER_GRP
#8. Drug batch posting === TXN_OM_ORDER_GRP
#9. Medical Oxygen posting === TXN_OM_ORDER_GRP
#10. Outpatient Sales ordering (Pharmacy, CSS, FND)
#11. Wellness Outpatient Ordering - Wellness Billing - Payment === TXN_OM_ORDER_GRP
#12. ER Clinical Ordering === TXN_OM_ORDER_GRP
#13. ER Checklist Order === TXN_OM_ORDER_GRP
#14. Pharmacy Clinical Ordering == SLMC.TXN_POS_ORDER_GRP
#15. CSS Clinical Ordering  == SLMC.TXN_POS_ORDER_GRP
#16. Adjustment and Cancellation Module - for order replacement === TXN_OM_ORDER_GRP
#17. Order List - Upon Medical Oxygen discontinuance === TXN_OM_ORDER_GRP
#18. To coordinate with CEMA (Tess) - Order and Pay












