/**
 * This module defines the `Logger`; the central component from which all log
 * messages originate.
 */
module slf4d.logger;

import slf4d.level;
import std.datetime;

/** 
 * The logger is the core component of SLF4D. Use it to generate log messages
 * in your code. A logger should be obtained from a factory.
 */
struct Logger {
    private LogHandler handler;
    private const Level level;

    public void log(Level level, string message) {
        if (this.level.value <= level.value) {
            this.handler.handle(LogMessage(level, message, Clock.currTime()));
        }
    }

    unittest {
        auto handler = new SingleCachingLogHandler();
        Logger log = Logger(handler, Levels.INFO);
        log.log(Levels.ERROR, "Oh no!");
        assert(handler.lastMessage.level == Levels.ERROR);
    }
}

/** 
 * A log message that was created by a logger.
 */
struct LogMessage {
    public const Level level;
    public const string message;
    public const SysTime timestamp;
}

interface LogHandler {
    void handle(LogMessage msg);
}

class SingleCachingLogHandler : LogHandler {
    public LogMessage lastMessage;

    void handle(LogMessage msg) const {
        this.lastMessage = msg;
    }
}
