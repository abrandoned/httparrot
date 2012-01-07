ResponseFactory.define(:base_ofx) do |ofx|
end 

ResponseFactory.define(:base_ofx_transaction) do |tran|
  tran.parent(:base_ofx)
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
