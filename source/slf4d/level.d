/**
 * Defines the concept of a *Log Level*, that is, a quantifiable *severity* of
 * a log message, which can be used to determine if such a message is shown, or
 * where that message gets routed.
 */
module slf4d.level;
import slf4d;

/** 
 * The set of pre-defined logging levels that are universally recognized.
 */
const enum Levels {
    /** 
     * The lowest severity log level defined by SLF4D, usually for fine-grained
     * debugging of individual statements and control flow.
     */
    TRACE = Level(10, "TRACE"),
    /** 
     * A low severity log level used for extra information that's only useful
     * when debugging a program's behavior.
     */
    DEBUG = Level(20, "DEBUG"),

    /** 
     * A medium severity log level used for reporting information during
     * standard, nominal program operation.
     */
    INFO = Level(30, "INFO"),

    /** 
     * A namehigher severity log level for reporting anomalous but non-fatal issues
     * that arise at runtime.
     */
    WARN = Level(40, "WARN"),

    /** 
     * A severe log level for program errors that indicate a fatal bug that
     * leads to program failure or inconsistent state.
     */
    ERROR = Level(50, "ERROR")
}

unittest {
    assert(Levels.TRACE.value < Levels.DEBUG.value);
    assert(Levels.DEBUG.value < Levels.INFO.value);
    assert(Levels.INFO.value < Levels.WARN.value);
    assert(Levels.WARN.value < Levels.ERROR.value);
}

/**
 * Attempts to parse one of the standard logging levels defined by `Levels`
 * from a string. The provided string is checked against the names of each of
 * the defined logging levels, and the level whose name matches is returned,
 * ignoring capitalization or whitespace.
 * Params:
 *   s = The string to parse.
 * Returns: The level that was parsed, or if none was found, a `LoggingException`
 * is thrown.
 */
Level parseLoggingLevel(string s) {
    import std.string : strip, toUpper;
    import std.traits : EnumMembers;
    if (s is null || s.strip.toUpper.length == 0) {
        throw new LoggingException("Cannot parse logging level from a null or empty string.");
    }
    s = s.strip.toUpper;
    static foreach(lvl; EnumMembers!Levels) {
        if (s == lvl.name) {
            return lvl;
        }
    }
    throw new LoggingException("String \"" ~ s ~ "\" didn't match any logging level.");
}

unittest {
    assert(parseLoggingLevel("TRACE") == Levels.TRACE);
    assert(parseLoggingLevel("DEBUG") == Levels.DEBUG);
    assert(parseLoggingLevel("INFO") == Levels.INFO);
    assert(parseLoggingLevel("WARN") == Levels.WARN);
    assert(parseLoggingLevel("ERROR") == Levels.ERROR);
    // Check that case-sensitivity and whitespace don't matter.
    assert(parseLoggingLevel(" inFo\n") == Levels.INFO);
    try {// Check that invalid strings throw an exception.
        auto l = parseLoggingLevel("not a logging level");
        assert(false, "Expected parseLoggingLevel to throw, but returned " ~ l.name);
    } catch (LoggingException e) {
        // This is fine.
    }
    try {// Null strings should also throw.
        auto l = parseLoggingLevel(null);
        assert(false, "Expected parseLoggingLevel to throw, but returned " ~ l.name);
    } catch (LoggingException e) {
        // This is fine.
    }
    try {
        auto l = parseLoggingLevel("");
        assert(false, "Expected parseLoggingLevel to throw, but returned " ~ l.name);
    } catch (LoggingException e) {
        // This is fine.
    }
}

/** 
 * The struct definition of a logging level.
 */
struct Level {
    /** 
     * The integer value of this level. A higher value indicates a greater
     * severity of the log message.
     */
    public int value;

    /** 
     * The textual name of this level, which may be shown in formatted log
     * messages.
     */
    public string name;
}
