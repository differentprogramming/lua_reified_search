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
local   _identical= Search._identical
local   not_identical= Search.not_identical
local   LVars=Search.LVars
local   dynamic=Search.dynamic

--/*24*/ condition_1(_,C1,_,_,_,_,_,_) :-
--/*25*/ C1 = red,!.
--/*26*/ condition_1(_,_,_,C2,_,_,_,_) :-
--/*27*/ C2 = red,!.
--/*28*/ condition_1(_,_,_,_,_,C3,_,_) :-
--/*29*/ C3 = red,!.
--/*30*/ condition_1(_,_,_,_,_,_,_,C4) :-
--/*31*/ C4 = red,!.
local function condition_1(c,search,_1,C1,_2,C2,_3,C3,_4,_C4)
  local r25,r27,r29,r31,rcut
  local snip_pos = snip_start(search)
  rcut=function() snip(search,snip_pos) return c(search) end
  r25=function() alt(search,r27)
    return unify(rcut,search,C1,'red') end
  r27=function() alt(search,r29)
    return unify(rcut,search,C2,'red') end
  r29=function() alt(search,r31)
    return unify(rcut,search,C3,'red') end
  r31=function() return unify(rcut,search,C4,'red') end
  return r25()
end

--/*32*/ condition_2(P1,_1,P2,C2,_2,_3,_4,_5) :-
--/*33*/ P2 is P1 + 1,
--/*34*/ C2 = blue,!.
--/*35*/ condition_2(P1,_1,_2,_3,P3,C3,_4,_5) :-
--/*36*/ P3 is P1 + 1,
--/*37*/ C3 = blue,!.
--/*38*/ condition_2(P1,_1,_2,_3,_4,_5,P4,C4) :-
--/*39*/ P4 is P1 + 1,
--/*40*/ C4 = blue,!.
local function condition_2(c,search,P1,_,P2,C2,P3,C3,P4,C4)
  local r33,r34,r36,r37,r39,r40,rcut
  local snip_pos = snip_start(search)
  rcut=function() snip(search,snip_pos) return c(search) end
  r33=function() 
    alt(search,r36)
    return unify(r34,search,P2,logical_get(P1)+1)
    end
  r34=function() return unify(rcut,search,C2,'blue') end
  r36=function()
    alt(search,r39)
    return unify(r37,search,P3,logical_get(P1)+1)
    end
  r37=function() return unify(rcut,search,C3,'blue') end
  r39=function() return unify(r40,search,P4,logical_get(P1)+1) end
  r40=function() return unify(rcut,search,C4,'blue') end
  return r33()
end

--/*47*/ color(orange).
--/*48*/ color(blue).
--/*49*/ color(red).
--/*50*/ color(plaid).
local function color(c, search, C)
  local function r50()
    return unify(c,search,C,'plaid')
  end
  local function r49()
    alt(search,r50)
    return unify(c,search,C,'red')
  end
  local function r48()
    alt(search,r49)
    return unify(c,search,C,'blue')
  end
  alt(search,r48)
  return unify(c,search,C,'orange')
end
--/*51*/ position(1).
--/*52*/ position(2).
--/*53*/ position(3).
--/*54*/ position(4).

local position = dynamic()
table.insert(position, function(s,c,search,C) return unify(c,search,C,1) end )
table.insert(position, function(s,c,search,C) return unify(c,search,C,2) end )
table.insert(position, function(s,c,search,C) return unify(c,search,C,3) end )
table.insert(position, function(s,c,search,C) return unify(c,search,C,4) end )


--/*21*/ conditions(Number,_,Color) :-
--/*22*/ position(Number),
--/*23*/ color(Color).
local function conditions(c,search,Number,_,Color)
  local function r23()
    return color(c,search,Color)
  end
  return position(r23,search,Number)
end

--combined all_positions_are_different with all_colors_are_different
--since there is no difference between =\= and \== in our implementation
--/*41*/ all_positions_are_different(X1, X2, X3, X4) :-
--/*42*/ X1 =\= X2, X1 =\= X3, X1 =\= X4,
--/*43*/ X2 =\= X3, X2 =\= X4, X3 =\= X4.
-- example of recasting logic as lua
local function all_different(c, search, X1, X2, X3, X4)
  if _identical(X1,X2) or _identical(X1,X3) or _identical(X1,X4)  
    or _identical(X2,X3) or _identical(X2,X4)
    or _identical(X3,X4) then 
    return fail(search)
  end
--  print("all different "..tostring(X1).." "..tostring(X2).." "..tostring(X3).." "..tostring(X4))
  return c(search)
end

--1

