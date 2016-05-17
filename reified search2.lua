local list,listp,nullp,car,cdr,pairp

local function amb_next(amb_list,n)
  assert(amb_list.class_name == 'AmbList')
    table.insert(amb_list,n)
end
local function amb(amb_list)
  assert(amb_list.class_name == 'AmbList')
  return table.remove(amb_list)()
end

local function new_amblist()
  local amb_list
  local function fail()
   amb_list.failed=true
   amb_next(amb_list,fail)
   return nil
  end
  amb_list = { class_name='AmbList',fail }
  return amb_list
end

local Unistanciated= { class_name='uninstanciated_singleton' }
local Dot = { class_name='dot_singleton' }
local Null = { class_name='Cons' }

Null[1]=Null
Null[2]=Null
setmetatable(Null,{__tostring=function() return '()' end})


local function class_of(obj)
    local c=type(obj)
    if c=='table' and obj.class_name then
        return obj.class_name 
    end
    return c
end


local function is_logical(v)
  return type(v)=='table' and v.class_name=='logical'
end



--follow the chain of logical unifications to the end, Unistanciated is a possible result
--for a logical returns the target as well (ie value,target)
--if not logical then returns original unchanged
local function logical_get(a)
  local is= is_logical(a)
  if is then
    while true do 
      if not is_logical(a.value) then 
        return a.value,a
      else
        a=a.value
      end
    end
  end
  return a
end

local function ground(n) 
  return logical_get(n)~=Unistanciated 
end



--true for equal objects, and logical variables that are unified
--tests for current equality not unifiability
--destructures with the internal routine _predicate_equal if both are predicates


local _predicate_unify

local function unify(C,search,a,b)
  if a==b then return C(search,true) end
  if listp(a) and listp(b) then 
    if not _predicate_unify(search,a,b) then return amb(search) end
    return C(search,true)
  end 
  if is_logical(b) then a,b=b,a end
  if is_logical(a) then
    local a_value,a_target = logical_get(a)
    local b_value,b_target = logical_get(b)
    if a_value==b_value then
      if a_value==Unistanciated then
        if a_target == b_target then return true end
        local restore_a = a_target.value
        a_target.value = b_target
        amb_next(search,function () a_target.value = restore_a return amb(search) end)
        return C(search,true)
      else
        return C(search,true)
      end
    elseif b_value==Unistanciated then a_value,a_target,b_value,b_target = b_value,b_target,a_value,a_target end
    if a_value==Unistanciated then
      local restore_a = a_target.value
      a_target.value = b_value
      amb_next(search,function () a_target.value = restore_a return amb(search) end)
      return C(search,true)
    end
  end
  return C(search,false)
end


--recursively destructure
--oops have to redo it so lists and dot work
_predicate_unify=function(search,a,b)
  local function null_amb() return amb(search) end
  if a==b then return true end
  if is_logical(b) then a,b=b,a end
  if is_logical(a) then
    local a_value,a_target = logical_get(a)
    local b_value,b_target = logical_get(b)
    if a_value==b_value then
      if a_value==Unistanciated then
        if a_target == b_target then return true end
        local restore_a = a_target.value
        a_target.value = b_target
        amb_next(search,function () a_target.value = restore_a return amb(search) end)
        return true
      else
        return true
      end
    elseif b_value==Unistanciated then a_value,a_target,b_value,b_target = b_value,b_target,a_value,a_target end
    if a_value==Unistanciated then
      local restore_a = a_target.value
      a_target.value = b_value
      amb_next(search,function () a_target.value = restore_a return amb(search) end)
      return true
    end
  end
  
  
  if class_of(a)=='table' then a=list(a) end
  if class_of(b)=='table' then b=list(b) end
  
  if pairp(a) and pairp(b) then
    if not _predicate_unify(search,car(a),car(b)) then return false end
    return _predicate_unify(search,cdr(a),cdr(b))    
  end
  return false  
end


nullp=function (l) return l==Null end

listp =function (n) 
    return 'Cons' ==  class_of(n)
end
pairp=function (n)
    return (not nullp(n)) and listp(n)
end

local Cons = { class_name='Cons'   }

function Cons:rest_tostring()
        if (nullp(logical_get(self[2]))) then return ' ' .. tostring(logical_get(self[1])) .. ' )'
        elseif (listp(logical_get(self[2]))) then return ' ' .. tostring(logical_get(self[1])) .. logical_get(self[2]):rest_tostring()
        else return ' ' .. tostring(logical_get(self[1])) .. ' . ' .. tostring(self[2]) ..' )'
        end
end

local Cons_meta={ 
  __tostring=function (self)  
        if nullp(self) then return '()'
        elseif nullp(logical_get(self[2])) then return '( ' .. tostring(logical_get(self[1])) .. ' )'
        elseif listp(logical_get(self[2])) then return '( ' .. tostring(logical_get(self[1])) .. logical_get(self[2]):rest_tostring()
        else return '( ' .. tostring(logical_get(self[1])) .. ' . ' .. tostring(self[2]) ..' )'
        end
end,
    
  __index = Cons
  }

