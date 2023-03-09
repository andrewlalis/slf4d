/** 
 * Module which defines the default provider's log handler implementation.
 */
module slf4d.default_provider.handler;

import slf4d;

/** 
 * A default handler that just writes a formatted string to stdout, or stderr
 * in the case of WARNING or ERROR messages.
 */
class DefaultLogHandler : LogHandler {
    import std.datetime;
    import std.format : format;
    import std.range;

    private bool colored;

    /** 
     * Constructs a default log handler.
     * Params:
     *   colored = Whether to apply ANSI color codes to output. True by default.
     */
    public shared this(bool colored = true) {
        this.colored = colored;
    }

    /** 
     * Handles log messages by writing them to standard output (or standard
     * error if the level is WARNING or higher).
     * Params:
     *   msg = The message that was produced.
     */
    public shared void handle(immutable LogMessage msg) {
        import std.stdio;

        string prefixStr = format!"%s %s %s"(
            formatLoggerName(msg.loggerName, this.colored),
            formatLogLevel(msg.level, this.colored),
            formatTimestamp(msg.timestamp, this.colored)
        );

        string logStr = prefixStr ~ " " ~ msg.message;
        if (!msg.exception.isNull) {
            ExceptionInfo info = msg.exception.get();
            logStr ~= "\n" ~ formatExceptionInfo(info, this.colored);
        }

        if (msg.level.value >= Levels.ERROR.value) {
            stderr.writeln(logStr);
        } else {
            stdout.writeln(logStr);
        }
    }

    /** 
     * Formats the log message's timestamp as a limited ISO-8601 format that's
     * accurate to the millisecond.
     * Params:
     *   timestamp = The timestamp to format.
     *   colored = Whether to color the name.
     * Returns: The formatted timestamp.
     */
    private static string formatTimestamp(SysTime timestamp, bool colored) {
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

    private static string formatLogLevel(Level level, bool colored) {
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
            }
            s = colorStr ~ s ~ "\033[0m";
        }
        return cast(string) padLeft(s, ' ', 5 + (s.length - originalLength)).array;
    }

    /** 
     * Formats the logger's name (usually this is the name of the module where
     * the logger was created) so that it is of a uniform character width.
     * Params:
     *   name = The logger's name.
     *   colored = Whether to color the name.
     * Returns: The formatted logger name string.
     */
    private static string formatLoggerName(string name, bool colored) {
        const size_t loggerNameLength = 24;

        name = compactLoggerName(name, loggerNameLength);
        const size_t originalNameLength = name.length;
        
        if (colored) {
            name = "\033[33m" ~ name ~ "\033[0m";
        }
        return cast(string) padRight(name, ' ', loggerNameLength + (name.length - originalNameLength)).array;
    }

    private static string compactLoggerName(string name, size_t maxLength) {
        if (name.length <= maxLength) return name;

        string[] segments = name.split(".");
        
        if (segments.length == 1) {
            return segments[0][0 .. maxLength - 3] ~ "...";
        }

        return name;
    }

    unittest {
        assert(compactLoggerName("test", 24) == "test");
        assert(compactLoggerName("testing", 4) == "t...");
    }

    private static string formatExceptionInfo(ExceptionInfo info, bool colored) {
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
}

unittest {
    import slf4d.default_provider.provider;
    auto factory = new shared DefaultProvider().getLoggerFactory();
    factory.setRootLevel(Levels.TRACE);
    Logger log = factory.getLogger();
    log.error("Testing default provider error message.");
    log.warn("Testing default provider warn message.");
    log.info("Testing default provider info message.");
    log.debug_("Testing default provider debug message.");
    log.trace("Testing default provider trace message.");
    log.traceF!"Testing default provider traceF message. %d"(42);
    log.info("ATTENTION! An exception and its stack trace will be shown. THIS IS EXPECTED.");

    try {
        throw new Exception("Oh no!");
    } catch (Exception e) {
        log.error(e);
    }
}