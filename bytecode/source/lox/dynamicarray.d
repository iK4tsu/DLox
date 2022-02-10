module lox.dynamicarray;

struct DynamicArray(T)
{
	import lox.mallocator : Mallocator;
	version(D_BetterC) import lox.memset;
	version(dlox_unittest) import std.stdio;

	this(U : T)(U[] slice)
	{
		this.opAssign(slice);
	}

	~this()
	{
		if (slice_ is null) return;
		scope(exit) slice_ = null;
		scope(exit) length_ = 0;

		static if ((is(T == struct) || is(T == union)) && __traits(hasMember, T, "__xdtor"))
		{
			foreach (ref value; slice_[0 .. length])
				value.__xdtor();
		}

		() @trusted { allocator.deallocate(slice_); } ();
	}

	this(ref return scope DynamicArray rhs)
	{
		this.opAssign(rhs[]);
	}

	ref back() @property
	{
		return slice_[length - 1];
	}


	/**
	The total space allocated for this array.

	Returns: the reserved capacity.
	*/
	size_t capacity() @property const
	{
		return slice_.length;
	}


	/**
	Ensures sufficient capacity to accommodate `n` elements. If 'n' is lower than
	the current capacity no reservation is performed.

	Params:
		n = size to reserve
	*/
	void capacity(size_t n) @property
	{
		reserve(n);
	}

	bool empty() @property const
	{
		return !length;
	}

	ref front() @property
	{
		return slice_[0];
	}

	/**
	The amount of elements currently in the array. The length defines the amount
	of elements that can be accessed.

	Returns: the current length.
	*/
	size_t length() @property const
	{
		return length_;
	}

	/**
	Update the array's size. If the size grows, the values are initialized with
	their default initializers. If the size shrinks and T has an elaborate dtor,
	the dtor is called for each value;

	Params:
		n = new size.
	*/
	void length(size_t n) @property
	{
		resize(n);
	}

	ref auto opAssign(DynamicArray value)
	{
		return opAssign(value[]);
	}

	ref opAssign(U : T)(U[] values)
	{
		reserve(values.length);
		scope(exit) length_ = values.length;


		if (length == values.length)
		{
			version(D_BetterC)
			{
				foreach (i, ref value; this[])
					value = values[i];
			}
			else
				this[] = values[];
		}
		else if (length < values.length)
		{
			version(D_BetterC)
			{
				foreach (i, ref value; this[])
					value = values[i];
			}
			else
				this[] = values[0 .. length];

			import std.traits : hasElaborateDestructor;
			static if (hasElaborateDestructor!T)
			{
				import core.lifetime : copyEmplace;

				foreach (i; length .. values.length)
				{
					static if (__traits(compiles, () @safe { T t; t = T.init; }))
						() @trusted @nogc { values[i].copyEmplace(slice_[i]); } ();
					else
						values[i].copyEmplace(slice_[i]);
				}
			}
			else
			{
				slice_[length .. values.length] = values[length .. $];
			}
		}
		else if (length > values.length)
		{
			version(D_BetterC)
			{
				foreach (i, ref value; slice_[0 .. values.length])
					value = values[i];
			}
			else
				slice_[0 .. values.length] = values[];

			import std.traits : hasElaborateDestructor;
			static if ((is(T == struct) || is(T == union)) && __traits(hasMember, T, "__xdtor"))
			{
				foreach (ref value; slice_[values.length .. length])
					value.__xdtor();
			}
		}

		return this;
	}

	DynamicArray opBinary(string op : "~", U : T)(U rhs)
	{
		DynamicArray arr;
		arr.reserve(length_ + 1);
		arr.opOpAssign!("~", false)(this[]);
		arr ~= rhs;
		return arr;
	}

	DynamicArray opBinary(string op : "~", U : T)(U[] rhs)
	{
		DynamicArray arr;
		arr.reserve(length_ + 1);
		arr.opOpAssign!("~", false)(this[]);
		arr.opOpAssign!("~", false)(rhs);
		return arr;
	}

	DynamicArray opBinary(string op : "~")(DynamicArray rhs)
	{
		return this ~ rhs[];
	}

	alias opDollar = length;

	///
	bool opEquals(U : T)(U[] other) const
	{
		return slice_[0 .. length] == other;
	}

	///
	bool opEquals(U)(DynamicArray!U other) const
	{
		return opEquals(other.slice_[0 .. other.length]);
	}

	ref T opIndex(size_t index)
	{
		return this[][index];
	}

	T opIndexAssign(U : T)(U value, size_t index)
	{
		return this[][index] = value;
	}

	ref DynamicArray opOpAssign(string op : "~", U : T)(U rhs) @safe
	{
		resize(length_ + 1, rhs);
		return this;
	}

	ref DynamicArray opOpAssign(string op : "~")(DynamicArray rhs)
	{
		return this ~= rhs[];
	}

	ref DynamicArray opOpAssign(string op : "~", bool checkOverlap = true, U : T)(U[] rhs)
	{
		static if (checkOverlap)
		if (() @trusted { return slice_.ptr <= rhs.ptr && slice_.ptr + slice_.length > rhs.ptr; } ())
		{
			// Special case where rhs is a slice of this array.
			this = () @safe { return this ~ rhs; } ();
			return this;
		}

		reserve(length + rhs.length);

		import core.lifetime : copyEmplace;
		import std.traits: hasElaborateDestructor;

		static if (hasElaborateDestructor!T)
		{
			foreach (ref value; rhs)
			{
				static if (__traits(compiles, () @safe { T t; t = T.init; }))
					() { value.copyEmplace(arr[length_++]); } ();
				else
					value.copyEmplace(arr[length_++]);
			}
		}
		else
		{
			slice_[length .. length + rhs.length] = rhs[];
			length_ += rhs.length;
		}

		return this;
	}

