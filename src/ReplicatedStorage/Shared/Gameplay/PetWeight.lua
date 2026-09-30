local Config=require(script.Parent.Definitions.PetWeightDefinitions)
local M={}
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
function M.Base(def)return def and finite(def.BaseWeight) and math.max(.01,def.BaseWeight) or 5 end
function M.Maximum(def)return math.clamp(def and def.MaxWeightMultiplier or Config.MaxWeightMultiplier,1,10)end
function M.Normalize(value,def)
 local base=M.Base(def)
 return finite(value) and math.max(base,value) or base
end
function M.Ratio(pet,def)return math.max(1,M.Normalize(pet and pet.Weight,def)/M.Base(def))end
function M.Scale(pet,def)return math.clamp(M.Ratio(pet,def)^Config.ScaleExponent,1,Config.MaxVisualScale)end
function M.Quality(pet,def)
 local ratio=M.Ratio(pet,def)
 return ratio>=2.4 and 'MASSIVE!' or ratio>=1.75 and 'HUGE!' or ratio>=1.35 and 'HEAVY!' or ''
end
-- Server calls this after species selection; rng is injectable for virtual simulations.
function M.Roll(def,rng,luck,weightBias)
 local advantage=math.clamp((finite(luck) and luck or 1)-1,0,2)*.1+math.clamp(finite(weightBias) and weightBias or 0,0,.40)
 local maximum=M.Maximum(def);local total=0
 for i,band in ipairs(Config.Bands)do
  if band.Minimum<maximum then total+=band.DropWeight*(1+advantage*(i-1))end
 end
 if total==0 then return M.Base(def)end
 local draw=rng:NextNumber()*total;local selected=Config.Bands[1]
 for i,band in ipairs(Config.Bands)do
  if band.Minimum<maximum then
   draw-=band.DropWeight*(1+advantage*(i-1))
   if draw<=0 then selected=band;break end
  end
 end
 local ratio=selected.Minimum+(math.min(selected.Maximum,maximum)-selected.Minimum)*rng:NextNumber()^2
 local base=M.Base(def)
 return math.clamp(math.floor(base*ratio*100+.5)/100,base,base*maximum)
end
return M
