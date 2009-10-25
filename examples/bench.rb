BareBench.suite :iterations => 100000 do
  bench "String#gsub" do
    "hello world".gsub(/l/, '')
  end

  bench "String#tr" do
    "hello world".tr('l', '')
  end

  bench "String#delete" do
    "hello world".delete('l')
  end
end
