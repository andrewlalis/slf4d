module slf4d.default_provider.formatters;

import slf4d.level;
import slf4d.logger : ExceptionInfo;
import std.datetime : SysTime;

/** 
 * Formats the log message's timestamp as a limited ISO-8601 format that's
 * accurate to the millisecond.
 * Params:
 *   timestamp = The timestamp to format.
 *   colored = Whether to color the name.
 * Returns: The formatted timestamp.
 */
public string formatTimestamp(SysTime timestamp, bool colored) {
    import std.format : format;
    string s = format!"%04d-%02d-%02dT%02d:%02d:%02d.%03d"(
        timestamp.year,
        timestamp.month,
        timestamp.day,
        timestamp.hour,
        timestamp.minute,
        timestamp.second,
        timestamp.fracSecs.total!"msecs"
    );
    if (colored) {
        s = "\033[90m" ~ s ~ "\033[0m";
    }
    return s;
}

/** 
 * Formats a log level to a fixed-width string that's right-aligned, and
 * optionally colored.
 * Params:
 *   level = The level to format.
 *   colored = Whether to use color.
 * Returns: The formatted string.
 */
public string formatLogLevel(Level level, bool colored) {
    import std.string : leftJustify;

    string s = level.name;
    size_t originalLength = s.length;
    if (colored) {
        string colorStr = "\033[1m";
        if (level == Levels.ERROR) {
            colorStr = "\033[31;1;4m";
        } else if (level == Levels.WARN) {
            colorStr = "\033[33;1m";
        } else if (level == Levels.INFO) {
            colorStr = "\033[34;1m";
        } else if (level == Levels.DEBUG) {
            colorStr = "\033[36;1m";
        } else if (level == Levels.TRACE) {
            colorStr = "\033[37;1m";
        } else {
            colorStr = "\033[34;1m"; // Use blue as a fallback for unknown levels.
        }
        s = colorStr ~ s ~ "\033[0m";
    }
    return leftJustify(s, 5 + (s.length - originalLength), ' ');
}

/** 
 * Formats the logger's name (usually this is the name of the module where
 * the logger was created) so that it is of a uniform character width.
 * Params:
 *   name = The logger's name.
 *   colored = Whether to color the name.
 * Returns: The formatted logger name string.
 */
public string formatLoggerName(string name, bool colored) {
    import std.string : rightJustify;
    const size_t loggerNameLength = 24;

    name = compactLoggerName(name, loggerNameLength);
    const size_t originalNameLength = name.length;
    
    if (colored) {
        name = "\033[33m" ~ name ~ "\033[0m";
    }
    return rightJustify(name, loggerNameLength + (name.length - originalNameLength), ' ');
}

public string compactLoggerName(string name, size_t maxLength) {
    if (name.length <= maxLength) return name;
    return "..." ~ name[3 + $ - maxLength .. $];
}

unittest {
    void assertNameCompacted(string input, size_t size, string expected) {
        import std.format : format;
        string result = compactLoggerName(input, size);
        assert(result == expected, format!"Compacted logger name \"%s\" from \"%s\" does not match expected \"%s\"."(
            result, input, expected
        ));
    }

    assertNameCompacted("test", 24, "test");
    assertNameCompacted("testing", 4, "...g");
    assertNameCompacted("testing", 24, "testing");
    assertNameCompacted("testingtesting", 10, "...testing");
    assertNameCompacted("module1.module2", 10, "...module2");
}

public string formatExceptionInfo(ExceptionInfo info, bool colored) {
    import std.format : format;
    string exceptionName = info.exceptionClassName;
    if (colored) {
        exceptionName = "\033[31;1m" ~ exceptionName ~ "\033[0m";
    }
    string sourceLocation = format!"%s:%d"(info.sourceFileName, info.sourceLineNumber);
    if (colored) {
        sourceLocation = "\033[97;4m" ~ sourceLocation ~ "\033[0m";
    }
    string titleMessage = format!"%s thrown in %s: %s"(
        exceptionName, sourceLocation, info.message
    );
    if (!info.stackTrace.isNull) {
        string traceStr = info.stackTrace.get();
        if (colored) {
            traceStr = "\033[31m" ~ traceStr ~ "\033[0m";
        }
        titleMessage ~= "\n" ~ traceStr;
    }

    return titleMessage;
}