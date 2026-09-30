local Config=require(script.Parent.Definitions.CollectionProgressionDefinitions).Streak
local M={}
function M.Bonus(count)
 local bonus=0;for _,tier in ipairs(Config.Tiers)do if count>=tier.Searches then bonus=tier.Bonus end end;return bonus
end
function M.Current(state,now)
 if not state or now-(state.LastSuccess or 0)>=Config.IdleSeconds then return 0,0 end
 return state.Count,M.Bonus(state.Count)
end
function M.Commit(state,now)
 local count=M.Current(state,now)
 return {Count=count+1,LastSuccess=now}
end
return M
