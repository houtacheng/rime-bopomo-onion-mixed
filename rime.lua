-- 顯示繁體候選的簡體提示，並以 Shift+Right 直接上屏簡體。
local tw_to_s = Opencc("tw2s.json")

function simplified_hint(input, env)
  for candidate in input:iter() do
    local simplified = tw_to_s:convert(candidate.text)
    local comment = candidate.comment
    if simplified ~= candidate.text then
      comment = "〔" .. simplified .. "〕"
    end
    yield(ShadowCandidate(candidate, candidate.type, candidate.text, comment))
  end
end

function simplified_commit(key, env)
  if key:repr() ~= "Shift+Right" then
    return 2
  end

  local context = env.engine.context
  if not context:has_menu() then
    return 2
  end

  local candidate = context:get_selected_candidate()
  if not candidate then
    return 2
  end

  env.engine:commit_text(tw_to_s:convert(candidate.text))
  context:clear()
  return 1
end
