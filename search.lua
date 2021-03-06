local list,listp,nullp,car,cdr,pairp

local function class_of(obj)
    local c=type(obj)
    if c=='table' and obj.class_name then
        return obj.class_name 
    end
    return c
end

local function save_undo(amb_list,n)
  assert(amb_list.class_name == 'AmbList')
    table.insert(amb_list,n)
    table.insert(amb_list,'undo')
end
local function alt(amb_list,n)
  assert(amb_list.class_name == 'AmbList')
    table.insert(amb_list,n)
    table.insert(amb_list,'alt')
end


local function fail(amb_list)
  assert(amb_list.class_name == 'AmbList')
  table.remove(amb_list)
  return table.remove(amb_list)()
end

local function snip_start(amb_list)
  return #amb_list
end
local function snip(amb_list,snip_pos)
  local n={}
  while #amb_list>snip_pos do
    if table.remove(amb_list) == 'undo' then
      table.insert(n,table.remove(amb_list))
    else
      table.remove(amb_list)
    end
  end
  while #n>0 do 
    table.insert(amb_list,table.remove(n)) 
    table.insert(amb_list,'undo') 
  end
end

local function new_amblist()
  local amb_list
  local function fail()
   amb_list.failed=true
   save_undo(amb_list,fail)
   return nil
  end
  amb_list = { class_name='AmbList',fail,'undo' }
  return amb_list
end

local Uninstanciated= { class_name='uninstanciated_singleton' }
local Dot = { class_name='dot_singleton' }
local Null = { class_name='Cons' }

Null[1]=Null
Null[2]=Null
setmetatable(Null,{__tostring=function() return '()' end})


local function is_logical(v)
  return type(v)=='table' and v.class_name=='logical'
end



--follow the chain of logical unifications to the end, Uninstanciated is a possible result
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

local function logical_set(l,v)
  local _,t = logical_get(l)
  assert(t)
  t.value = v
  return v
end

local function ground(n) 
  return logical_get(n)~=Uninstanciated 
end



--true for equal objects, and logical variables that are unified
--tests for current equality not unifiability
--destructures with the internal routine _predicate_equal if both are predicates


local _predicate_unify

local function unify(C,search,a,b,match_table)
  if not _predicate_unify(search,a,b,match_table) then return fail(search) end
  return C(search)
end


--recursively destructure
_predicate_unify=function(search,a,b,match_table)
  local function filter(v)
    if match_table and match_table[class_of(v)] then 
      return match_table[class_of(v)](v)
    end
    return v
  end
    
  if class_of(a)=='table' then a=list(a) end
  if class_of(b)=='table' then b=list(b) end

  if filter(a)==filter(b) then return true end
  if is_logical(b) then a,b=b,a end
  local a_value=a;
  local b_value=b;
  
  if is_logical(a) then
    local a_target,b_target
    a_value,a_target = logical_get(a)
    b_value,b_target = logical_get(b)
    if filter(a_value)==filter(b_value) then
      if a_value==Uninstanciated then
        if a_target == b_target then return true end
        local restore_a = a_target.value
        a_target.value = b_target
        save_undo(search,function () a_target.value = restore_a return fail(search) end)
        return true
      else
        return true
      end
    elseif b_value==Uninstanciated then a_value,a_target,b_value,b_target = b_value,b_target,a_value,a_target end
    if a_value==Uninstanciated then
      local restore_a = a_target.value
      a_target.value = b_value
      save_undo(search,function () a_target.value = restore_a return fail(search) end)
      return true
    end
  end
  
    
  if pairp(a_value) and pairp(b_value) then
    if not _predicate_unify(search,car(a_value),car(b_value)) then return false end
    return _predicate_unify(search,cdr(a_value),cdr(b_value))    
  end
  return false  
end

function _identical(a,b)
  if a==b then return true end
  if is_logical(b) then 
    a,b=b,a 
  end
  local a_value=a;
  local b_value=b;
  if is_logical(a) then
    local a_target,b_target
    a_value,a_target = logical_get(a)
    b_value,b_target = logical_get(b)
    if a_value==b_value then
      if a_value==Uninstanciated then
        if a_target == b_target then
          return true 
        end
        return false
      else
        return true
      end
    end
    return false
  end
  a=a_value
  b=b_value
  if class_of(a)=='table' then a=list(a) end
  if class_of(b)=='table' then b=list(b) end
  
  if pairp(a) and pairp(b) then
    if not _identical(car(a),car(b)) then return false end
    return _identical(cdr(a),cdr(b))    
  end
  return false  
