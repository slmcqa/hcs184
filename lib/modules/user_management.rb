#!/bin/env ruby
# encoding: utf-8
module UserManagement

  def add_new_user_with_roles(options = {})
    all_roles = options[:all_roles] || false
    osf_key = options[:osf_key].to_s
    roles = options[:roles]
    go_to_healthcare_pages
    click "//input[@value='Add']",  :wait_for => :page
    if all_roles == true || roles.length > 1
      user = options[:user] || osf_key + "_test_user_" + rand(1000).to_s
    else
      if roles.class == Array
        role = roles[0].split('ROLE_')[1]
      elsif roles.class == String
        role = roles.split('ROLE_')[1]
      end
      user = options[:user] ||  osf_key + "_" + role.downcase # + "_" + rand(1000).to_s
    end
    self.populate_add_new_user_page_fields(user, osf_key)
    if all_roles == true
      self.remove_all_roles
      self.set_all_roles
      click Locators::FileMaintenance.update_button
    else
      if roles.class == Array
        self.remove_all_roles
        roles.each do |r|
          self.add_role(r)
        end
        click Locators::FileMaintenance.update_button
      else
        self.add_role(roles)
        click Locators::FileMaintenance.update_button
      end
    end
    sleep 1
    click "btnUserSubmit", :wait_for => :page
    return user
  end
  def add_role(role)
    click("selectRole", :wait_for => :visible, :element => "roleDialog") if !is_visible("roleDialog")
    add_selection "selAvailableRoles", "label=#{role}"
    click "btnMoveRight"
  end
  def set_all_roles
    roles = UserManagement.user_roles
    roles.each do |r|
      add_selection "selAvailableRoles", "label=#{r}"
    end
    click "btnMoveRight"
  end
  def edit_spec_roles(options={})
    all_roles = options[:all_roles]
    go_to_healthcare_pages
    user_search(options[:user])
    click("link=#{options[:user]}", :wait_for => :page)
    if options[:all_roles]
      self.remove_all_roles
      all_roles.each do |r|
        add_selection "selAvailableRoles", "label=#{r}"
      end
      click "btnMoveRight"
      click Locators::FileMaintenance.update_button
    end
    click("btnUserSubmit", :wait_for => :page)
  end
  def edit_roles(user, key)
    edit_spec_roles(:user => user, :all_roles => UserManagement.user_roles, :osf_key => key)
    puts "Successfully edited roles of #{user}"
  end
  def remove_all_roles
    count = get_css_count("css=#selCurrentRoles>option")
    c = []
    x = 1
    count.times do
      c << get_text("css=#selCurrentRoles>option:nth-child(#{x})")
      x += 1
    end
    c.each do |r|
      add_selection "selCurrentRoles", "label=#{r}"
    end
    click "btnMoveLeft"
  end
  def remove_roles
    roles = ['ROLE_CSS_CASHIER', 'ROLE_PHARMACY_CASHIER', 'ROLE_DAS_ONESTOP_SHOP', 'ROLE_USER']
    roles.each do |r|
      add_selection "selCurrentRoles", "label=#{r}"
      click "btnMoveLeft"
    end
  end
  def delete_user(user)
    go_to_healthcare_pages
    user_search(user)
    click("link=#{user}", :wait_for => :page)
    click("btnUserDelete", :wait_for => :element, :element => "//div[11]/div/button[2]")
    click("//div[11]/div/button[2]", :wait_for => :page)
    user_search(user)
    get_text("//table[@id='users']/tbody/tr/td") == "Nothing found to display."
  end
  def populate_add_new_user_page_fields(user, osf_key)
    type "username", user
    type "password", "123qweuser"
    type "confirmPassword", "123qweuser"
    type "passwordHint", "please dont change - selenium team"
    type "email", "#{user}@slmc.com"
    click "radioEmployee"
    click "//img[@alt='Search']", :wait_for => :element, :element => "employee_entity_finder_key"
    sleep 1
    type("employee_entity_finder_key", "0002733")
    click "//input[@value='Search' and @type='button' and @onclick='EF.search();']", :wait_for => :element, :element => "link=0002733"
    sleep 3
    click "link=0002733"
    sleep 1
    click "//a[@id='orgCodeFind']/img", :wait_for => :element, :element => "osf_entity_finder_key"
    type "osf_entity_finder_key", osf_key
    click "//input[@value='Search' and @type='button' and @onclick='OSF.search();']", :wait_for => :element,
      :element => "link=#{osf_key}"
    click "link=#{osf_key}"
    sleep 5
    click "accountEnabled" if !(is_checked("accountEnabled"))
  end
  def self.user_roles
    [
      'ROLE_ADMISSION_CLERK',
      'ROLE_ANCILLARY_FNB',
      'ROLE_NURSING_ADJUSTMENT_ANCILLARY',
      'ROLE_NURSING_ADJUSTMENT_OTHERS',
      'ROLE_NURSING_ADJUSTMENT_PHARMACY',
      'ROLE_NURSING_GENERAL_UNITS',
      'ROLE_NURSING_VALIDATE',
      'ROLE_PACKAGE_ADJUSTMENT',
      'ROLE_RPT_OM_DIET_LISTING',
      'ROLE_RPT_OM_NURSING_ENDORSEMENT',
      'ROLE_RPT_OM_TWENTY_FOUR_HOUR_MEDICINE',
      'ROLE_RPT_OM_PATIENT_ASSIGNMENT',
      'ROLE_RPT_USER',
      'ROLE_SPECIAL_ORDERS',
    ]
  end
  def verify_availability_of_roles
    get_select_options("selAvailableRoles")
    get_select_options("selCurrentRoles")
  end
  def add_landing_page(options ={})
    click "//input[@value='Add']", :wait_for => :page
    type "displayLabel", options[:display_label] if options[:display_label]
    type "description", options[:url_description] if options[:url_description]
    type "//input[@id='description' and @name='description']", options[:description] if options[:description]
    click "save", :wait_for => :page if options[:add]
  end
  def add_user(options ={})
    click "//input[@value='Add']", :wait_for => :page
    type "username", options[:user_name]
    type "password", options[:password]
    type "confirmPassword", options[:confirm_password]
    type "email", options[:email] || ""
    click "typeFind", :wait_for => :visible, :element => 'doctorFinderForm'
    doctor_code = '0126'
    type "entity_finder_key", doctor_code
    doctor_row_locator = "css=td>div:contains('#{doctor_code}')"
    click "//input[@value='Search']", :wait_for => :element, :element => doctor_row_locator
    click doctor_row_locator, :wait_for => :not_visible, :element => 'doctorFinderForm'
    click "radioDoctor"
    click "//a[@id='orgCodeFind']/img"
    click "//input[@value='Search' and @type='button' and @onclick='OSF.search();']",
          :wait_for => :element,
          :element => "link=OFFICE OF THE PRESIDENT"
    click "link=OFFICE OF THE PRESIDENT", :wait_for => :not_visible, :element => 'orgStructureFinderForm'
    click "accountEnabled" if options[:acct_enabled]
    click "accountExpired" if options[:acct_expired]
    click "accountLocked" if options[:acct_locked]
    click "credentialsExpired" if options[:password_expired]
    click "btnUserSubmit", :wait_for => :page if options[:add]
    return get_text("errorMessages") if is_element_present("errorMessages")

  end
  def add_new_role(options ={})
    click "//input[@value='Add']", :wait_for => :page
    type "name", options[:name]
    type "description", options[:description]
    select "landingPage", options[:landing_page]
    add_selection "selAvailableUsers", "label=#{options[:user]}"
    click "btnMoveRight"
    click "save", :wait_for => :page
    sleep 5
    is_text_present("Role #{options[:name]} has been added successfully.")
  end
  def edit_role(options={})
    type("criteria", options[:name])
    click("//input[@type='submit' and @value='Search']", :wait_for => :page)
    click("link=Last »") if is_element_present("link=Last »")
    sleep 5
    if is_text_present("#{options[:name]}")
    else
      while !is_text_present("#{options[:name]}")
        click("link=‹ Prev")
        sleep 5
      end
    end
    count = get_css_count("css=#role>tbody>tr")
    count.times do |rows|
      my_row = get_text("css=#role>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)")
      if my_row == options[:name]
        stop_row = rows
        click("css=#role>tbody>tr:nth-child(#{stop_row + 1})>td:nth-child(2)")
        sleep 10
        break
      end
    end
    type "name", options[:name]
    type "description", options[:description] if options[:description]
    select "landingPage", options[:landing_page] if options[:landing_page]
    add_selection "selAvailableUsers", "label=#{options[:user]}" if options[:user]
    click "btnMoveRight" if options[:user]
    click "save", :wait_for => :page
    is_text_present("Role #{options[:name]} has been updated successfully.")
  end
  def delete_role(options={})
    type("criteria", options[:name])
    click("//input[@type='submit' and @value='Search']", :wait_for => :page)
    click("link=Last »") if is_element_present("link=Last »")
    sleep 5
    if is_text_present("#{options[:name]}")
    else
      while !is_text_present("#{options[:name]}")
        click("link=‹ Prev")
        sleep 5
      end
    end
    count = get_css_count("css=#role>tbody>tr")
    count.times do |rows|
      my_row = get_text("css=#role>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)")
      if my_row == options[:name]
        stop_row = rows
        click("css=#role>tbody>tr:nth-child(#{stop_row + 1})>td:nth-child(2)", :wait_for => :page)
        break
      end
    end
    if get_css_count("css=#selCurrentUsers>option") > 0
      add_selection("selCurrentUsers", "label=jglifonea")
      click("btnMoveLeft")
      click("//input[@type='submit' and @value='Save']", :wait_for => :page)
      # save first before delete as per steven.. for future reference, this should be fixed by deleting direct from page

      type("criteria", options[:name])
      click("//input[@type='submit' and @value='Search']", :wait_for => :page)
      click("link=Last »") if is_element_present("link=Last »")
      sleep 5
      if is_text_present("#{options[:name]}")
      else
        while !is_text_present("#{options[:name]}")
          click("link=‹ Prev")
          sleep 5
        end
      end
      count = get_css_count("css=#role>tbody>tr")
      count.times do |rows|
        my_row = get_text("css=#role>tbody>tr:nth-child(#{rows + 1})>td:nth-child(2)")
        if my_row == options[:name]
          stop_row = rows
          click("css=#role>tbody>tr:nth-child(#{stop_row + 1})>td:nth-child(2)", :wait_for => :page)
          break
        end
      end
    end
    choose_ok_on_next_confirmation
    click("//input[@value='Delete' and @name='delete']", :wait_for => :element, :element => "//div[11]/div/button[1]")
    click("//div[11]/div/button[2]", :wait_for => :page)
    get_confirmation() if is_confirmation_present
    is_text_present("Role #{options[:name]} has been deleted successfully.")
  end
  def add_group(options ={})
    click "//input[@type='button' and @value='Add']", :wait_for => :element, :element => "//input[@value='Save' and @name='action']"
    sleep 3
    type "name", options[:group_name] if options[:group_name]
    type "description", options[:description] if options[:description]
    click "//input[@value='Save' and @name='action']", :wait_for => :page if options[:add]
    a = is_text_present("Group #{options[:group_name]} has been added successfully.")
    b = is_text_present("View Groups › Search")
    return a && b
  end
  def edit_group(options={})
    count = get_css_count("css=#group>tbody>tr")
    count.times do |rows|
      my_row = get_text("//table[@id='group']/tbody/tr[#{rows + 1}]/td[2]")
      if my_row == options[:group_name]
        stop_row = rows
        click("//table[@id='group']/tbody/tr[#{stop_row + 1}]/td[2]", :wait_for => :page)
        break
      end
    end

    if options[:edit]
      type("name", options[:name])
      type("description", options[:description])
      add_selection("availableRoles", options[:role])
      click("btnMoveRight")
      add_selection("selAvailableUsers", options[:user])
      click("btnMoveUserRight")
      sleep 2
      click("//input[@value='Save' and @name='action']", :wait_for => :page)
      @a = is_text_present("Group #{options[:name]} has been updated successfully.")
      @b = is_text_present("View Groups › Search")
    elsif options[:delete]
      if get_css_count("css=#assignedRoles>option") > 0 || get_css_count("css=#selCurrentUsers>option") > 0
        add_selection("assignedRoles", "ROLE_ADMIN") if get_css_count("css=#assignedRoles>option") > 0
        click("btnMoveLeft") if get_css_count("css=#assignedRoles>option") > 0
        add_selection("selCurrentUsers", "label=jglifonea") if get_css_count("css=#selCurrentUsers>option") > 0
        click("btnMoveUserLeft") if get_css_count("css=#selCurrentUsers>option") > 0
        click("//input[@type='submit' and @value='Save']", :wait_for => :page)
        # save first before delete as per steven.. for future reference, this should be fixed by deleting direct from page
        count = get_css_count("css=#group>tbody>tr")
        count.times do |rows|
          my_row = get_text("//table[@id='group']/tbody/tr[#{rows + 1}]/td[2]")
          if my_row == options[:group_name]
            stop_row = rows
            click("//table[@id='group']/tbody/tr[#{stop_row + 1}]/td[2]", :wait_for => :page)
            break
          end
        end
      end
      choose_ok_on_next_confirmation
      click("//input[@value='Delete' and @name='action']", :wait_for => :element, :element => "//button[2]")
      click("//button[2]", :wait_for => :page)
      get_confirmation() if is_confirmation_present
    end
    return @a && @b if options[:edit]
    return get_text("successMessages") if options[:delete]
  end
  def delete_group(options={})

  end
  def user_search(user)
    type "criteria", user
    click "action", :wait_for => :page
    is_element_present("link=#{user}")
  end
  def user_reset_search
    click "//input[@name='action' and @value='Reset']", :wait_for => :page
  end
  def edit_master_service_aop(options ={})
    click "//img[@alt='Edit']", :wait_for => :visible, :element => "divMstAopPopup"
    select "selMstAopStat", options[:status] if options[:status]
    type "txtMstAopSvcPrep", options[:service_prep] if options[:service_prep]
    type "txtMstAopSpecType", options[:spec_type] if options[:spec_type]
    type "txtMstAopPrepTime", options[:prep_time] if options[:prep_time]
    if options[:master_services]
      click "btnMstAopMsvcFind", :wait_for => :visible, :element => "divMsvcFindPopup"
      type "txtMsvcQuery", options[:master_service]
      sleep 3
      click "btnMsvcFindSearch"
      sleep 3
      click "tdMsvcDesc-0", :wait_for => :not_visible, :element => "divMsvcFindPopup"
    end
    if options[:units_measures]
      click "btnMstAopUomFind", :wait_for => :visible, :element => "divNliFindPopup"
      type "txtNliQuery", options[:units_measure]
      sleep 3
      click "btnNliFindSearch"
      sleep 3
      click "tdNliDesc-0", :wait_for => :not_visible, :element => "divNliFindPopup"
    end
    click "btnMstAopOk", :wait_for => :page if options[:edit]
    return true if get_text("css=#results>tbody>tr>td:nth-child(2)") == options[:master_service]
  end
  def modify_user_credentials(options ={})
    go_to_healthcare_pages
    type "criteria", options[:user_name]
    click "action", :wait_for => :page
    click "link=#{options[:user_name]}", :wait_for => :page #usename link
    click "//a[@id='orgCodeFind']/img"
    type "osf_entity_finder_key", options[:org_code] #0279
    click "//input[@value='Search' and @type='button' and @onclick='OSF.search();']", :wait_for => :element, :element => "//html/body/div/div[2]/div[2]/div[2]/div[5]/div[2]/div[2]/div[2]/table/tbody/tr/td[2]/a"
    click "//html/body/div/div[2]/div[2]/div[2]/div[5]/div[2]/div[2]/div[2]/table/tbody/tr/td[2]/a" #"link=15TH FLOOR SW CARDIOVASCULAR UNIT 2"
    sleep 5
    click "btnUserSubmit", :wait_for => :page
    is_text_present("Username/User's Last Name:")
  end



end
