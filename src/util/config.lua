local function loadFile(path)
  local result = {}

  local pname, pvalue, partial
  for line in io.lines(path) do
    if not partial then
      pname, pvalue, partial = line:match("^%s*(.+)%s*:%s*(.+)%s*(\\?)$")
      if partial == "" and pvalue == '"""' then
        pvalue = ""
        partial = 2
      elseif partial ~= "" then
        partial = 1
      end
    else
      if partial == 1 then
        local prevValue = pvalue
        pvalue, partial = line:match("^%s*(.+)%s*(\\?)$")
        if partial then
          partial = 1
        end
        pvalue = prevValue .. " " .. pvalue
      elseif partial == 2 then
        if line == '"""' then
          partial = nil
        else
          pvalue = pvalue .. "\n" .. line
        end
      end
    end
    if partial == "" then
      partial = nil
    end
    if not partial then
      result[pname:lower()] = pvalue
      pname, pvalue, partial = nil, nil, nil
    end
  end
  return result
end

return {
  loadFile = loadFile
}
