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

    /** 
     * Handles log messages by writing them to standard output (or standard
     * error if the level is WARNING or higher).
     * Params:
     *   msg = The message that was produced.
     */
    public shared void handle(LogMessage msg) {
        import std.stdio;

        string logStr = format!"%s %s %s %s"(
            formatLoggerName(msg.loggerName),
            padLeft(msg.level.name, ' ', 8),
            formatTimestamp(msg.timestamp),
            msg.message
        );

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
     * Returns: The formatted timestamp.
     */
    private static string formatTimestamp(SysTime timestamp) {
        return format!"%04d-%02d-%02dT%02d:%02d:%02d.%03d"(
            timestamp.year,
            timestamp.month,
            timestamp.day,
            timestamp.hour,
            timestamp.minute,
            timestamp.second,
            timestamp.fracSecs.total!"msecs"
        );
    }

    /** 
     * Formats the logger's name (usually this is the name of the module where
     * the logger was created) so that it is of a uniform character width.
     * Params:
     *   name = The logger's name.
     * Returns: The formatted logger name string.
     */
    private static string formatLoggerName(string name) {
        const size_t loggerNameLength = 20;
        if (name.length < loggerNameLength) {
            return cast(string) padRight(name, ' ', loggerNameLength).array;
        } else if (name.length > loggerNameLength) {
            return name[0 .. loggerNameLength - 3] ~ "...";
        } else {
            return name;
        }
    }
}

unittest {
    import slf4d.default_provider.provider;
    auto factory = new shared DefaultProvider().getLoggerFactory();
    auto log = factory.getLogger();
    log.info("Testing default provider");
    log.error("Testing default provider error message.");
}