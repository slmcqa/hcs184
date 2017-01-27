#!/bin/env ruby
# encoding: utf-8
require File.dirname(__FILE__) + '/helpers/locators'

module OneStopShop

  #fill out POS/OSS - PATIENT information section
  def oss_patient_info(options={})
    click 'checkPhilhealth' if options[:philhealth]
    click 'checkSenior' if options[:senior] #&& !is_checked("checkSenior")
    sleep 3
    if options[:senior]
             select "id=idTypeCode","label=SENIOR CITIZEN ID" if is_visible("id=idTypeCode")
    end

    type 'seniorIdNumber', '1234' if options[:senior]
    click 'checkMaternity' if options[:maternity]
    if options[:pwd]
      click 'checkPwd', :wait_for => :element, :element =>  'pwdIdNumber'
      type 'pwdIdNumber', options[:pwd_id] || "test123"
      sleep 15
    end
    click 'checkForeign' if options[:foreign]
    sleep 15
  end
  def add_pharmacy_patient(options={})
      click("id=patientToggle");
      click("id=findPatient");
      type("id=patient_entity_finder_key", options[:pin]);
      click("css=#patientFinderForm > div.finderFormContents > div > input[type=\"button\"]");
  end
  # methods to get values of item details
  def get_unit_price
    unit_price = get_text('//*[@id="ops_order_unit_price_0"]').gsub(',','').to_f
    return unit_price
  end
  def get_discount_value
    discount = get_text('//*[@id="ops_order_promo_discount_0"]').gsub(',','').to_f
    return discount
  end
  def get_class_discount_value
    sleep 2
    class_discount = get_text('//*[@id="ops_order_discount_0"]').gsub(',','').to_f
    return class_discount
  end
  def get_vat_value
    vat = get_text('//*[@id="ops_order_vat_0"]').gsub(',','').to_f
    return vat
  end
  def get_net_amount
    get_text('css=#tot_net_amt_span').gsub(',','').to_f
  end
  def get_fixed_courtesy_discount
    get_text('//*[@id="discountAmountFixedDisplay-0"]').gsub(',','').to_f
  end
  def get_percent_courtesy_discount
    get_text('//html/body/div/div[2]/div[2]/form/div[6]/div/div[8]/table/tbody/tr/td[4]').gsub(',','').to_f
  end
  def get_courtesy_discount
    get_text('//*[@id="discountAdditionalDiscountDisplay-0"]').gsub(',','').to_f
  end
  #methods of getting hidden and accurate item details
  def get_db_unit_price
    sleep 5
    db_unit_price = get_value("opsOrderBeans[0].serviceRateStr").gsub(',','').to_f
    return db_unit_price
  end
  def get_db_discount_value
    db_discount_value = get_value("opsOrderBeans[0].promoDisplay").gsub(',','').to_f
    return db_discount_value
  end
  def get_db_class_discount_value
    sleep 2
    db_class_discount = get_value("opsOrderBeans[0].discountDisplay").gsub(',','').to_f
    return db_class_discount
  end
  def get_db_vat_value
    db_vat = get_value("opsOrderBeans[0].vatAmountDisplay").gsub(',','').to_f
    return db_vat
  end
  def get_db_net_amount
    #get_text("tot_net_amt_span").gsub(',','').to_f
    get_text("totalNetAmountDisplay").gsub(',','').to_f
  end
  def get_db_fixed_courtesy_discount
    get_value("discountAmountFixed-0").gsub(',','').to_f
  end
  def get_db_percent_courtesy_discount
    get_value("discountAmountPercentage-0").gsub(',','').to_f
  end
  def get_db_courtesy_discount
    get_value("discountAdditionalDiscount-0").gsub(',','').to_f
  end
  def get_db_discount_net_amount
    get_value("discountNetAmount-0").gsub(',','').to_f
  end
  # methods to get summary totals located in the upper left corner of the OSS form
  def get_total_gross_amount
    get_text('//*[@id="totalAmountDisplay"]').gsub(',','')
  end
  def get_total_promo_amount
    sleep 2
    get_text('//*[@id="headerTotalPromoDisplay"]').gsub(',','')
  end
  def get_total_vat
    get_text('headerTotalVatDisplay').gsub(',','')
  end
  def get_philhealth_claims_amount
    get_text('//*[@id="philHealthDisplay"]').gsub(',','')
  end
  def get_total_class_amount
    get_text('//*[@id="headerTotalClassDisplay"]').gsub(',','')
  end
  def get_package_discount
    get_text('//*[@id="packageDiscountDisplay"]').gsub(',','')
  end
  def get_total_net_amount
    sleep 2
    get_text('//*[@id="totalNetAmountDisplay"]').gsub(',','')
    
  end
  def get_total_discount
    get_text('//*[@id="totalDiscountDisplay"]').gsub(',','')
  end
  def get_total_charged_amount
    get_text('totalChargeAmountDisplay').gsub(',','')
  end
  def get_total_amount_due
    get_text('//*[@id="totalAmountDueDisplay"]').gsub(',','')
  end
  def get_total_pf
    get_text('//*[@id="paymentTotalPfHead"]').gsub(',','')
  end
  # method for items added outside the package
  def get_item_amount(count)
    sleep 5
    get_text("//*[@id='ops_order_amount_" + count.to_s + "']").gsub(',','').to_f
  end
  def get_item_promo_discount(count)
    sleep 10
    get_text("//*[@id='ops_order_promo_discount_" + count.to_s + "']").gsub(',','').to_f
  end
  def get_item_class_discount(count)
    sleep 10
    get_text("//*[@id='ops_order_discount_" + count.to_s + "']").gsub(',','').to_f
  end
  def get_item_net_amount(count)
    sleep 10
    get_text("//*[@id='ops_order_net_amount_" + count.to_s + "']").gsub(',','').to_f
  end
  # methods to get payment summary and billing details from the PAYMENT toggle
  def get_billing_total_net_amount
    get_text('//*[@id="paymentTotalAmount"]').gsub(',','')
  end
  def get_billing_discount_amount
    get_text('//*[@id="paymentTotalDiscount"]').gsub(',','')
  end
  def get_billing_net_after_discount_amount
    get_text('//*[@id="paymentTotalNetAmount"]').gsub(',','')
  end
  def get_billing_total_charge_amount
    get_text('//*[@id="paymentTotalChargeAmount"]').gsub(',','')
  end
  def get_billing_total_amount_due
    get_text('//*[@id="paymentTotalAmountDue"]').gsub(',','')
  end
  def get_billing_total_payments
    get_text('paymentTotalPayments').gsub(',','')
  end
  def get_billing_balance_due_amount
    get_text('//*[@id="balanceDue"]').gsub(',','')
  end
  def get_summary_totals
    sleep 10
    tga = get_total_gross_amount
    tp = get_total_promo_amount
    pc = get_philhealth_claims_amount if is_element_present("philHealthDisplay")
    tv = get_total_vat if is_element_present("headerTotalVatDisplay")
    tcd = get_total_class_amount
    tna = get_total_net_amount
    td = get_total_discount
    tca = get_total_charged_amount
    tad = get_total_amount_due
    tpd = get_package_discount if is_element_present("packageDiscountDisplay")
    tpf = get_total_pf if is_element_present("paymentTotalPfHead")
    return{
      :total_gross_amount => tga,
      :total_promo => tp,
      :philhealth_claims => pc,
      :total_vat => tv,
      :total_class_discount => tcd,
      :total_net_amount => tna,
      :total_discount => td,
      :total_charge_amount => tca,
      :total_amount_due => tad,
      :total_package_discount => tpd,
      :total_pf => tpf
    }
  end
  def get_billing_details
    tna = get_billing_total_net_amount
    disc = get_billing_discount_amount
    nad = get_billing_net_after_discount_amount
    ca = get_billing_total_charge_amount
    tad = get_billing_total_amount_due
    tp = get_billing_total_payments
    bd = get_billing_balance_due_amount
    return{
      :total_net_amount => tna,
      :discount => disc,
      :net_after_discount => nad,
      :charge_amount => ca,
      :total_amount_due => tad,
      :total_payments => tp,
      :balance_due => bd
    }
  end
  def compute_discounts(options={})
    if options[:senior]
      #discount = ((options[:unit_price] * (20.0/100.0)) * 100).round.to_f / 100
      discount = ((options[:unit_price] * 20.0/100.0)* 10**6).round.to_f / 10**6
    elsif options[:promo]
      #discount = ((options[:unit_price] * (16.0/100.0)) * 100).round.to_f / 100
      discount = ((options[:unit_price] * 16.0/100.0)* 10**6).round.to_f / 10**6
    elsif options[:disabled]
      #discount = ((options[:unit_price] * (20.0/100.0)) * 100).round.to_f / 100
      discount = ((options[:unit_price] * 20.0/100.0)* 10**6).round.to_f / 10**6
    elsif options[:foreigner]
      discount = (((options[:unit_price] - options[:mrp]) * 16.0/100.0) * 10**6).round.to_f / 10**6
    elsif options[:scheme]
      #discount = ((options[:unit_price] * (options[:scheme_discount]/100.0)) * 100).round.to_f / 100
      discount = (((options[:unit_price] * (options[:scheme_discount]/100.0)) * 10**6).round.to_f) / 10**6
    end
    return discount
  end
  def compute_class_discount(options={})
    if options[:percent]
      class_discount = ((((options[:unit_price] - options[:discount]) * options[:percent] / 100) * 10**6).round.to_f) / 10**6
    else
      class_discount = (((options[:unit_price] - options[:discount]) * 10**6).round.to_f) / 10**6
    end
    return class_discount
  end
  def compute_vat(options={})
    if options[:senior]
      vat = ((options[:net_promo] - (options[:net_promo] / 1.12)) * 10**6).round.to_f / 10**6
      #vat = ((options[:net_promo] - (options[:net_promo] / 1.12)) * 10**6).round.to_f / 10**6 if options[:class_discount]
    else
      vat = (((options[:net_promo] / 1.12) * 0.12) * 10**6).round.to_f / 10**6
      #vat = ((((options[:net_promo] - options[:class_discount]) / 1.12) * 0.12) * 10**6).round.to_f / 10**6 if options[:class_discount]
    end
    return vat
  end
  def compute_net_amount(options={})
    if options[:senior]
      net_amount = options[:net_promo] - self.compute_vat(options)
    else
      net_amount = options[:net_promo]
    end
    return net_amount
  end
  def compute_courtesy_discount(options={})
    if options[:fixed]
      discount = options[:amount]
    elsif options[:percent]
      #discount =  (options[:net] * ( options[:amount] / 100.0))
      discount = self.truncate_to(options[:net] * ( options[:amount] / 100.0), 2)
    end
    return discount
  end
  # computation of discount, net of promo, vat and net amount in POS
  def pos_computation(options={})
    ## enhancements based on bug # 26159
      if options[:senior]
        gross = (options[:total_gross] * 10**2).round.to_f / 10**2
              mgross =   options[:total_gross]
        puts "gross - #{gross}"
        puts "mgross - #{mgross}"

        disc = ((gross * (20.0/100.0)) * 10**2).round.to_f / 10**2 ## 20% senior discount
              mdisc = (gross * 0.20).round.to_f
          puts"disc - #{disc}"
          puts"mdisc - #{mdisc}"
        net_of_promo = ((gross - disc) * 10**2).round.to_f / 10**2
        vat = ((net_of_promo - (net_of_promo / 1.12)) * 10**2).round.to_f / 10**2
      #vat = ((self.truncate_to(net_of_promo/1.12,1) * (12.0/100.0)) * 10**2).round.to_f / 10**2 # gets only the first decimal value
        net_amount = ((self.truncate_to(gross,2) - self.truncate_to(disc,2) - self.truncate_to(vat,2)) * 10**6 ).round.to_f / 10**6

        puts "net_amount - #{net_amount}"
      else
        gross = (options[:total_gross] * 10**2).round.to_f / 10**2
        disc = (( gross * (16.0/100.0)) * 10**2).round.to_f / 10**2 ## 16% promo discount
        net_of_promo = ((gross - disc) * 10**2).round.to_f / 10**2
      #vat = (((net_of_promo/1.12) * (12.0/100.0)) * 10**2).round.to_f / 10**2
              vat = ((net_of_promo - (net_of_promo / 1.12)) * 10**2).round.to_f / 10**2
        #vat = ((self.truncate_to(net_of_promo/1.12,1) * (12.0/100.0)) * 10**2).round.to_f / 10**2
        net_amount = ((self.truncate_to(gross,2) - self.truncate_to(disc,2)) * 10**2 ).round.to_f / 10**2
        puts "net_amount - #{net_amount}"
      end
    return {
      :gross => gross,
      :discount => disc,
      :net_of_promo => net_of_promo,
      :vat => vat,
      :net_amount => net_amount
    }
  end
  # computation of discount, net of promo and net amount in OSS
  # OSS does not display vat in summary totals
  def oss_computation(options={})
    ## enhancements based on bug # 26159
    if options[:senior]
      gross = (options[:total_gross] * 10**6).round.to_f / 10**6

      disc = ((gross * (20.0/100.0)) * 10**6).round.to_f / 10**6 ## 20% senior discount

      net_of_promo = ((gross - disc) * 10**6).round.to_f / 10**6
      net_amount = ((self.truncate_to(gross,2) - self.truncate_to(disc,2)) * 10**6 ).round.to_f / 10**6
    else
      gross = (options[:total_gross] * 10**6).round.to_f / 10**6
      disc = (( gross * (16.0/100.0)) * 10**6).round.to_f / 10**6 ## 16% promo discount
      net_of_promo = ((gross - disc) * 10**6).round.to_f / 10**6
      net_amount = ((self.truncate_to(gross,2) - self.truncate_to(disc,2)) * 10**6 ).round.to_f / 10**6
    end
    return {
      :gross => gross,
      :discount => disc,
      :net_of_promo => net_of_promo,
      :net_amount => net_amount
    }
  end
  #fill out One Stop Shop - GUARANTOR section
  def oss_add_guarantor(options={})
    sleep 5 if options[:edit]
    click("//table[@id='guarantorListTable']/tbody/tr/td/input") if options[:edit]
    click("edit") if options[:edit]
    if options[:delete]
            click("//table[@id='guarantorListTable']/tbody/tr/td/input") if options[:delete]
            sleep 1 if options[:delete]
            click("delete") if options[:delete]
            return get_css_count("css=#guarantorListTable>tbody>tr")
    else
            sleep 5
            click "guarantorToggle" if !is_visible("guarantorType")
            sleep 3
            select "opsGuarantorBean.accountClassStr", "label=#{options[:acct_class]}" if options[:acct_class]

            sleep 2
            select "guarantorType", "label=#{options[:guarantor_type]}" if options[:guarantor_type]
            return get_alert() if is_alert_present()
            if options[:guarantor_type] == 'INDIVIDUAL'
                 #   (type "guarantorCode", options[:guarantor_name] || get_value("opsPatientBannerBean.lastname")) if is_element_present("guarantorCode")
                    (type "id=guarantorName", options[:guarantor_name] || get_value("opsPatientBannerBean.lastname")) if is_element_present("id=guarantorName")
            else
                    sleep 3
                    click("id=findGuarantor")
                    sleep 3
                    if options[:guarantor_type] == "SOCIAL SERVICE"
                            click "ssPatientFinder"
                            type "ss_patient_entity_finder_key", options[:esc_no] || "234"
                            click "//input[@type='button' and @onclick='SSPF.search();' and @value='Search']", :wait_for => :element, :element => "css=#ss_patient_finder_table_body>tr.even>td>a"
                            click "css=#ss_patient_finder_table_body>tr.even>td>a"
                            sleep 2
                            #        select "departmentCode", options[:dept_code] || "S - MEDICINE"
                            select "departmentCode", options[:dept_code] || "A - PAIN MANAGEMENT"
                    end

                    if options[:guarantor_type] == 'EMPLOYEE'
                            type 'employee_entity_finder_key', options[:guarantor_code]
                            click "//input[@value='Search' and @type='button' and @onclick='EF.search();']"
                    elsif options[:guarantor_type] == 'DOCTOR'
                            type 'ddf_entity_finder_key', options[:guarantor_code]
                            click "//input[@value='Search' and @onclick='DDF.search();']"
                    else
                            type "bp_entity_finder_key", options[:guarantor_code]
                            #click "//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']"
                            click "css=#bpFinderForm > div.finderFormContents > div > input[type=\"button\"]"



                    end
                    sleep 5
