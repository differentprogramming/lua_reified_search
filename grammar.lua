Search=require 'search'

local 	save_undo= Search.save_undo
local 	alt= Search.alt
local 	fail= Search.fail
local 	snip_start= Search.snip_start
local 	snip= Search.snip
local 	new_amblist= Search.new_amblist
local 	Uninstanciated= Search.Uninstanciated
local 	Dot= Search.Dot
local 	Null= Search.Null
local 	class_of= Search.class_of
local 	is_logical= Search.is_logical
local 	logical_get= Search.logical_get
local 	ground= Search.ground
local 	unify= Search.unify
local 	nullp= Search.nullp
local 	listp= Search.listp
local 	pairp= Search.pairp
local 	Cons= Search.Cons
local 	car= Search.car
local 	cdr= Search.cdr
local 	list= Search.list
local 	LV= Search.LV
local 	new_search= Search.new_search
local   identical= Search.identical
local   LVars=Search.LVars

--[[
 sentence(A,B,s(NP,VP)) :- noun_phrase(A,C,NP), verb_phrase(C,B,VP).
 noun_phrase(A,B,np(D,N)) :- det(A,C,D), noun(C,B,N).
 verb_phrase(A,B,vp(V,NP)):- verb(A,C,V), noun_phrase(C,B,NP).
 det([the|O],O,d(the)).
 det([a|O],O,d(a)).
 noun([bat|O],O,n(bat)).
 noun([cat|O],O,n(cat)).
 verb([eats|O],O,v(eats)).
 ]]


local noun_phrase

-- verb([eats|O],O,v(eats)).
-- verb([plays with|O],O,v(eats)).
local function verb(c,search,X,Y,Z)
  local O = LV()
  local function rest()
    return unify(c,search,{X,Y,Z},{{'plays','with',Dot,O},O,{'v','plays','with'}})
  end
  alt(search,rest)
  return unify(c,search,{X,Y,Z},{{'eats',Dot,O},O,{'v','eats'}})
  
end

-- noun([bat|O],O,n(bat)).
-- noun([cat|O],O,n(cat)).

local function noun(c,search,X,Y,Z)
  local O = LV()
  local function rest()
    return unify(c,search,{X,Y,Z},{{'cat',Dot,O},O,{'n','cat'}})
  end
  alt(search,rest)
  return unify(c,search,{X,Y,Z},{{'bat',Dot,O},O,{'n','bat'}})
  
end

-- det([the|O],O,d(the)).
-- det([a|O],O,d(a)).
local function det(c,search,X,Y,Z)
  local O = LV()
  local function rest()
    return unify(c,search,{X,Y,Z},{{'a',Dot,O},O,{'d','a'}})
  end
  alt(search,rest)
  return unify(c,search,{X,Y,Z},{{'the',Dot,O},O,{'d','the'}})  
end

-- verb_phrase(A,B,vp(V,NP)):- verb(A,C,V), noun_phrase(C,B,NP).
local function verb_phrase(c,search,X,Y,Z)
  local A,B,V,NP,C=LVars(5)
  local function rest()
    local function rest2()
      return noun_phrase(c,search,C,B,NP)
    end
    return verb(rest2,search,A,C,V)
  end
  return unify(rest,search,{X,Y,Z},{A,B,{'vp',V,NP,N}})
end

-- noun_phrase(A,B,np(D,N)) :- det(A,C,D), noun(C,B,N).
noun_phrase= function (c,search,X,Y,Z)
  local A,B,D,N,C=LVars(5)
  local function rest()
    local function rest2()
      return noun(c,search,C,B,N)
    end
    return det(rest2,search,A,C,D)
  end
  return unify(rest,search,{X,Y,Z},{A,B,{'np',D,N}})
end

-- sentence(A,B,s(NP,VP)) :- noun_phrase(A,C,NP), verb_phrase(C,B,VP).
local function sentence (c,search,X,Y,Z)
  local A,B,NP,VP,C=LVars(5)
  local function rest()
    local function rest2()
      return verb_phrase(c,search,C,B,VP)
    end
    return noun_phrase(rest2,search,A,C,NP)
  end
  return unify(rest,search,{X,Y,Z},{A,B,{'s',NP,VP}})
end

local X,Y,Z=LVars(3)

function rest1(search)
  print('parse =',X,Y,Z)
  return not search.failed
end


local search = new_search(sentence,rest1,X,Y,Z)

--local search = new_search(unify,rest1,list{'cat',Dot,'dog'},list{X,Dot,Y})

repeat
  l = search()
 --  print (N,M)
until not l
search:reset()
repeat
  l = search()
 --  print (N,M) 
until not l