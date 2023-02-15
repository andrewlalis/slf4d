/** 
 * A default SLF4D provider that implements a simple string log handler to
 * write messages to stdout or stderr.
 */
module slf4d.default_provider;

import slf4d;
import slf4d.provider;

class DefaultProvider : LoggingProvider {
    /** 
     * Gets a default `LoggerFactory` instance for constructing loggers.
     * Returns: The factory.
     */
    shared shared(LoggerFactory) defineLoggerFactory() {
        return new shared SimpleLoggerFactory(
            new DefaultLogHandler(),
            Levels.INFO
        );
    }
}

/** 
 * A default handler that just writes a formatted string to stdout, or stderr
 * in the case of ERROR messages.
 */
private class DefaultLogHandler : LogHandler {
    shared void handle(LogMessage msg) {
        import std.format;
        import std.stdio;

        string simpleTimestampStr = format!"%04d-%02d-%02dT%02d:%02d:%02d"(
            msg.timestamp.year,
            msg.timestamp.month,
            msg.timestamp.day,
            msg.timestamp.hour,
            msg.timestamp.minute,
            msg.timestamp.second
        );

        string logStr = format!"[%s %s] %s: %s"(
            msg.loggerName,
            msg.level.name,
            simpleTimestampStr,
            msg.message
        );

        if (msg.level.value >= Levels.ERROR.value) {
            stderr.writeln(logStr);
        } else {
            stdout.writeln(logStr);
        }
    }
}

unittest {
    auto factory = new shared DefaultProvider().defineLoggerFactory();
    auto log = factory.getLogger();
    log.info("Testing default provider");
    log.error("Testing default provider error message.");
}