#                    if options[:guarantor_type] != 'INDIVIDUAL'
#                            click "//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']" if is_element_present "//input[@value='Search' and @type='button' and @onclick='BusinessPartner.search();']"
#                            sleep Locators::NursingGeneralUnits.waiting_time
#                            click "link=#{options[:guarantor_code]}" if is_element_present("link=#{options[:guarantor_code]}")
#                            click("css=#ddf_finder_table_body>tr>td>div") if is_element_present("css=#ddf_finder_table_body>tr>td>div")
#                            sleep 3
#                    end
            end
            # dependent name
            account_class = options[:acct_class]
            if is_visible("id=dependentFinder")
                    if account_class == "BOARD MEMBER DEPENDENT" || account_class == "DOCTOR DEPENDENT" || account_class == "EMPLOYEE DEPENDENT"
                            click("id=dependentFinder")
                            sleep 6
                            click("//input[@type='button' and @onclick='DOF.search();' and @value='Search']") if (account_class == "BOARD MEMBER DEPENDENT" || account_class == "DOCTOR DEPENDENT")
                            #click("//input[@type='button' and @onclick='EDF.search();' and @value='Search']") if (account_class == "EMPLOYEE DEPENDENT")
                            click("css=#employeeDependentFinderForm > div.finderFormContents > div > input[type=\"button\"]") if (account_class == "EMPLOYEE DEPENDENT")


                            sleep 5
                            click("css=#dep_others_finder_table_body>tr>td:nth-child(2)>a") if (account_class == "BOARD MEMBER DEPENDENT" || account_class == "DOCTOR DEPENDENT")
                            if is_element_present("//tbody[@id='employee_dependent_finder_table_body']/tr/td/a")
                           # click("//tbody[@id='employee_dependent_finder_table_body']/tr/td/a") if account_class == "EMPLOYEE DEPENDENT"
                            click "css=#employeeDependentFinderForm > div.finderFormContents > div > input[type=\"button\"]" if account_class == "EMPLOYEE DEPENDENT"

                            end
                            sleep 8
                            click("//input[@type='button' and @value='Close' and @onclick='DOF.close()']") if (account_class == "BOARD MEMBER DEPENDENT" || account_class == "DOCTOR DEPENDENT")
                            if is_element_present("//input[@type='button' and @value='Close' and @onclick='EDF.close()']")
                            click("//input[@type='button' and @value='Close' and @onclick='EDF.close()']") if account_class == "EMPLOYEE DEPENDENT"
                            end
                    end
            end

            select("relationship", options[:relationship]) if options[:relationship]
            #select coverage amount options
            if options[:coverage_choice] == 'max_amount'
                    check 'max'
                    type 'maximumLimit', options[:coverage_amount].to_s
            elsif options[:coverage_choice] == 'percent'
                    check "percent"
                    type "percentageLimit", options[:coverage_amount].to_s
            end

            if options[:guarantor_add]
                    # click "add"
                    sleep 6
                    click "id=add"
                    sleep 5
                    if is_alert_present()
                            return get_alert()
                    else
                            if options[:guarantor_type] == 'INDIVIDUAL'
                                    name_in_banner = '//*[@id="opsPatientBannerBean.lastname"]'
                                    name_in_list = get_text("css=#guarantorListTableBody>tr>td:nth-child(5)")
                                    puts "name_in_banner -#{name_in_banner}"
                                    puts "name_in_list =#{name_in_list}"
                                    boolean_name = (name_in_list == options[:guarantor_name] || name_in_banner)