	T[] opSliceAssign(U : T)(U value)
	{
		return this[][] = value;
	}

	T[] opSliceAssign(U : T)(U[] value)
	{
		return this[][] = value[];
	}

	T[] opSliceAssign(U : T)(U value, size_t start, size_t end)
	{
		return this[][start .. end] = value;
	}

	T[] opSliceAssign(U : T)(U[] value, size_t start, size_t end)
	{
		return this[][start .. end] = value[];
	}

	T[] opSlice()
	{
		return slice_[0 .. length];
	}

	const(T)[] opSlice() const
	{
		return slice_[0 .. length];
	}

	T[] opSlice(size_t start, size_t end)
	{
		return this[][start .. end];
	}

	const(T)[] opSlice(size_t start, size_t end) const
	{
		return this[][start .. end];
	}

	void remove(size_t i)
		in (i < length)
	{
		scope(exit) length_--;

		static if ((is(T == struct) || is(T == union)) && __traits(hasMember, T, "__xdtor"))
		{
			this[][i].__xdtor;
		}

		import core.lifetime : copyEmplace;

		foreach (n; i + 1 .. length)
		{
			static if (__traits(compiles, () @safe { T t; t = T.init; }))
				() @trusted { slice_[n].copyEmplace(slice_[n - 1]); } ();
			else
				slice_[n].copyEmplace(slice_[n - 1]);
		}
	}

	void removeBack()
	{
		remove(length_ - 1);
	}

	void removeFront()
	{
		remove(0);
	}

	/**
	Ensures sufficient capacity to accommodate `n` elements. If 'n' is lower than
	the current capacity no reservation is performed.

	Params:
		n = size to reserve
	*/
	void reserve(size_t n)
	{
		if (capacity >= n) return;

		if (slice_ is null)
		{
			// first allocation guarantees 4 capacity
			size_t inicap = 4 < n ? n : 4;

			auto ptr = allocator.allocate(T.sizeof * inicap);
			slice_ = () @trusted { return cast(typeof(slice_)) ptr; } ();
		}
		else  // capacity < n
		{
			// reallocation doubles capacity until 512 and increments by 1024 after
			size_t newcap = capacity > 512 ? capacity + 1024 : capacity << 1;
			if (newcap < n) newcap = n;

			void[] arr = cast(void[]) slice_;
			() @trusted { allocator.reallocate(arr, T.sizeof * newcap); } ();
			slice_ = () @trusted { return cast(typeof(slice_)) arr; } ();
		}
	}

	/**
	Update the array's size. If the size grows, the values are initialized with
	their default initializers. If the size shrinks and T has an elaborate dtor,
	the dtor is called for each value;

	Params:
		n = the new size.
	*/
	void resize(size_t n)
	{
		auto toinit = resizeInternal(n);

		import std.traits : hasElaborateDestructor;

		static if (hasElaborateDestructor!T)
		{
			import core.lifetime : emplace;

			// do not call the destructor of each 'value'
			foreach (ref value; toinit)
				emplace(&value);
		}
		else
		{
			// make use of the compiler assignment
			toinit[] = T.init;
		}
	}

	/**
	Update the array's size. If the size grows, the values are initialized with
	'init'. If the size shrinks and T has an elaborate dtor, the dtor is called
	for each value;

	Params:
		n = new array size.
		init = default initializer.
	*/
	void resize(size_t n, T init)
	{
		auto toinit = resizeInternal(n);

		import std.traits : hasElaborateDestructor;

		static if (hasElaborateDestructor!T)
		{
			import core.lifetime : copyEmplace;

			// do not call the destructor of each 'value'
			foreach (ref value; toinit)
			{
				static if (__traits(compiles, () @safe { T t; t = T.init; }))
					() @trusted @nogc { init.copyEmplace(value); } ();
				else
					init.copyEmplace(value);
			}
		}
		else
		{
			// make use of the compiler assignment
			toinit[] = init;
		}
	}

	alias popBack = removeBack;

	alias popFront = removeFront;

private:
	T[] resizeInternal(size_t n)
	{
		T[] toinit;
		scope(exit) length_ = n;

		reserve(n);

		// resizing works both ways, growing and shrinking
		if (length < n)
		{
			toinit = slice_[length .. n];
		}
		else
		{
			static if ((is(T == struct) || is(T == union)) && __traits(hasMember, T, "__xdtor"))
			{
				// when shrinking dtors must run
				foreach (ref value; slice_[n .. length])
					value.__xdtor();
			}
		}

		return toinit;
	}

	T[] slice_;
	size_t length_;
	alias allocator = Mallocator.instance;
}

@safe pure nothrow @nogc unittest
{
	DynamicArray!int arr = [1, 2, 3];
	assert(arr == [1, 2, 3]);
	assert(arr[0] == 1);
	assert(arr[0 .. 2] == [1, 2]);
	assert(arr.length == 3);

	arr[1] = 4;
	assert(arr[1] == 4);

	arr[0 .. 2] = [12, 6];
	assert(arr[0 .. 2] == [12, 6]);

	arr[] = 4;
	assert(arr == [4, 4, 4]);

	arr[] = [4, 5, 6];
	assert(arr == [4, 5, 6]);

	arr = [1, 2, 3, 4, 5, 6];
	assert(arr == [1, 2, 3, 4, 5, 6]);
}
