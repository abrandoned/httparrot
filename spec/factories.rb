require 'date'
require 'securerandom'
require File.expand_path('../response_factory', __FILE__)

ResponseFactory.define(:base_ofx) do |ofx|
  # header fields
  ofx.ofx_header = "100"
  ofx.data = "OFXSGML"
  ofx.old_file_uid = "NONE"
  ofx.new_file_uid = "NONE"
  ofx.compression = "NONE"
  ofx.security = "NONE"
  ofx.encoding = "USASCII"
  ofx.charset = "1252"
  ofx.language = "ENG"
  ofx.security = "NONE"

  # data type fields
  ofx.tz = "MDT"
  ofx.date_format = "%Y%m%d%H%M%S"
  ofx.float_format = "%.2f"
  ofx.curdef = "USD"

  ofx.org = "MD Bank1"
  ofx.fid = "#{rand(1_000_000_000)}"

  ofx.userkey = "UserKey"
  ofx.appid = "QWIN"
  ofx.appver = "1800"
  ofx.trnuid = SecureRandom.hex(16) 
  ofx.bankid = rand(1_000_000_000)
  ofx.acctid = "#{rand(1_000_000_000)}-#{rand(3_000)}" 
  ofx.accttype = ResponseFactory.one_of(["CREDITLINE", "SAVINGS", "CHECKING"])
  ofx.dtstart = (Time.now - 90.days).to_datetime.strftime(ofx.date_format)
  ofx.dtend = DateTime.now.strftime(ofx.date_format)
  ofx.include = "Y"
  ofx.balamt = ofx.float_format % (rand(1000.0)/7)
  ofx.dtasof = DateTime.now.strftime(ofx.date_format)
  ofx.dtacctup = DateTime.now.strftime(ofx.date_format)
  ofx.desc = "Account/Bank Description : #{rand(1_000)}"

  ofx.suptxdl = "Y"
  ofx.xfersrc = "N"
  ofx.xferdest = "N"
  ofx.svcstatus = ResponseFactory.one_of(["ACTIVE", "PEND", "AVAIL"])

  ofx.code = "0"
  ofx.severity = "INFO"
  ofx.message = "Success"
  ofx.dtserver = DateTime.now.strftime(ofx.date_format + ".%L[%z:#{ofx.tz}]")
end 

ResponseFactory.define(:base_ofx_transaction) do |tran|
  tran.parent(:base_ofx)

  tran.trntype = ResponseFactory.one_of(["DEBIT", "CREDIT"])
  tran.dtposted = DateTime.now.strftime(tran.date_format + ".%L[%z:#{tran.tz}]")
  tran.dtavail = DateTime.now.strftime(tran.date_format + ".%L[%z:#{tran.tz}]")
  tran.trnamt = tran.float_format % (tran.trntype == "DEBIT" ? (rand(1000.0)/7) * -1 : (rand(1000.0)/7)) 
  tran.fitid = SecureRandom.hex(24)
  tran.name = "Test Transaction description #{rand(1_000_000_000)}"
  tran.memo = "Memos are the best #{rand(1_000_000)}"
end

ResponseFactory.define(:base_ofx_statement) do |tran|
  tran.parent(:base_ofx)
  tran.transactions = ResponseFactory.collection_of(:base_ofx_transaction, 10)
end

ResponseFactory.define(:cmc_statement) do |stat|
  stat.parent(:base_ofx_statement)
  stat.template_file = "templates/cmc_statement_list.erb"
end

ResponseFactory.define(:base_ofx_account) do |acct|
  acct.parent(:base_ofx)
end

ResponseFactory.define(:ofx_bank_statement) do |tran|
  tran.parent(:base_ofx_statement)

  tran.trntype = ResponseFactory.one_of(["DIV", "DEBIT"])
end

ResponseFactory.define(:base_ofx1) do |ofx|
  ofx.parent(:base_ofx) 

  ofx.ofx_header = "100"
  ofx.data = "OFXSGML"
end

ResponseFactory.define(:base_ofx2) do |ofx|
  ofx.parent(:base_ofx)
end

ResponseFactory.define(:base_mdx) do |ofx|
end

ResponseFactory.define(:home_cu_ofx) do |ofx|
end

ResponseFactory.define(:cmc_ofx_accounts_list) do |ofx|
  ofx.parent(:base_ofx)
  ofx.template_file = "templates/cmc_accounts_list.erb"
  ofx.accounts = [ResponseFactory.build(:base_ofx)]

  ofx.version = "102"
end

ResponseFactory.define(:cmc_ofx_multi_accounts_list) do |ofx|
  ofx.parent(:base_ofx)
  ofx.template_file = "templates/cmc_accounts_list.erb"
  ofx.accounts = [ResponseFactory.build(:base_ofx), ResponseFactory.build(:base_ofx), ResponseFactory.build(:base_ofx)]

  ofx.version = "102"
end

ResponseFactory.define(:macu_ofx) do |ofx|
end