#                                    boolean_name = (get_text("css=#guarantorListTableBody>tr>td:nth-child(5)") == #//html/body/div/div[2]/div[2]/form/div[4]/div/div[16]/table/tbody/tr/td[4] 1.3 edited to css in 1.4
#                                    (options[:guarantor_name] || get_value("opsPatientBannerBean.lastname")))
                            else
                                    name_in_list = get_text("css=#guarantorListTableBody>tr>td:nth-child(5)")
                                    boolean_name = ((name_in_list ==  options[:guarantor_code] if options[:guarantor_code])) ||
                                    ((get_text("css=#guarantorListTableBody>tr>td:nth-child(8)") == options[:coverage_amount].to_s if options[:coverage_amount])) ||
                                    ((get_text("css=#guarantorListTableBody>tr>td:nth-child(4)")) == options[:guarantor_code] if options[:guarantor_code])
                            end
                           return boolean_name
                    end
            end
            sleep 5
    end
end

  #fill out One Stop Shop - ORDERS section
  def oss_order(options={})
    click "orderToggle" if !is_visible("find")
    sleep 2 if !is_visible("find")
    if options[:order_add]
              if options[:special]
                          sleep 5
                          click("specialOrder") if !is_checked("specialOrder")
                          description = options[:description] || "sample description"
                          doctor_code = options[:doctor] || "ABAD"
                          org_code = options[:org_code] || "0164"
                          rate = options[:rate] || "1000"
                          quantity = options[:quantity] || "1"
                          remarks = options[:remarks] || "sample remark"
                          sleep 3
                          type("itemDesc", description)
                          click "orderDF"
                          type "entity_finder_key", doctor_code
                          click "//input[@value='Search' and @type='button' and @onclick='DF.search();']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
                           sleep 3
                          click "//tbody[@id='finder_table_body']/tr[1]/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
                          sleep 3
                          click "css=#selectDiv > input[type=\"submit\"]" if is_element_present("css=#selectDiv > input[type=\"submit\"]")
                          sleep 3
					   click "css=input.myButton" if is_element_present( "css=input.myButton")
                          sleep 3													
                          click "css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]" if is_element_present("css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]")
					  sleep 3
					  click "css=#doctorSelectedPopUpDialog > input.myButton" if is_element_present("css=#doctorSelectedPopUpDialog > input.myButton")
				     sleep 3
                          click "name=nursingUnitFinder", :wait_for => :visible, :element => "name=nursingUnitFinder"
                          type "osf_entity_finder_key", org_code
                          click "//input[@value='Search' and @onclick='OSF.search();']", :wait_for => :element, :element => "//tbody[@id='osf_finder_table_body']/tr[1]/td[2]/a"
                          click "css=div.searchArea > input[type=\"button\"]" if is_element_present("css=div.searchArea > input[type=\"button\"")													
                          sleep 3
                          click "//tbody[@id='osf_finder_table_body']/tr[1]/td[2]/a", :wait_for => :not_visible, :element => "//tbody[@id='osf_finder_table_body']/tr[1]/td[2]/a"
				        sleep 3
						click "link=#{org_code}"  if is_element_present("link=#{org_code}")								 
#                          click "css=#selectDiv > input[type=\"submit\"]" if is_element_present("css=#selectDiv > input[type=\"submit\"]")
#                          sleep 3
#					   click "css=input.myButton" if is_element_present( "css=input.myButton")
#                          sleep 3													
#                          click "css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]" if is_element_present("css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]")
#				                       sleep 3
#					   click "css=input.myButton" if is_element_present( "css=input.myButton")
		
                          type("serviceRateDisplay", rate)
                          type("quantity", quantity)
                          type("remarks", remarks)
                          sleep 3
                          unit_price = get_value("serviceRateDisplay")
                          click("addOrder")
                          sleep 10
					 if is_text_present("Please choose")
							click "id=isMaintenanceMedYes" if is_element_present("id=isMaintenanceMedYes")
						#	click "id=isMaintenanceMedNo"
						     click("addOrder")
							sleep 10
					 end
                          count = get_css_count("css=#tableRows>tr")
                          count.times do |rows|
                            my_row = get_text("//*[@id='ops_order_description_#{rows}']")
                            return true if my_row.include?(description)
                          end
                          click "specialOrder" if get_value("specialOrder") == "on" && is_element_present("specialOrder")
              elsif options[:fnb_special]
                          click "find"
                          type "oif_entity_finder_key", options[:item_code]
                          select 'locationFilter',options[:filter] if options[:filter]
                          click "//input[@value='Search' and @type='button' and @onclick='OIF._page_counter = 0;OIF.search();']"
                          sleep Locators::NursingGeneralUnits.waiting_time
                          type "quantity", options[:quantity] if options[:quantity]
                          click "link=#{options[:item_code]}" if is_element_present("link=#{options[:item_code]}")
                          type "itemDesc", options[:item_desc] if options[:item_desc]
                          type "serviceRateDisplay", options[:service_rate] if options[:service_rate]
                          sleep 3
                          unit_price = get_value("serviceRateDisplay")
                          click("addOrder")
                          sleep 10
                          if is_element_present('//*[@id="ops_order_chk_0"]')
                            (get_text('//*[@id="ops_order_item_code_0"]') == options[:item_code] || (get_text('//*[@id="ops_order_description_0"]').include? options[:item_code])) &&
                              get_text('//*[@id="ops_order_unit_price_0"]') == unit_price ||
                              get_text('//*[@id="totalAmountDisplay"]') ==  get_text('//*[@id="tot_amt_span"]')
                          elsif is_element_present('//*[@id="ops_order_item_code_0"]')
                            get_text('css=tbody[id="tableRows"]').empty? == false
                          else
                            return false
                          end
              else
