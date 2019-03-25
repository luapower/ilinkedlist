--[[

	Intrinsic doubly-linked list for Terra.
	Written by Cosmin Apreutesei. Public domain.

	Elements must have a fixed memory location while in the list, so they
	can't be stored in a growing dynarray. Allocate elements with malloc,
	a fixedfreelist or a preallocated array that can't grow.

	The element to be inserted must have its prev and next fields set to nil.
	This is to prevent double-inserts. Double-removes are ignored.

	local list_type = list(T, 'next', 'prev')   create a list type
	var list = list_type(nil)                   create a list object
	var list = list(T, 'next', 'prev')          create a list object

	list:init()                                 initialize (for struct members)

	list.first -> &e                            (read/only) first element
	list.last  -> &e                            (read/only) last element

	list:next(&e) -> &e                         next element
	list:prev(&e) -> &e                         prev element

	for &e in list do ... end                   iterate elements (remove() works inside)
	for &e in list:backwards() do ... end       iterate backwards (remove() works inside)

	list:insert_before(&e, &v)                  link v before e
	list:insert_after(&e, &v)                   link v after e
	list:remove(&e)                             unlink element

]]

if not ... then require'ilinkedlist_test'; return end

setfenv(1, require'low')

local function list_type(T, NEXT, PREV)

	local struct list {
		first : &T;
		last  : &T;
	};

	list.empty = `list{
		first = nil;
		last  = nil;
	}

	terra list:init()
		@self = [list.empty]
	end

	function list.metamethods.__cast(from, to, exp)
		if to == list then
			if from == niltype then
				return list.empty
			end
		end
		assert(false, 'invalid cast from ', from, ' to ', to, ': ', exp)
	end

	terra list:next(e: &T) return e.[NEXT] end
	terra list:prev(e: &T) return e.[PREV] end

	list.metamethods.__for = function(self, body)
		return quote
			var e = self.first
			while e ~= nil do
				var n = e.[NEXT] --...so that list:remove(e) works inside for
				[ body(e) ]
				e = n
			end
		end
	end

	local struct backwards {list: &list}
	backwards.metamethods.__for = function(self, body)
		return quote
			var e = self.list.last
			while e ~= nil do
				var p = e.[PREV] --...so that list:remove(e) works inside for
				[ body(e) ]
				e = p
			end
		end
	end
	terra list:backwards() return backwards{list = self} end

	terra list:insert_after(p: &T, v: &T)
		if p == self.last then
			assert(v.[NEXT] == nil and v.[PREV] == nil)
			if self.last ~= nil then
				self.last.[NEXT] = v
				v.[PREV] = self.last
				self.last = v
			else
				self.first = v
				self.last = v
			end
		else
			assert(p ~= nil)
			assert(v.[NEXT] == nil and v.[PREV] == nil)
			var n = p.[NEXT]
			p.[NEXT] = v
			n.[PREV] = v
			v.[PREV] = p
			v.[NEXT] = n
		end
	end

	terra list:insert_before(n: &T, v: &T)
		if n == self.first then
			assert(v.[NEXT] == nil and v.[PREV] == nil)
			if self.first ~= nil then
				self.first.[PREV] = v
				v.[NEXT] = self.first
				self.first = v
			else
				self.first = v
				self.last = v
			end
		else
			assert(n ~= nil)
			self:insert_after(n.[PREV], v)
		end
	end

	terra list:remove(e: &T)
		var p = e.[PREV]
		var n = e.[NEXT]
		if p == nil and n == nil then --prevent double-remove
			assert(e == self.first)
		end
		if p ~= nil then p.[NEXT] = n else self.first = n end
		if n ~= nil then n.[PREV] = p else self.last  = p end
		e.[NEXT] = nil
		e.[PREV] = nil
	end

	setinlined(list.methods)

	return list
end
list_type = terralib.memoize(list_type)

local list_type = function(T, NEXT, PREV)
	if terralib.type(T) == 'table' then
		T, NEXT, PREV = T.T, T.NEXT, T.PREV
	end
	assert(T, 'type expected, got ', type(T))
	return list_type(T, NEXT or 'next', PREV or 'prev')
end

low.intrinsiclinkedlist = macro(function(T, NEXT, PREV)
	T = T:astype()
	local list = list_type(T, NEXT, PREV)
	return `list(nil)
end, list_type)
