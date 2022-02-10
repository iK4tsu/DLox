module lox.mallocator;

/**
   The C heap allocator.
 */
struct Mallocator
{
    /**
    The alignment is a static constant equal to $(D platformAlignment), which
    ensures proper alignment for any D data type.
    */
    enum uint alignment = double.alignof > real.alignof ? double.alignof : real.alignof ;

    /**
    Standard allocator methods per the semantics defined above. The
    $(D deallocate) and $(D reallocate) methods are $(D @system) because they
    may move memory around, leaving dangling pointers in user code. Somewhat
    paradoxically, $(D malloc) is $(D @safe) but that's only useful to safe
    programs that can afford to leak memory allocated.
    */
    static void[] allocate()(size_t bytes)
    {
		import core.memory : pureMalloc;
        if (!bytes) return null;
        auto p = pureMalloc(bytes);
        return p ? () @trusted { return p[0 .. bytes]; } () : null;
    }

    /// Ditto
    static bool deallocate()(void[] b)
    {
        import core.memory : pureFree;
        pureFree(b.ptr);
        return true;
    }

    /// Ditto
    static bool reallocate()(ref void[] b, size_t s)
    {
        import core.memory : pureRealloc;
        if (!s)
        {
            // fuzzy area in the C standard, see http://goo.gl/ZpWeSE
            // so just deallocate and nullify the pointer
            deallocate(b);
            b = null;
            return true;
        }
        auto p = cast(ubyte*) pureRealloc(b.ptr, s);
        if (!p) return false;
        b = () @trusted { return p[0 .. s]; } ();
        return true;
    }

    /**
    Returns the global instance of this allocator type. The C heap allocator is
    thread-safe, therefore all of its methods are $(D static) and `instance` itself is
    $(D shared).
    */
    enum Mallocator instance = Mallocator();
}