#                          if is_element_present("specialOrder")
#                            click("specialOrder") if is_checked("specialOrder")
#                          end
                          click "find", :wait_for => :element, :element => "oif_entity_finder_key"
                          sleep 1
                          type "oif_entity_finder_key", options[:item_code]
                          select 'locationFilter',options[:filter] if options[:filter]
                          click("//input[@type='button' and @onclick='OIF._page_counter = 0;OIF.search();' and @value='Search']")#, :wait_for => :element, :element => "link=#{options[:item_code]}")
                          sleep 5
                          if is_element_present"link=#{options[:item_code]}"
                            sleep 1
                            click "link=#{options[:item_code]}" if is_element_present("link=#{options[:item_code]}")
                          end
                          sleep 3
                          type "quantity", options[:quantity] if options[:quantity]
                          type "itemDesc", options[:item_desc] if options[:item_desc]
                          type "serviceRate", options[:service_rate] if options[:service_rate]
                          type "serviceRateDisplay", options[:service_rate_display] if options[:service_rate_display]
                          click "prescription" if options[:prescription]
                          if options[:doctor]
                            click "orderDF"
                            type "entity_finder_key", options[:doctor]
                            click "//input[@value='Search' and @type='button' and @onclick='DF.search();']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
                            sleep 2
                            click "//tbody[@id='finder_table_body']/tr[1]/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
                            sleep 2
                            click "css=#selectDiv > input[type=\"submit\"]" if is_element_present("css=#selectDiv > input[type=\"submit\"]")
                            click "css=input.myButton" if is_element_present( "css=input.myButton")
                            sleep 2
						click "css=#doctorSelectedPopUpDialog > input.myButton"
						sleep 2								
                            click "css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]" if is_element_present("css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]")
                            sleep 2
                          end
					if options[:isi_maintenance] == "Yes"
							click "id=isMaintenanceMedYes" if is_element_present("id=isMaintenanceMedYes")
						#	click "id=isMaintenanceMedNo"
						    # click("addOrder")
							sleep 3
					else
						click "id=isMaintenanceMedNo"
						sleep 3
					 end													
                          sleep 1
                          unit_price = get_value("serviceRate")
                          type "remarks", "remarks"
                          click "addOrder"
                          sleep 4
                          if is_element_present('//*[@id="ops_order_chk_0"]')
                            (get_text('//*[@id="ops_order_item_code_0"]') == options[:item_code] || (get_text('//*[@id="ops_order_description_0"]').include? options[:item_code])) &&
                              get_text('//*[@id="ops_order_unit_price_0"]') == unit_price ||
                              get_text('//*[@id="totalAmountDisplay"]') ==  get_text('//*[@id="tot_amt_span"]')
                          elsif is_element_present('//*[@id="ops_order_item_code_0"]')
                            get_text('css=tbody[id="tableRows"]').empty? == false
                          else
                            return false
                          end
              end
      elsif options[:order_edit] # currently works for the first item
              item = get_text('//*[@id="ops_order_description_0"]')
              click("link=Edit")
              sleep 2
              click("genericName") if options[:generic_name]
              click("prescription") if options[:without_prescription]
              click("vitaminCheck") if options[:vitamins]
              if options[:doctor]
                click "orderDF"
                type "entity_finder_key", options[:doctor]
                click "//input[@value='Search' and @type='button' and @onclick='DF.search();']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
                sleep 2
                click "//tbody[@id='finder_table_body']/tr[1]/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
                sleep 2
                click "css=#selectDiv > input[type=\"submit\"]" if is_element_present("css=#selectDiv > input[type=\"submit\"]")
                click "css=input.myButton" if is_element_present( "css=input.myButton")
                sleep 2
                click "css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]" if is_element_present("css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]")
                sleep 2                
              end
              type("quantity", options[:quantity]) if options[:quantity]
              click("editOrder")
              is_element_present("ops_order_item_code_0")
  elsif options[:order_delete] # currently works for the first item
            item = get_text('//*[@id="ops_order_description_0"]')
            check "ops_order_chk_0"
            click "deleteOrder"
            sleep 2
            if is_element_present("css=#tableRows>tr")
              get_text("css=#tableRows>tr>td:nth-child(32)").include?(item) == false
            else
              return true if !is_element_present("css=#opsOrderTable>tbody>tr")
            end
    elsif options[:check_item]
			
               if is_element_present("specialOrder")
                      click("specialOrder") if is_checked("specialOrder")
               end
               click "find", :wait_for => :element, :element => "oif_entity_finder_key"
               sleep 1
               type "oif_entity_finder_key", options[:item_code]
               select 'locationFilter',options[:filter] if options[:filter]
               click("//input[@type='button' and @onclick='OIF._page_counter = 0;OIF.search();' and @value='Search']")#, :wait_for => :element, :element => "link=#{options[:item_code]}")
               sleep 5
    end
  end
  def oss_verify_new(options ={})
        if is_element_present("specialOrder")
               click("specialOrder") if is_checked("specialOrder")
        end
        click "find", :wait_for => :element, :element => "oif_entity_finder_key"
        sleep 1
        type "oif_entity_finder_key", options[:item_code]
        select 'locationFilter',options[:filter] if options[:filter]
        click("//input[@type='button' and @onclick='OIF._page_counter = 0;OIF.search();' and @value='Search']")#, :wait_for => :element, :element => "link=#{options[:item_code]}")
        sleep 5
        if is_element_present"link=#{options[:item_code]}"
            sleep 1
            click "link=#{options[:item_code]}" if is_element_present("link=#{options[:item_code]}")
        end
        sleep 3
        type "quantity", options[:quantity] if options[:quantity]
        type "itemDesc", options[:item_desc] if options[:item_desc]
        type "serviceRate", options[:service_rate] if options[:service_rate]
        type "serviceRateDisplay", options[:service_rate_display] if options[:service_rate_display]
        click "prescription" if options[:prescription]
        if options[:doctor]
            click "orderDF"
            type "entity_finder_key", options[:doctor]
            click "//input[@value='Search' and @type='button' and @onclick='DF.search();']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
            sleep 2
            click "//tbody[@id='finder_table_body']/tr[1]/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
            click "css=input.myButton" if is_element_present("css=input.myButton")
            click "css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]"  if is_element_present("css=#doctorSelectedPopUpDialog > div > input[type=\"submit\"]")

        end
        sleep 1
        unit_price = get_value("serviceRate")
        type "remarks", "remarks"
        click "addOrder"
        sleep 4
        if is_element_present('//*[@id="verifyItemAction"]')
               click"id=updact1" if options[:update_quantity]
               click"id=updact2" if options[:override]
               click"id=updact3" if options[:new_line]
               click"id=updact4" if options[:openitem]
               click("//input[@value='Proceed']");
        end
 if is_element_present('//*[@id="ops_order_chk_0"]')
            (get_text('//*[@id="ops_order_item_code_0"]') == options[:item_code] || (get_text('//*[@id="ops_order_description_0"]').include? options[:item_code])) &&
            get_text('//*[@id="ops_order_unit_price_0"]') == unit_price ||
            get_text('//*[@id="totalAmountDisplay"]') ==  get_text('//*[@id="tot_amt_span"]')
        elsif is_element_present('//*[@id="ops_order_item_code_0"]')
            get_text('css=tbody[id="tableRows"]').empty? == false
        else
            return false
        end
  end
  def oss_edit_order(options ={})
    if options[:oss]
      count = get_css_count("css=#tableRows>tr")
      count.times do |rows|
        my_row = get_text("//tbody[@id='tableRows']/tr[#{rows + 1}]/td[2]") if is_element_present("//tbody[@id='tableRows']/tr[#{rows + 1}]/td[2]")
        if my_row.to_s == options[:item_code].to_s
          stop_row = rows
          click "//tbody[@id='tableRows']/tr[#{stop_row + 1}]/td[11]/a"
          sleep 1
        end
      end
      if options[:doctor_code]
        click "orderDF"
        type "entity_finder_key", options[:doctor_code]
        click "//input[@value='Search' and @type='button' and @onclick='DF.search();']", :wait_for => :element, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
        sleep 1
        click "//tbody[@id='finder_table_body']/tr[1]/td[2]/div", :wait_for => :not_visible, :element => "//tbody[@id='finder_table_body']/tr[1]/td[2]/div"
        sleep 1
      end
      click "prescription" if options[:prescription]
      click "vitaminCheck" if options[:vitamins]
      type "quantity", options[:quantity] if options[:quantity]
      type "remarks", options[:remarks] if options[:remarks]
      click "editOrder" if options[:edit]
      sleep 3 if options[:edit]
      get_value("remarks") == "" if options[:edit]
    elsif options[:fnb]
      click "link=#{options[:edit_link]}", :wait_for => :page  if is_element_present("link=#{options[:edit_link]}")
      sleep 5
      type "remarks", "Sample Remark"
      type "serviceRateStr","624.00"
      click "//input[@name='add' and @value='SAVE']", :wait_for => :page
      editsuccess = get_text("successMessages")
      return editsuccess
    end
  end
  def oss_add_discount(options={})
    sleep 6
	count_before = get_css_count("css=#discountDetails>tr")
	item_code = get_text("css=#ops_order_item_code_0")
	puts "itemcode#{item_code}"
	click "discountToggle" if !is_visible("discountTypeCode")
	sleep 6
	puts "itemcode1#{item_code}"
	select "discountTypeCode",options[:discount_type] if options[:discount_type]
	puts "itemcode1#{item_code}"
	select "id=endorsedSelect", "label=OTHERS"
	type "id=endorsed", "asdasdas"
	select "id=approvedSelect", "label=OTHERS"
	type "id=approved", "dasdasda"

		
    if options[:scope] == "dept"
      click "id=discountScopeDepartment"
    elsif options[:scope] == "service"
      click "id=discountScopeService"
      puts "      click discountScopeService"
    elsif options[:scope] == "ancillary"
     # click "discountScopeAncillary"
      click "id=discountScopeAncillary"
    end
    sleep 6
    if options[:type] == "percent"
      click "id=discountAmountPercentage"
    elsif options[:type] == "fixed"
      click "id=discountAmountFixed"
      puts "click fixed"
    end


    sleep 6
    type "discountAmount", options[:amount]
    puts "discountAmount"
    click "viewOrderList", :wait_for => :element, :element => "okOrderDetail"
    puts "click viewOrderList"
    sleep 5
     get_alert() if is_alert_present()

    if options[:dept]
          sleep 6
      wait_for(:wait_for => :ajax)
          sleep 6
      select "departmentSelection", "label=#{options[:dept]}"
    elsif options[:service] || options[:discount_all]
      if options[:discount_all]
            sleep 6
        select "serviceSelection", "label="
      else
            sleep 6
        select "serviceSelection", "label=#{item_code} - #{options[:service]}"
      end
    end
    sleep 6
    click "okOrderDetail"
    click "cancelOrderDetail" if is_visible("cancelOrderDetail")
    count_after = get_css_count("css=#discountDetails>tr")
    puts count_before
    puts count_after
    return false if is_text_present("Discount amount should not be greater than Total Net Amount.")
    return true if count_after > count_before
  end
  #fill out One Stop Shop - PAYMENT section
  def oss_add_payment(options={})
    click "deposit" if options[:deposit]
    if is_element_present("checkSenior")
      type "seniorIdNumber", "12340787" if is_checked("checkSenior")
    end
    click "hospitalPayment" if is_element_present("hospitalPayment")
    click "paymentToggle" if is_element_present("paymentToggle")
    sleep 5
    if options[:type] == "CASH" # only in Social Service when paying Patient Share
      sleep 3
      click "cashPaymentMode1"
      sleep 3
      type "cashBillAmount", options[:amount]
      click "cashAmountInPhp"
      sleep 3
      click "cashAmountInPhp"
      sleep 5
      if options[:payment_amount]
        type "cashAmountInPhp", options[:amount]
      end
      get_value('//*[@id="cashChangeInPhp"]') == "0.00"
    elsif options[:type] == "CHECK"
      click "checkPaymentMode1"
      sleep 3
      type("cBankName", options[:bank_name])
      type("cCheckNo", options[:check_no])
      select("cCurrency", "label=#{options[:currency]}") if options[:currency]
      type("cCheckDate", options[:date])
      type("cCheckAmount", options[:amount])
      select("cCheckType", "label=#{options[:check_type]}") if options[:check_type]
      click("addCheckPayment")
      sleep 3
    elsif options[:type] == "BANK"
      click "opsPaymentBean.bankRemittanceMode1"
      type "brBank", options[:bank_name] || "Bank"
      type "brBranchDeposited", options[:bank_branch] || "Branch"
      type "brRemittanceAmount", options[:amount]
      type "brTransactionNumber", options[:trans_no] || "Transaction_number"
      #type "brTransactionDate", options[:date]
      click "addBankRemittancePayment"
    elsif options[:type] == "CREDIT CARD"
      click "creditCardPaymentMode1"
      sleep 3
      select "ccCompany", "label=CITIBANK - PAYLITE"
      type "ccNo", options[:credit_no] || "4111111111111111"
      select "ccType", "label=VISA"
      click "ccHolder"
      type "ccHolder", options[:cc_holder] || "TEST"
      type "ccExpiryDate", Time.now.strftime("%m/%d/%Y")
      type "ccApprovalNo", options[:cc_approv] ||"1234"
      type "ccSlipNo", options[:cc_slip] || "143"
      type "ccAccountNo", options[:cc_acctno] || "124"
      type "ccAmount", options[:amount]
      click "addCreditCardPayment"
    elsif options[:type] == "GIFT CHECK"
            click("id=giftCheckPaymentMode1");
            type "id=gcNo", options[:gc_no] || Time.now.strftime("%m/%d/%Y")
           gc_donomination = options[:gc_denomination] || "SERVICE"
            select "id=gcDenomination", "label=#{gc_donomination}"
            type"id=gcAmount", options[:amount] || "123"
            click("id=addGiftCheckPayment");
            sleep 5
    end
  end
  #fill out One Stop Shop - PHILHEALTH sectio
  def oss_input_philhealth(options={})
    claim_type = options[:claim_type] || "ACCOUNTS RECEIVABLE"
    select "claimType", "label=#{claim_type}"
    click "btnDiagnosisLookup", :wait_for => :element, :element => "icd10_entity_finder_key"
    type "icd10_entity_finder_key", options[:diagnosis] if options[:diagnosis]
    click "//input[@value='Search' and @type='button' and @onclick='Icd10Finder.search();']"
    sleep Locators::NursingGeneralUnits.waiting_time
    diagnosis = options[:diagnosis] || "CHOLERA"
    click "link=#{diagnosis}"
    sleep 2
    if options[:case_type]
              #select "philHealthBean.medicalCaseType", "label=#{options[:case_type]}"
              puts "options[:case_type] not used"
    end
    if options[:rvu_code]
          options[:case_rate_name] = options[:rvu_code]
          options[:case_rate] =  options[:rvu_code]
          options[:case_rate_type] = "SURGICAL"
    end
    type "philHealthBean.memberInfo.membershipID", options[:philhealth_id] if options[:diagnosis]

    select("philHealthBean.phCaseRateType", options[:case_rate_type]) if options[:case_rate_type]


    sleep 2 if options[:case_rate_type]

    if options[:case_rate_type] == "SURGICAL"
            click "id=btnCaseRateLookup"
            type "id=rvs_entity_finder_key", options[:case_rate]
            sleep 6
            click "css=#rvsAction > input[type=\"button\"]"
            sleep 6
            click "link=#{options[:case_rate_name]}"
    end


    
    type "philHealthBean.memberInfo.memberAddress", "Address"
    type "philHealthBean.memberInfo.memberCity", "City"
    type "philHealthBean.memberInfo.memberProvince", "Province"
    select "philHealthBean.memberInfo.memberCountry", "label=PHILIPPINES"
    type "philHealthBean.memberInfo.memberPostalCode", "1234"
    type "philHealthBean.memberInfo.employerName", "Employer"
    type "philHealthBean.memberInfo.employerAddress.address", "Address"
    type "philHealthBean.memberInfo.employerAddress.city", "City"
    type "philHealthBean.memberInfo.employerAddress.province", "Province"
    select "philHealthBean.memberInfo.employerAddress.country", "label=PHILIPPINES"
    type "philHealthBean.memberInfo.employerAddress.postalCode", "1234"
    type "philHealthBean.memberInfo.employerMembershipID", "4321"
    sleep 1    
    type("seniorIdNumber", "456098986") if is_checked("checkSenior")