local function top(c,search)
local C1,C2,C3,C4,P1,P2,P3,P4 = LVars(8)
local r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16

  r2=function() 
    alt(search,r16)
    return conditions(r3,search,P1,"Fred",C1) end
  r3=function() return conditions(r4,search,P1,"Joe",C2) end
  r4=function() return unify(r5,search,P2,2) end
  r5=function() return conditions(r6,search,P4, "Bob", C4) end
  r6=function() return unify(r7,search,C4,'plaid') end
  r7=function() return conditions(r8,search,P3,"Tom", C3) end
  r8=function()  return not_identical(r9,search,C3,'orange') end
  r9=function() return not_identical(r10,search,P3,2) end
  r10=function() return not_identical(r11,search,P3,4) end
  r11=function() return all_different(r12,search,P1, P2, P3, P4) end
  r12=function() return all_different(r13,search,C1, C2, C3, C4) end
  r13=function() return condition_1(r14,search,P1, C1, P2, C2, P3, C3, P4, C4) end
  r14=function() return condition_2(r15,search,P1, C1, P2, C2, P3, C3, P4, C4) end
  r15=function() 
    print("Fred is in position "..tostring(P1).." and wears "..tostring(C1).." pants.")
    print("Joe is in position "..tostring(P2).." and wears "..tostring(C2).." pants.")
    print("Tom is in position "..tostring(P3).." and wears "..tostring(C3).." pants.")
    print("Bob is in position "..tostring(P4).." and wears "..tostring(C4).." pants.")
    print()
    return fail(search)
    end
  r16=function()
     print("That’s all!")
     return c(search)
    end
  return r2()
end

-- /*1*/ top:-
-- % Fred is standing somewhere and has pants of some color:
-- /*2*/ conditions(P1,"Fred",C1),
-- % 3)Joe is second in line:
-- /*3*/ conditions(P2, "Joe",C2),
-- /*4*/ P2 is 2,
-- % 4)Bob is wearing plaid pants;:
-- /*5*/ conditions(P4, "Bob", C4),
-- /*6*/ C4 = plaid,
-- % 5)Tom isn’t in position one or four, and he isn’t
-- % wearing the hideous orange pants:
-- /*7*/ conditions(P3,"Tom", C3),
-- /*8*/ C3 \== orange,
-- /*9*/ P3 =\= 2,
-- /*10*/ P3 =\= 4,
-- /*11*/ all_positions_are_different(P1, P2, P3, P4),
-- /*12*/ all_colors_are_different(C1, C2, C3, C4),
-- % 1)someone is wearing red pants - see condition_1():
-- /*13*/ condition_1(P1, C1, P2, C2, P3, C3, P4, C4),
-- % 2)the golfer to Fred’s immediate right is wearing blue pants; -
-- % see condition__2():
-- /*14*/ condition_2(P1, C1, P2, C2, P3, C3, P4, C4),
-- /*15*/ write("Fred is in position "),write(P1),
-- write(" and wears "),write(C1), write(" pants."),nl,
-- /*16*/ write("Joe is in position "), write(P2),
-- write(" and wears "),write(C2), write(" pants."),nl,
-- /*17*/ write("Tom is in position "), write(P3),
-- write(" and wears "),write(C3), write(" pants."),nl,
-- /*18*/ write("Bob is in position "), write(P4),
-- write(" and wears "),write(C4), write(" pants."),nl,nl,fail.
-- /*19*/ top:-
-- /*20*/ write("That’s all!"),nl.
-- /*21*/ conditions(Number,_,Color) :-
-- /*22*/ position(Number),
-- /*23*/ color(Color).
-- /*24*/ condition_1(_,C1,_,_,_,_,_,_) :-
-- /*25*/ C1 = red,!.
-- /*26*/ condition_1(_,_,_,C2,_,_,_,_) :-
-- /*27*/ C2 = red,!.
-- /*28*/ condition_1(_,_,_,_,_,C3,_,_) :-
-- /*29*/ C3 = red,!.
-- /*30*/ condition_1(_,_,_,_,_,_,_,C4) :-
-- /*31*/ C4 = red,!.
-- /*32*/ condition_2(P1,_,P2,C2,_,_,_,_) :-
-- /*33*/ P2 is P1 + 1,
-- /*34*/ C2 = blue,!.
-- /*35*/ condition_2(P1,_,_,_,P3,C3,_,_) :-
-- /*36*/ P3 is P1 + 1,
-- /*37*/ C3 = blue,!.
-- /*38*/ condition_2(P1,_,_,_,_,_,P4,C4) :-
-- /*39*/ P4 is P1 + 1,
-- /*40*/ C4 = blue,!.
-- /*41*/ all_positions_are_different(X1, X2, X3, X4) :-
-- /*42*/ X1 =\= X2, X1 =\= X3, X1 =\= X4,
-- /*43*/ X2 =\= X3, X2 =\= X4, X3 =\= X4.
-- /*44*/ all_colors_are_different(X1, X2, X3, X4) :-
-- /*45*/ X1 \== X2, X1 \== X3, X1 \== X4,
-- /*46*/ X2 \== X3, X2 \== X4, X3 \== X4.
-- /*47*/ color(orange).
-- /*48*/ color(blue).
-- /*49*/ color(red).
-- /*50*/ color(plaid).
-- /*51*/ position(1).
-- /*52*/ position(2).
-- /*53*/ position(3).
-- /*54*/ position(4).

local function rest1(search)
  return not search.failed
end
local search = new_search(top,rest1)

repeat
  l = search()
 --  print (N,M)
until not l
