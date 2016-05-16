


function amb_next(amb_list,n)
    table.insert(amb_list,n)
end
function amb(amb_list)
  return table.remove(amb_list)()
end

function new_amblist()
  local amb_list
  fail= function ()
--    print 'failed'
    return amb_next(amb_list,fail)
  end
  amb_list = { fail }
  return amb_list
end

local function stream1(C,amb_list)
  local n=0
  local function rest()
    n=n+1
    if n==10 then return amb(amb_list) end
    amb_next(amb_list,rest)
    return C(amb_list,n)
  end
  return rest()
end

local function stream2(C,amb_list)
  local n=0
  local function rest()
    n=n+1
    if n==4 then return amb(amb_list) end
    amb_next(amb_list,rest)
    return C(amb_list,n*n)
  end
  return rest()
end


local function rest1(search,m)
  local function rest2(search,n)
--    print(m,n)
    if m~=n then return amb(search) end
--    print("equal!",m,n)
    return m,n
  end
  
  return stream2(rest2,search)
end

local function new_search(fn,C,...)
  local amb_list=new_amblist()
  rest = table.pack(...)
  
  local function search_continue(self)
    return amb(amb_list)
  end

  local function search_doit(self)
    self.doit=search_continue
    return fn(C, amb_list,table.unpack(rest,rest.n))  
  end 
  
  return setmetatable({ 
   doit=search_doit,
   reset = function(self) self.doit=search_doit end
   },{ __call=function(self) return self:doit() end })
 
 
end


local search = new_search(stream1,rest1)
repeat
  l,k = search()
  if l then  print (l,k) end
until not l
search:reset()
repeat
  l,k = search()
  if l then  print (l,k) end
until not l