#####    if options[:rvu_code]
#####      click "btnRVULookup"
#####      type "rvu_entity_finder_key", options[:rvu_code]
#####      click "//input[@value='Search' and @type='button' and @onclick='RVU.search();']", :wait_for => :element, :element => "css=#rvu_finder_table_body>tr>td>div"
#####      sleep 2
#####      click "css=#rvu_finder_table_body>tr>td>div", :wait_for => :not_visible, :element => "css=#rvu_finder_table_body>tr>td>div"
#####    end

        select "id=doctorsList0.firstCasePhDocSpec", "label=SURGEON" if options[:surgeon_type]
        select "id=doctorsList0.firstCasePhDocSpec", "label=ANESTHESIOLOGIST" if options[:anesthesiologist_type]
  sleep 6
     if options[:case_rate_pf2]
                 click "id=2ndCaseDoctor-0" if is_element_present("id=2ndCaseDoctor-0")
     else
                click "id=1stCaseDoctor-0" #if is_element_present("id=1stCaseDoctor-0")

     
     end
   sleep 10
        if get_value("id=1stCaseDoctor-0") == ("off")
                 click "id=1stCaseDoctor-0"
        end
    if options[:compute]
      click "computeClaims"
      sleep 15

      arbc = (get_text Locators::OSS_Philhealth.actual_rb_availed_charges).gsub(",","") if is_element_present Locators::OSS_Philhealth.actual_rb_availed_charges
      arbb = (get_text Locators::OSS_Philhealth.actual_rb_availed_benefit_claim).gsub(",","") if is_element_present Locators::OSS_Philhealth.actual_rb_availed_benefit_claim
      amc = (get_text Locators::OSS_Philhealth.actual_medicine_charges).gsub(",","") if is_element_present Locators::OSS_Philhealth.actual_medicine_charges
      amb = (get_text Locators::OSS_Philhealth.actual_medicine_benefit_claim).gsub(",","") if is_element_present Locators::OSS_Philhealth.actual_medicine_benefit_claim
      alc = (get_text Locators::OSS_Philhealth.actual_lab_charges).gsub(",","") if is_element_present Locators::OSS_Philhealth.actual_lab_charges
      albc = (get_text Locators::OSS_Philhealth.actual_lab_benefit_claim).gsub(",","") if is_element_present Locators::OSS_Philhealth.actual_lab_benefit_claim
      aoc = (get_text Locators::OSS_Philhealth.actual_operation_charges).gsub(",","") if is_element_present Locators::OSS_Philhealth.actual_operation_charges
      aobc = (get_text Locators::OSS_Philhealth.actual_operation_benefit_claim).gsub(",","") if is_element_present Locators::OSS_Philhealth.actual_operation_benefit_claim
      tac = (get_text Locators::OSS_Philhealth.actual_total_charges).gsub(",","") if is_element_present Locators::OSS_Philhealth.actual_total_charges
      tabc = (get_text Locators::OSS_Philhealth.actual_total_benefit_claim).gsub(",","") if is_element_present Locators::OSS_Philhealth.actual_total_benefit_claim
      mbd = (get_text Locators::OSS_Philhealth.max_benefit_drugs).gsub(",","") if is_element_present Locators::OSS_Philhealth.max_benefit_drugs
      mbxlo = (get_text Locators::OSS_Philhealth.max_benefit_xray_lab_others).gsub(",","") if is_element_present Locators::OSS_Philhealth.max_benefit_xray_lab_others
      ddc = (get_text Locators::OSS_Philhealth.drugs_deduction_claims).gsub(",","") if is_element_present Locators::OSS_Philhealth.drugs_deduction_claims
      drbc = (get_text Locators::OSS_Philhealth.drugs_remaining_benefit_claims).gsub(",","") if is_element_present Locators::OSS_Philhealth.drugs_remaining_benefit_claims
      ldc = (get_text Locators::OSS_Philhealth.lab_deduction_claims).gsub(",","") if is_element_present Locators::OSS_Philhealth.lab_deduction_claims
      lrbc = (get_text Locators::OSS_Philhealth.lab_remaining_benefit_claims).gsub(",","") if is_element_present Locators::OSS_Philhealth.lab_remaining_benefit_claims
      odc = (get_text Locators::OSS_Philhealth.operation_deduction_claims).gsub(",","") if is_element_present Locators::OSS_Philhealth.operation_deduction_claims
      aac = (get_text Locators::OSS_Philhealth.anesthesiologist_actual_charges).gsub(",","") if is_element_present Locators::OSS_Philhealth.anesthesiologist_actual_charges
      abc = (get_text Locators::OSS_Philhealth.anesthesiologist_benefit_claim).gsub(",","") if is_element_present Locators::OSS_Philhealth.anesthesiologist_benefit_claim
      sac = (get_text Locators::OSS_Philhealth.surgeon_actual_charges).gsub(",","") if is_element_present Locators::OSS_Philhealth.surgeon_actual_charges
      sbc = (get_text Locators::OSS_Philhealth.surgeon_benefit_claim).gsub(",","") if is_element_present Locators::OSS_Philhealth.surgeon_benefit_claim

      return {
        :actual_rb_availed_charges => arbc,
        :actual_rb_availed_benefit_claim => arbb,
        :actual_medicine_charges => amc,
        :actual_medicine_benefit_claim => amb,
        :actual_lab_charges => alc,
        :actual_lab_benefit_claim => albc,
        :actual_operation_charges => aoc,
        :actual_operation_benefit_claim => aobc,
        :total_actual_charges => tac,
        :total_actual_benefit_claim => tabc,
        :max_benefit_drugs => mbd,
        :max_benefit_xray_lab_others => mbxlo,
        :drugs_deduction_claims => ddc,
        :drugs_remaining_benefit_claims => drbc,
        :lab_deduction_claims => ldc,
        :lab_remaining_benefit_claims => lrbc,
        :operation_deduction_claims => odc,
        :actual_anesthesiologist_charges => aac,
        :anesthesiologist_benefit_claim => abc,
        :actual_surgeon_charges => sac,
        :surgeon_benefit_claim => sbc
      }

    end
  end
  def oss_verify_order_list
    count = get_xpath_count("//html/body/div/div[2]/div[2]/form/div[5]/div/div[15]/table/tbody/tr").to_i

    orders = []
    count.times do |i|
      orders << get_text("//html/body/div/div[2]/div[2]/form/div[5]/div/div[15]/table/tbody/tr[#{i + 1}]/td[3]")
    end
    return orders
  end
  # submit One Stop Shop form
  def oss_submit_order(value="def")
    #type 'seniorIdNumber', '1234' if (get_text('seniorIdNumber') == "" && is_visible('seniorIdNumber'))
        sleep 20
    click "id=submitForm"

    sleep 20
