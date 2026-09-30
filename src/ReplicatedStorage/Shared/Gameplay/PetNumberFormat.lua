local M={}
local locale='en-us'
pcall(function()locale=game:GetService('LocalizationService').RobloxLocaleId:lower()end)
function M.Number(value,decimals)
 value=tonumber(value)or 0;if value~=value or math.abs(value)==math.huge then value=0 end
 local raw=string.format('%.'..(decimals or 0)..'f',value)
 local whole,fraction=raw:match('^([^%.]+)%.?(.*)$')
 local language=locale:sub(1,2)
 local comma=({de=true,fr=true,es=true,it=true,pt=true,ru=true,nl=true,pl=true,tr=true})[language]
 local grouping=language=='fr' or language=='ru' or language=='pl'
 local group=grouping and ' ' or comma and '.' or ','
 whole=whole:reverse():gsub('(%d%d%d)','%1'..group):reverse():gsub('^%'..group,'')
 return whole..(fraction~='' and ((comma and ',' or '.')..fraction) or '')
end
function M.Weight(value)return M.Number(value,(value or 0)<100 and 1 or 0)..' kg'end
function M.Income(value)return '+'..M.Number(value,1)..'/sec'end
return M
