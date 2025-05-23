/** 
 * Module which defines the default provider's log handler implementation.
 */
module slf4d.default_provider.handler;

import slf4d;
import slf4d.default_provider.formatters;

/** 
 * A default handler that just writes a formatted string to stdout, or stderr
 * in the case of WARNING or ERROR messages.
 */
shared class DefaultLogHandler : LogHandler {
    import std.datetime;
    import std.format : format;
    import std.range;

    private bool colored;

    /** 
     * Constructs a default log handler.
     * Params:
     *   colored = Whether to apply ANSI color codes to output. False by default.
     */
    public this(bool colored = false) {
        this.colored = colored;
    }

    /** 
     * Handles log messages by writing them to standard output (or standard
     * error if the level is WARNING or higher).
     * Params:
     *   msg = The message that was produced.
     */
    public void handle(immutable LogMessage msg) shared {
        import std.stdio;
        string logStr = formatLogMessage(msg, this.colored);
        synchronized(this) {
            if (msg.level.value >= Levels.ERROR.value) {
                stderr.writeln(logStr);
                stderr.flush();
            } else {
                stdout.writeln(logStr);
                stdout.flush();
            }
        }
    }
}

unittest {
    import slf4d.default_provider.provider;
    auto factory = new DefaultProvider(false, Levels.INFO, null).getLoggerFactory();
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