puts "value = #{value}"		
    if is_element_present"warningMessages"
      warning = get_text("warningMessages")
    else
			 sleep 50
      #wait_for(:wait_for => :element, :element => "popup_ok")
    end
    if value == "yes"
      click "popup_ok"
      sleep 10
      click "tagDocument" if is_element_present("tagDocument")
      sleep 6
      click "popup_ok" if (is_element_present("popup_ok") && (is_visible("popup_ok")))
      sleep 6
      warning = get_text("css=div[id='successMessages']")
    elsif value == "no"
      click "popup_cancel"
      sleep 2
      warning =  get_text("css=div[id='successMessages']")
    elsif (value == "hmo" || value == "class")
      warning = get_text("css=li[class='breadCrumbSub']")
    elsif value == "oss_submit"
      is_element_present "errorMessages"
      warning = get_text("errorMessages")
    elsif value == "view"
      warning = is_element_present("tagDocument")
    else
      sleep 2
      warning = get_text("warningMessages")
    end
    return warning
  end
  def submit_package_order(value)
    click "_submit", :wait_for => :page
    sleep 5
    if value == "yes"
      click "popup_ok"
      click "tagDocument", :wait_for => :page if is_element_present("tagDocument")
      warning = get_text "css=div[id='successMessages']" if is_text_present "css=div[id='successMessages']"
    elsif value == "no"
      click "popup_cancel"
      click "tagDocument", :wait_for => :page if is_element_present("tagDocument")
      warning =  get_text "css=div[id='successMessages']"
    end
    return warning
  end
  def submit_order
    sleep 20
    click "submitForm"  # :wait_for => :page
    
        sleep 20
    if is_element_present"warningMessages"
      click "cashPaymentMode1"
      click "submitForm" ##:wait_for => :page
          sleep 30
    end
    is_element_present("popup_ok") || is_text_present("Point of Sales")
  end
  def print_or_confirmation(value="def")
    if value == "yes"
      click "popup_ok"
      click "tagDocument", :wait_for => :page
      warning = get_text("//html/body/div/div[2]/div[2]/div[3]/div")
    elsif value == "no"
      click "popup_cancel"
      click "tagDocument", :wait_for => :page
      warning = get_text("//html/body/div/div[2]/div[2]/div[3]/div")
    elsif value == "hmo"
      warning = get_text("//html/body/div/div[2]/div[2]/div/div/ul/li")
    else
      warning = get_text("//html/body/div/div[2]/div[2]/form/div[4]/div")
    end
    return warning
  end
  def get_confinement_number
    confinement_no = get_text('//*[@id="banner.visitNo"]')
    return confinement_no
  end
  def ci_search(options={})
    type Locators::OrderAdjustmentAndCancellation.start_date_search, options[:start_date] || Time.now.strftime("%m/%d/%Y")
    type Locators::OrderAdjustmentAndCancellation.end_date_search, options[:end_date] || Time.now.strftime("%m/%d/%Y")
    if options[:request_unit]
      click Locators::OrderAdjustmentAndCancellation.requesting_unit_search_icon, :wait_for => :element, :element => Locators::OrderAdjustmentAndCancellation.search_textbox
      type Locators::OrderAdjustmentAndCancellation.search_textbox, options[:request_unit]
      type Locators::OrderAdjustmentAndCancellation.search_textbox, "0332" if (options[:request_unit] == '0278' && CONFIG['location'] == 'QC')
      click Locators::OrderAdjustmentAndCancellation.search_button, :wait_for => :element, :element => "link=#{options[:request_unit]}"
      click "link=#{options[:request_unit]}"
      sleep 3
    end
    if options[:patient_type]
      select "patientType", "label=#{options[:patient_type]}"
    end
    click Locators::OrderAdjustmentAndCancellation.ci_search_button, :wait_for => :page
  end
  def oss_click_adjust_order(options={})
    count = get_css_count("css=#results>tbody>tr")

    count.times do |rows|
      my_row = get_text("css=#results>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)") if is_element_present("css=#results>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)")
      if my_row == options[:ci_no]
        stop_row = rows
        click "css=#results>tbody>tr:nth-child(#{stop_row + 1})>td:nth-child(5)>div>a", :wait_for => :page
      end
    end
    is_text_present("Order Number: #{options[:ci_no]}")
  end
  def oss_click_cancel_order(options={})
#    count = get_css_count("css=#results>tbody>tr")
#      puts "body count= #{count}"

    count = get_css_count("//html/body/div[1]/div[2]/div[2]/div[9]/div[2]/table/tbody/tr")
      puts "body count= #{count}"
    count.times do |rows|
      my_row = get_text("css=#results>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)")
      puts "my_row - #{my_row}"
  #("//html/body/div[1]/div[2]/div[2]/div[9]/div[2]/table/tbody/tr[1]/td[2]")
    #  puts "my_row - #{my_row}"
      if my_row == options[:ci_no]
        stop_row = rows
        click "css=#results>tbody>tr:nth-child(#{stop_row + 1})>td:nth-child(5)>div:nth-child(2)>a"

      end
    end
    sleep 5
    #is_text_present("Proceed and cancel this order with CI No. #{options[:ci_no]}?")
    is_text_present("Proceed and cancel this order with Order No. #{options[:ci_no]}?")


  end
  # can choose either edit cancel or replace in order adjustment and cancellation (still unfinished, finished only CANCEL
  def oss_select_specific_order_adjustment(options={})
    count = get_css_count("css=#row>tbody>tr")
    puts "count - #{count}"
  #  item_code = @@visit_no
    count.times do |rows|
            # my_row = get_text("css=#row>tbody>tr:nth-child(#{rows + 1})>td[1]")
            my_row = get_text("css=#row>tbody>tr:nth-child(#{rows + 1})>td")
      
            puts "rows  = #{rows}"
            #      "//html/body/div[1]/div[2]/div[2]/form/div[1]/div[2]/table/tbody/tr[1]/td[1]"
            #      "//html/body/div[1]/div[2]/div[2]/form/div[1]/div[2]/table/tbody/tr[2]/td[1]  "
            my_row = my_row.gsub(" ","")
            puts ":item_code = #{options[:item_code]}"
           puts "my_row = #{my_row}"
            if my_row == options[:item_code]
                    stop_row = rows + 1
                    puts "yes item code and myrow is eequal"
                    click "css=#row>tbody>tr:nth-child(#{stop_row})>td:nth-child(5)>div>a" if options[:edit]
                    click "css=#row>tbody>tr:nth-child(#{stop_row})>td:nth-child(5)>div:nth-child(2)>a" if options[:cancel]
             #       click "//html/body/div[1]/div[2]/div[2]/form/div[1]/div[2]/table/tbody/tr[#{stop_row}]/td[5]/div[2]/a"  if options[:cancel]
                   #          "//html/body/div[1]/div[2]/div[2]/form/div[1]/div[2]/table/tbody/tr[1]/td[5]/div[2]/a"
                    click "css=#row>tbody>tr:nth-child(#{stop_row + 1})>td:nth-child(5)>div:nth-child(3)>a" if options[:replace]
                    #        click "css=#row>tbody>tr:nth-child(#{stop_row})>td:nth-child(5)>div>a" if options[:edit]
                    #        click "css=#row>tbody>tr:nth-child(#{stop_row})>td:nth-child(5)>div:nth-child(2)>a" if options[:cancel]
                    #        click "css=#row>tbody>tr:nth-child(#{stop_row})>td:nth-child(5)>div:nth-child(3)>a" if options[:replace]
                    #        "//html/body/div[1]/div[2]/div[2]/form/div[1]/div[2]/table/tbody/tr[1]/td[5]/div[2]"