end

local function identical(C,search,a,b)
  if not _identical(a,b) then return fail(search) end
  return C(search)
end

local function not_identical(C,search,a,b)
  if _identical(a,b) then return fail(search) end
  return C(search)
end


nullp=function (l) return l==Null end

listp =function (n) 
    return 'Cons' ==  class_of(n)
end
pairp=function (n)
    return (not nullp(n)) and listp(n)
end

local Cons = { class_name='Cons'   }

local open_paren = '「 '
local close_paren = ' 」'
local display_nil = '「」'
local display_dot = ' | '

function Cons:rest_tostring()
        if (nullp(logical_get(self[2]))) then return ' ' .. tostring(logical_get(self[1])) .. close_paren
        elseif (listp(logical_get(self[2]))) then return ' ' .. tostring(logical_get(self[1])) .. logical_get(self[2]):rest_tostring()
        else return ' ' .. tostring(logical_get(self[1])) .. display_dot .. tostring(logical_get(self[2])) ..close_paren
        end
end

local Cons_meta={ 
  __tostring=function (self)  
        if nullp(self) then return display_nil
        elseif nullp(logical_get(self[2])) then return open_paren .. tostring(logical_get(self[1])) .. close_paren
        elseif listp(logical_get(self[2])) then return open_paren .. tostring(logical_get(self[1])) .. logical_get(self[2]):rest_tostring()
        else return open_paren .. tostring(logical_get(self[1])) .. display_dot .. tostring(logical_get(self[2])) ..close_paren
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

local LV_COUNTER = 0
local function inc_lv_counter()
  LV_COUNTER=LV_COUNTER+1
  return LV_COUNTER
end
local LV = setmetatable({ class_name='logical'  },{__call=function(self,n) return self:new(n) end})
local LV_meta={ 
  __tostring=function (self) 
      if ground(self) then return tostring(logical_get(self)) end
      local n=logical_get(self)
      if n==Uninstanciated then return 'Var'..self.number end
      return 'Var'..("%p"):format(self)..':'..tostring(n) 
    end,
  __index = LV,
  }
function LV(n) 
  return setmetatable({number = inc_lv_counter(),value=n or Uninstanciated},LV_meta) 
end



local function new_search(fn,C,...)
  local amb_list=new_amblist()
  local rest = table.pack(...)
  
  local function search_continue(self)
    return fail(amb_list)
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

local function LVars(n)
  if n==1 then 
    return LV() 
  end
  return LV(),LVars(n-1)
end

local function apply_dynamic(self,c,search,...)
  local snip_pos = snip_start(search)
  local current_predicate = self[1]
  local extras = table.pack(...)
  local function next() 
    if nullp(current_predicate) then return fail(search) end
    alt(search,next)
    local f=car(current_predicate)
    current_predicate=cdr(current_predicate)
    if type(f) == 'function' then
      return f(snip_pos,c,search,table.unpack(extras))
    end
    return unify(c,search,f,extras[1])
  end
  return next()
end 

local function dynamic()
  return setmetatable({Null,Null},{__call= apply_dynamic})
end

local function assertz(d,f)
  if d[2]==Null then d[1]=Cons:new(f) d[2]=d[1] else
    d[2][2]=Cons:new(f) 
    d[2]=d[2][2]
  end
  return d[2]
end

local function asserta(d,f)
  if d[1]==Null then d[1]=Cons:new(f) d[2]=d[1] else
    d[1]=Cons:new(f,d[1]) 
  end
  return d[1]
end

local function retract_all(d)
  d[1]=Null
  d[2]=Null
end


local Search = {
  retract_all=retract_all,
  asserta=asserta,
  assertz=assertz,
  dynamic=dynamic,
	save_undo=save_undo,
	alt=alt,
	fail=fail,
	snip_start=snip_start,
	snip=snip,
	new_amblist=new_amblist,
	Uninstanciated=Uninstanciated,
	Dot=Dot,
	Null=Null,
	class_of=class_of,
	is_logical=is_logical,
	logical_get=logical_get,
	ground=ground,
	unify=unify,
	nullp=nullp,
	listp=listp,
	pairp=pairp,
	Cons=Cons,
	car=car,
	cdr=cdr,
	list=list,
	LV=LV,
	new_search=new_search,
	identical=identical,
	not_identical=not_identical,
  LVars=LVars,
	_identical=_identical,
  logical_set=logical_set,
}

return Search