function Cons:new(car,cdr)
    if (car==nil and cdr==nil) then return Null end
    return setmetatable({ car or Null,  cdr or Null },Cons_meta)
end

car=function(self)
--    if nullp(self) then error ("car of Null list") end
    return self[1]
end
cdr=function(self)
--    if nullp(self) then error ("cdr of Null list") end
    return self[2]
end

list=function (t)
    if class_of(t) ~='table' then return t  end
    local l=#t
    if l == 0 then return Null end
    local loop;
    loop=function(cons,tb,pos) 
        if pos==0 then return cons end
        return loop(Cons:new(list(tb[pos]),cons),tb,pos-1)
    end
    if l>2 and t[l-1]==Dot then return loop(Cons:new(list(t[l-2]),list(t[l])),t,l-3) end
    return loop(Null,t,l)
end


local Logical = { class_name='logical'   }
local Logical_meta={ 
  __tostring=function (self) 
      local n=logical_get(self)
      if n==Unistanciated then return 'Var'..("%p"):format(self) end
      return 'Var'..("%p"):format(self)..':'..tostring(n) 
    end,
  __index = Logical
  }
function Logical:new(n) 
  return setmetatable({value=n or Unistanciated},Logical_meta) 
end


local function new_search(fn,C,...)
  local amb_list=new_amblist()
  rest = table.pack(...)
  
  local function search_continue(self)
    return amb(amb_list)
  end

  local function search_doit(self)
    self.doit=search_continue
    amb_list.failed=nil
    return fn(C, amb_list,table.unpack(rest,1,rest.n))  
  end 
  
  return setmetatable({ 
   doit=search_doit,
   reset = function(self) self.doit=search_doit end,
   failed=function() return amb_list.failed end,
   
   },{ __call=function(self) return self:doit() end,
   }) 
end

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

local function verb(c,search,X,Y,Z)
  local O = Logical:new()
  local function rest()
    return unify(c,search,list{X,Y,Z},list{{'plays','with',Dot,O},O,{'v','plays','with'}})
  end
  amb_next(search,rest)
  return unify(c,search,list{X,Y,Z},list{{'eats',Dot,O},O,{'v','eats'}})
  
end


local function noun(c,search,X,Y,Z)
  local O = Logical:new()
  local function rest()
    return unify(c,search,list{X,Y,Z},list{{'cat',Dot,O},O,{'n','cat'}})
  end
  amb_next(search,rest)
  return unify(c,search,list{X,Y,Z},list{{'bat',Dot,O},O,{'n','bat'}})
  
end

local function det(c,search,X,Y,Z)
  local O = Logical:new()
  local function rest()
    return unify(c,search,list{X,Y,Z},list{{'a',Dot,O},O,{'d','a'}})
  end
  amb_next(search,rest)
  return unify(c,search,list{X,Y,Z},list{{'the',Dot,O},O,{'d','the'}})  
end
local function verb_phrase(c,search,X,Y,Z)
  local A=Logical:new()
  local B=Logical:new()
  local V=Logical:new()
  local NP=Logical:new()
  local C=Logical:new()
  local function rest()
    local function rest2()
      return noun_phrase(c,search,C,B,NP)
    end
    return verb(rest2,search,A,C,V)
  end
  return unify(rest,search,list{X,Y,Z},list{A,B,{'vp',NP,N}})
end

noun_phrase= function (c,search,X,Y,Z)
  local A=Logical:new()
  local B=Logical:new()
  local D=Logical:new()
  local N=Logical:new()
  local C=Logical:new()
  local function rest()
    local function rest2()
      return noun(c,search,C,B,N)
    end
    return det(rest2,search,A,C,D)
  end
  return unify(rest,search,list{X,Y,Z},list{A,B,{'np',D,N}})
end
local function sentence (c,search,X,Y,Z)
  local A=Logical:new()
  local B=Logical:new()
  local NP=Logical:new()
  local VP=Logical:new()
  local C=Logical:new()
  local function rest()
    local function rest2()
      return verb_phrase(c,search,C,B,VP)
    end
    return noun_phrase(rest2,search,A,C,NP)
  end
  return unify(rest,search,list{X,Y,Z},list{A,B,{'s',NP,VP}})
end


print(list{'A','B',Dot,'C'})
print(list{'A',{'B','C'},Logical:new(5)})

X=Logical:new()
Y=Logical:new()
Z=Logical:new()

function rest1(search)
  print('parse =',X,Y,Z)
  return not search.failed
end


local search = new_search(sentence,rest1,X,Y,Z)

--local search = new_search(unify,rest1,list{'cat',Dot,'dog'},list{X,Dot,Y})

repeat
  l = search()
   print (N,M)
until not l
search:reset()
repeat
  l = search()
   print (N,M) 
until not l