#            else
#                    click "css=#verifyDetailAdjustment_div>center>div:nth-child(2)>input:nth-child(4)", :wait_for => :page if options[:edit]
#                    click "css=#verifyDetailCancel_div>center>div:nth-child(2)>input:nth-child(5)", :wait_for => :page if options[:cancel]
#                    click "css=#verifyDetailReplacement_div>center>div:nth-child(2)>input:nth-child(5)", :wait_for => :page if options[:replace]
            end
    end
    sleep 6
    click "xpath=(//input[@value='Proceed'])[2]" if is_element_present( "xpath=(//input[@value='Proceed'])[2]")
    puts "proceed"
    if options[:cancel]
		#select("reason", "CANCELLATION - DOCTOR'S ORDER")
		#select "id=cboCancelReason", "label=CANCELLATION - DOCTOR'S ORDER"  if is_element_present("id=cboCancelReason",)
		select "id=reason", "label=CANCELLATION - DOCTOR'S ORDER" if is_element_present("id=reason",)
		#type("id=txtRemarks", "selenium remarks")  if is_element_present("id=txtRemarks",)
		type "id=remarks", "asdas"  if is_element_present("id=remarks",)
		#click "id=btnUpdate"  if is_element_present("id=btnUpdate",)
		#click("//input[@type='button' and @onclick='saveOrderCancelForm();' and @value='OK' and @name='btnOK']")  if is_element_present("//input[@type='button' and @onclick='saveOrderCancelForm();' and @value='OK' and @name='btnOK']")
		click "name=btnOK" if is_element_present("name=btnOK",)
		sleep 10
		puts "click update and save"
    #  self.tag_document
      is_text_present("The CM was successfully updated with printTag = 'Y'.")
    end
  end
  def oss_click_proceed_cancel
    click("css=#verifyOrderCancel_div>center>div:nth-child(2)>input:nth-child(4)")
    #click "xpath=(//input[@value='Proceed'])[2]"

    sleep 5
    select("reason","CANCELLATION - DOCTOR'S ORDER")
    type("remarks", "sample remark")
    click("//input[@value='OK' and @name='btnOK']", :wait_for => :page)
    sleep 3
    click("popup_ok", :wait_for => :page)
    sleep 3
    get_text("successMessages")
  end
  def pos_document_search(options={})
    select "//select[@id='documentType']", "label=#{options[:type]}"
    type "//input[@id='documentNumber' and @name='documentNumber' and @type='text']", options[:doc_no] if options[:doc_no]
    type'//input[@id="searchFromDate" and @name="startDate" and @type="text"]', options[:start_date] || Time.now.strftime("%m/%d/%Y")
    type'//input[@id="searchToDate" and @name="endDate" and @type="text"]', options[:end_date] || Time.now.strftime("%m/%d/%Y")
    search_button = is_element_present('//input[@id="action" and @value="Search" and @type="button"]') ?  '//input[@id="action" and @value="Search" and @type="button"]' :  '//input[@type="button" and @onclick="submitForm(this.value);" and @value="Search"]'
    click search_button, :wait_for => :page
    is_text_present(options[:doc_no]) || is_element_present("link=View Details")
  end
  def pos_click_view_details(options={})
    if options[:sales_invoice_number]
      click "//a[@href='/ops/posDocumentDetails.html?documentType=SI_TYPE&documentNumber=#{options[:sales_invoice_number]}']", :wait_for => :page
    elsif options[:ci_no]
      click "//a[@href='/ops/posDocumentDetails.html?ciNo=#{options[:ci_no]}']", :wait_for => :page
    end
  end
  def pos_cancel_item(options={})
    sleep 2
    click("css=#results>tbody>tr:nth-child(#{options[:order_of_item]})>td:nth-child(8)>div>a")
    sleep 3
    get_confirmation()
    choose_ok_on_next_confirmation()
    select "cancelReason", "label=#{options[:reason]}"
    type "cancelRemarks", "testRemarks" || options[:remarks] if options[:remarks]
    click "btnOK", :wait_for => :page
    click "//input[@value='Submit']", :wait_for => :page
    me = get_alert if is_alert_present
    click "popup_ok", :wait_for => :page
    return get_alert if is_alert_present
    return get_text("successMessages")
  end
  def click_reprint_button(options={})
    if options[:ci]
      click "link=Reprint CI", :wait_for => :page
    elsif options[:sales_invoice]
      click "link=Reprint OR", :wait_for => :page
    end
    click("popup_ok", :wait_for => :page) if is_element_present("popup_ok")
    is_text_present("POS Document Search")
  end
  def oss_reprint_cancellation_prooflist
    click "link=Reprint Request Slip"
    sleep 10
    is_text_present("Document Search")
  end
  def click_oss_ordering
    click "//input[@value='Oss Ordering']", :wait_for => :page
  end
  def get_document_number
    ## works on Sales Invoice
    location = get_location()
    array1 = location.split('=')
    array2 = array1[1].split('&')
    return array2[0]
  end
  def reprint_to_dlr(options={})
    select "reprintToDLR#{options[:pin]}", "label=#{options[:action]}"
    if options[:action] == "Reprint Drug Label"
      click "//option[@value='drugLabel']"
    elsif options[:action] == "Reprint Prooflist"
      click "//option[@value='prooflist']"
    end
    click "//input[@value='Submit']"
    sleep 10
    get_alert()
  end
  def oss_rvu(options ={})
    click "checkPhilhealth" if options[:philhealth]

if options[:diagnosis]
        click "id=btnDiagnosisLookup"
        sleep 3
        type "id=icd10_entity_finder_key", options[:diagnosis]
        click "css=div.searchArea > input[type=\"button\"]"
        sleep 3
        click "link=#{options[:diagnosis]}"
end
if  options[:rvu_key]
        sleep 3
        select "id=phCaseRateType", "label=SURGICAL"
        sleep 3
        click "id=btnCaseRateLookup"
        sleep 3
        type "id=rvs_entity_finder_key", options[:rvu_key]
        sleep 3
        click "css=#rvsAction > input[type=\"button\"]"
        sleep 3
        click "link=#{options[:rvu_key]}"
end

if options[:rvu_key2]
        sleep 3
        select "id=phCaseRateTypeSecond", "label=SURGICAL"
        sleep 3
        click "id=btnCaseRateLookupSecond"
        sleep 3
        type "id=rvs_entity_finder_key", options[:rvu_key2]
        sleep 3
        click "css=#rvsAction > input[type=\"button\"]"
        sleep 3
        click "link=#{options[:rvu_key2]}"
        sleep 3
