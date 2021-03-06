setfenv(1, require'low')
require'ilinkedlist'

local struct S {
	x: int;
	next: &S;
	prev: &S;
}
terra test()
	var a = arr(S)
	a:add(S{1, nil, nil})
	a:add(S{2, nil, nil})
	a:add(S{3, nil, nil})

	var s = intrinsiclinkedlist(S)

	for i,e in a:backwards() do s:insert_before(s.first, e) end
	do var i = 1; for e in s do assert(e.x == i); inc(i) end assert(i == 4) end
	do var i = 3; for e in s:backwards() do assert(e.x == i); dec(i) end assert(i == 0) end

	for e in s do s:remove(e) end
	assert(s.first == nil)
	assert(s.last == nil)

	for i,e in a do s:insert_after(s.last, e) end
	do var i = 1; for e in s do assert(e.x == i); inc(i) end end
	do var i = 3; for e in s:backwards() do assert(e.x == i); dec(i) end end

	do var i=1;
		for e in s:backwards() do s:remove(e)
			inc(i)
			if i==3 then break end
		end
	end
	assert(s.first == s.last)
	s:remove(s.last)
	assert(s.first == nil)
	assert(s.last == nil)

	for i,e in a do s:insert_after(s.last, e) end
	s:remove(s.first)
	assert(s.first.next == s.last)

	s:remove(s.last)
	assert(s.first == s.last)
	assert(s.first.next == nil)
	assert(s.first.prev == nil)

	var e = s.last
	s:remove(s.last)
	assert(s.first == nil)
	assert(s.last == nil)
	assert(e.prev == nil)
	assert(e.next == nil)

	s:insert_before(s.first, a:at(0))
	s:insert_after(a:at(0), a:at(2))
	s:insert_before(a:at(2), a:at(1))
	do var i = 1; for e in s do assert(e.x == i); inc(i) end end

end
test()
