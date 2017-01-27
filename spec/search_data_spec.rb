#require File.dirname(__FILE__) + '/../lib/slmc'
require File.expand_path(File.dirname(__FILE__)) + '/../lib/slmc.rb'
require 'spec_helper'
require 'yaml'


describe "SLMC :: View and Reprinting - PBA Search Parameter" do

  attr_reader :selenium_driver
  alias :slmc :selenium_driver

  before(:all) do
#    @selenium_driver = SLMC.new
#    @selenium_driver.start_new_browser_session
#    @patient = Admission.generate_data
#    @password = "123qweuser"
#    @user = "gu_spec_user6"
#
#    @drugs =  {"049000028" => 1}
#    @ancillary = {"010001636" => 1}
#    @operation = {"060000204" => 1}
#
#    @user_actions = ["Reprint PhilHealth Form", "Reprint Prooflist", "Display Details"]
@@my_search = "feature"
  end

  after(:all) do
#    slmc.logout
#    slmc.close_current_browser_session
  end

it "Search Data To Database" do
        mysearch = 'DT024'
     #   ww =[]
        q = "SELECT TABLE_NAME FROM ALL_TABLES WHERE OWNER = 'SLMC' and TABLE_NAME LIKE 'REF%'"
        Database.connect
        ww = Database.select_all_rows(q)
        Database.logoff
        mtable_count = ww.count
        table_count  = mtable_count - 1
        while table_count != -1
                  current_table = ww[table_count]
                  bb = "SELECT COLUMN_NAME FROM all_tab_columns WHERE OWNER = 'SLMC' AND TABLE_NAME = '#{current_table}'"
                  cc =[]
                  Database.connect
                  cc = Database.select_all_rows(bb)
                  Database.logoff
                  mcolunm_count = cc.count
                  colunm_count = mcolunm_count - 1
                  while colunm_count != -1
                        current_colunm = cc[colunm_count]
                        vv = "SELECT COUNT(#{current_colunm}) FROM #{current_table} WHERE UPPER(#{current_colunm}) like '%#{mysearch}%'"
                        Database.connect
                        dd = Database.select_last_statement(vv)
                        Database.logoff
                        dd = dd.to_i
                   #   puts "dd - #{dd}"
                        if dd != 0
                              puts "#{current_table}  #{dd}"
                        end
                        colunm_count -=1
                  end
                  table_count -= 1
        end
end

#it "Search Rspec" do
##        wd = Dir.pwd
##         Dir.chdir(wd + '/spec')
##  spec_files =  Dir.glob("C:\Users\sandy\Desktop\newfolder\stluke\167\spec\*_spec.rb")
##  spec_names = []
##  spec_files.length.times do |x|
##    spec_names << spec_files[x].split('_spec.rb')
##  end
##  spec_names.flatten!
##  spec_names.length.times do |x|
##    puts "#{spec_names[x]}","#{spec_files[x]}"
##  end
#spec_files = Dir.glob("spec/*_spec.rb")
##puts spec_files
#  spec_names = []
#  spec_files.length.times do |x|
#    spec_names << spec_files[x].split('_spec.rb')
#
#  end
#  spec_names.flatten!
#  spec_names.length.times do |x|
#   # puts "#{spec_names[x]}","#{spec_files[x]}"
#    
#    if spec_files[x].include? @@my_search
#                puts spec_files[x]
#   end
#  end
#
#end
end