end
##    click "btnRVULookup", :wait_for => :text, :text => "Search RVU"
##
##    type "rvu_entity_finder_key", options[:rvu_key]
##    click "//input[@value='Search' and @type='button' and @onclick='RVU.search();']"
##    sleep Locators::NursingGeneralUnits.waiting_time
##    click "//tbody[@id='rvu_finder_table_body']/tr/td[2]/div"
##    sleep 2

    return true
  end
  def validate_existing_order(options ={})
    if options[:open_edit]
      click "updact4"
      click "//input[@value='Proceed']", :wait_for => :not_visible, :element => "verifyItemAction"
      type "quantity", options[:quantity]
      click "editOrder"
      sleep 5
      times_two = get_text("ops_order_quantity_0")
      return times_two
    elsif options[:new_line]
      click "updact3"
      click "//input[@value='Proceed']",:wait_for => :not_visible, :element => "verifyItemAction"
      sleep 3
      is_element_present "ops_order_chk_0"
    elsif options[:override]
      click "updact2"
      click "//input[@value='Proceed']",:wait_for => :not_visible, :element => "verifyItemAction"
      sleep 3
      times_two = get_text("ops_order_quantity_0")
      return times_two
    elsif options[:update_quantity]
      click "updact1"
      click "//input[@value='Proceed']",:wait_for => :not_visible, :element => "verifyItemAction"
      sleep 3
      times_two = get_text("ops_order_quantity_0")
      return times_two
    end
  end
  def oss_advanced_search(options={})
    search_value = is_element_present("criteria") ?  ("criteria") :  ("param")
    type search_value, options[:pin] || options[:lastname]  || "DOMOGAN"
    click'slide-fade'
    type'fName',options[:firstname] || "JOY ALLISON"
    type'mName',options[:middlename] || "N"
    type'bDate',options[:bday] if options[:bday]
    search_button = is_element_present('//input[@type="submit" and @value="Search"]') ? '//input[@type="submit" and @value="Search"]' : '//input[@type="button" and @value="Search" and @onclick="submitPSearchForm(this);"]'
    click search_button, :wait_for=>:page
  end
  def oss_verify_orders(options={})
    count = get_css_count("css=#discountDetails>tr")

    x = 0
    w = []
    count.times do
      amount = get_text("//*[@id=\"discountNetAmountDisplay-#{x}\"]").gsub(',','').to_f
      discount = (amount * options[:discount] / 100.0).to_f
      w << (("%0.2f" %(discount)).to_f == get_text("//*[@id=\"discountAdditionalDiscountDisplay-#{x}\"]").gsub(',','').to_f)
      x += 1
    end

    x = 0
    count.times do
      return false if w[x] != true
      x += 1
    end
    return false if w.include?(false)
    return true
  end
  def pos_patient_toggle(options={})
    click'patientToggle'
    sleep 2
    click'findPatient', :wait_for => :element, :element => "css=#patient_finder_table_body"
    type'patient_entity_finder_key',options[:pin]
    click'//input[@type="button" and @onclick="PF.search();" and @value="Search"]', :wait_for => :element, :element => "css=#patient_finder_table_body>tr.even>td>a"
    click'css=#patient_finder_table_body>tr.even>td>a'
  end
  def oss_order_amount_per_item
    order_table=get_css_count("css=#tableRows>tr")
    order_amount=0.0
    rows = 0
    order_table.times do
      order_amount = ((get_text("ops_order_amount_#{rows}").gsub(',','').to_f) + order_amount)
      sleep 1
      rows = rows+1
      order_table = order_table-1
    end
    return order_amount
  end
  def oss_promo_amount(options={})
    order_table=get_css_count("css=#tableRows>tr")
    rows = 0
    @w = []
    order_table.times do
      amount = (get_text("ops_order_amount_#{rows}").gsub(',','').to_f)
      promo_discount = amount * options[:promo]
      @w << (("%0.2f" %(promo_discount)).to_f == (get_text("ops_order_promo_discount_#{rows}").gsub(',','').to_f))
      rows = rows+1
    end

     if @w.include?(false)
       return false
     else return true
     end
  end
  def oss_net_of_promo(options={})
       sleep 6
    order_table=get_css_count("css=#tableRows>tr")
    rows = 0
    @w = []
    order_table.times do
      amount = (get_text("ops_order_amount_#{rows}").gsub(',','').to_f)
      #puts "amount = #{amount}"
      promo_amount = (get_text("ops_order_promo_discount_#{rows}").gsub(',','').to_f)
      total_amount = amount - promo_amount
      class_discount = (total_amount * options[:class_discount]) + 0.01
      puts "class_discount = #{class_discount}"
#      @w << (("%0.2f" %(class_discount)).to_f == (get_text("ops_order_discount_#{rows}").gsub(',','').to_f))
  puts "from page #{get_text("ops_order_discount_#{rows}").gsub(',','').to_f}"

    @w << (((truncate_to((class_discount.to_f -  (get_text("ops_order_discount_#{rows}").gsub(',','').to_f)),2).to_f).abs) <= 0.02)
      rows = rows+1
      puts @w
    end

     if @w.include?(false)
       return false
     else return true
     end
  end
  def oss_discount_table(options={})
    if options[:percent]
      discount_table = get_css_count("css=#discountDetails>tr")
      rows = 0
      @w = []
      discount_table.times do
        amount = (get_text("discountNetAmountDisplay-#{rows}").gsub(',','').to_f)
        discount_amount = amount * options[:percent]
        @w << (("%0.2f" %(discount_amount)).to_f == (get_text("discountAdditionalDiscountDisplay-#{rows}").gsub(',','').to_f))
  #    @w << (((truncate_to((discount_amount.to_f -  (get_text("discountAdditionalDiscountDisplay-#{rows}").gsub(',','').to_f)),2).to_f).abs) <= 0.01)
        rows = rows+1
      end

       if @w.include?(false)
         return false
       else return true
       end
    else
      discount_table = get_css_count("css=#discountDetails>tr")
      amount = 0.0
      rows = 0
      discount_table.times do
        amount = ((get_text("discountAdditionalDiscountDisplay-#{rows}").gsub(',','').to_f) + amount)
        rows = rows+1
        discount_table -= discount_table
      end
      return amount
    end
  end
  def oss_billing_details
    tna = get_billing_total_net_amount
    da = get_billing_discount_amount
    nad = get_billing_net_after_discount_amount
    tca = get_billing_total_charge_amount
    tad = get_billing_total_amount_due
    tbp = get_billing_total_payments
    bd = get_billing_balance_due_amount
    return {
      :total_net_amount => tna,
      :discount_amount => da,
      :net_after_discount => nad,
      :total_charge_amount => tca,
      :total_amount_due => tad,
      :total_billing_payment => tbp,
      :balance_due => bd
    }
end
  def click_button_on_outpatient_registration(options={})
    if options[:back]
      click'//input[@type="button" and @onclick="submitForm(this);" and @value="Back"]'
       is_text_present"PIN/Patient's Last Name"
    elsif options[:order_page]
      click'//input[@type="button" and @onclick="submitForm(this);" and @value="Order Page"]'
      is_text_present"Patient Information"
    elsif options[:print_data_sheet]
      click'//input[@type="button" and @onclick="submitForm(this);" and @value="Print Out Patient Info Sheet"]'
      is_text_present"One Stop Shop"
    end
  end
  def click_add_reference(options={})
    type"phPatientInfoBean.pin",options[:pin] if options[:pin]
    type"referenceDocument",options[:reference_no] if options[:reference_no]
    click"isCi" if options[:ci]
    sleep 1
    click"addOrCi"
    sleep 1
    if options[:alert]
    return get_alert
    else
      sleep 20 #multiple or/ci loads slow
     return (get_text"css=#orCiRows>tr>td") == options[:reference_no]
    end
  end
  def ph_multiple_session(options={})
    diagnosis = options[:diagnosis] || "CHOLERA"
    click "btnDiagnosisLookup"#, :wait_for => :element, :element => "icd10_entity_finder_key"
    sleep 3
    type "icd10_entity_finder_key", diagnosis if options[:diagnosis]
    click "//input[@value='Search' and @type='button' and @onclick='Icd10Finder.search();']"
    sleep Locators::NursingGeneralUnits.waiting_time
    click "link=#{diagnosis}"
    sleep 2
    select "medicalCaseType", options[:case_type] if options[:case_type]
    select"id=phCaseRateType", options[:case_rate_type] if options[:case_rate_type]
    sleep 2 if options[:case_rate_type]
    #ORIGINAL CODE LINE
    #select"caseRateNo", options[:case_rate] if options[:case_rate]
   #DEBUGGING - JUDE
   # type"caseRate", case_rates if options[:case_rate]
   case_rate= options[:case_rate]
   click "id=btnCaseRateLookup", wait_for => :findElement, :findElement => "id=rvs_entity_finder_key"
   sleep 6
    type  "id=rvs_entity_finder_key", case_rate

        sleep 6
   #click "//input[@value='Search' and @type='button' and @onclick='CaseRateFinder.searchRvs();']]"
    click "css=#rvsAction > input[type=\"button\"]"
            sleep 6
    #sleep Locators::NursingGeneralUnits.waiting_time
    click "link=#{options[:case_rate_name]}" if is_element_present("link=#{options[:case_rate_name]}")
    sleep 6

     if options[:session]
        type"orCiRecords[0].orderDetailPhBean[#{options[:session]}].sessionDate",Time.now.strftime("%m/%d/%Y")
     elsif options[:all_session]
        count = get_css_count"css=#orderDetailRows>tr"
        rows = 0
        count.times do
        type"orCiRecords[0].orderDetailPhBean[#{rows}].sessionDate",Time.now.strftime("%m/%d/%Y")
        count+=1
        rows+=1
        end
     end
    sleep 2
    type"phPatientInfoBean.memberInfo.membershipID","123456789"
    type"phPatientInfoBean.memberInfo.memberAddress","Address"
    type "phPatientInfoBean.memberInfo.memberCity", "City"
    type "phPatientInfoBean.memberInfo.memberProvince", "Province"
    select "phPatientInfoBean.memberInfo.memberCountry", "label=PHILIPPINES"
    sleep 4

    if is_checked("id=1stCaseDoctor-0") == false
           click "id=1stCaseDoctor-0"
    end
    
    click"btnCompute", :wait_for => :page if options[:compute]
    click"btnSave", :wait_for => :page if options[:save]

    sleep 5
      arbc = (get_text"css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr.even>td:nth-child(2)")
      arbb = (get_text"css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr.even>td:nth-child(3)").gsub(",","")
      aoc = (get_text"css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(2)>td:nth-child(2)").gsub(",","")
      aobc =(get_text"css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(2)>td:nth-child(3)").gsub(",","")
      tac = (get_text"css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(3)>td:nth-child(2)").gsub(",","")
      tabc = (get_text"css=#benefitSummarySection>div:nth-child(2)>div>table>tbody>tr:nth-child(3)>td:nth-child(3)").gsub(",","")

      return {
        :actual_rb_availed_charges => arbc,
        :actual_rb_availed_benefit_claim => arbb,
        :actual_operation_charges => aoc,
        :actual_operation_benefit_claim => aobc,
        :total_actual_charges => tac,
        :total_actual_benefit_claim => tabc
       }

  end

end

