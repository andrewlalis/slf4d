/**
 * This module defines the `Logger`; the central component from which all log
 * messages originate.
 */
module slf4d.logger;

import slf4d.level;
import slf4d.handler;
import std.datetime;

/** 
 * The logger is the core component of SLF4D. Use it to generate log messages
 * in your code. An ad-hoc Logger can be created and used anywhere, but usually
 * you'll want to use a `LoggerFactory` to obtain a pre-configured Logger that
 * has been set up with an application-specific LogHandler.
 */
struct Logger {
    private LogHandler handler;
    private const Level level;
    private const string name;

    public this(LogHandler handler, Level level = Levels.TRACE, string name = __MODULE__) {
        this.handler = handler;
        this.level = level;
        this.name = name;
    }

    // Base log functions.

    public LogBuilder builder() {
        return LogBuilder.forLogger(this);
    }

    public void log(LogMessage msg) {
        if (this.level.value <= msg.level.value) {
            this.handler.handle(msg);
        }
    }

    public void log(
        Level level,
        string msg,
        string moduleName = __MODULE__,
        string functionName = __PRETTY_FUNCTION__
    ) {
        this.log(LogMessage(
            level,
            msg,
            this.name,
            Clock.currTime(),
            LogMessageSourceContext(moduleName, functionName)
        ));
    }

    public void logF(string fmt, T...)(
        Level level,
        T args,
        string moduleName = __MODULE__,
        string functionName = __PRETTY_FUNCTION__
    ) {
        import std.format;
        this.log(level, format!(fmt)(args), moduleName, functionName);
    }

    // INFO functions

    public LogBuilder infoBuilder() {
        return LogBuilder.forLogger(this).lvl(Levels.INFO);
    }

    public void info(
        string msg,
        string moduleName = __MODULE__,
        string functionName = __PRETTY_FUNCTION__
    ) {
        this.log(Levels.INFO, msg, moduleName, functionName);
    }

    public void infoF(string fmt, T...)(
        T args,
        string moduleName = __MODULE__,
        string functionName = __PRETTY_FUNCTION__
    ) {
        this.logF!(fmt, T)(Levels.INFO, args, moduleName, functionName);
    }

    unittest {
        auto handler = new CachingLogHandler();
        Logger log = Logger(handler, Levels.INFO);
        log.log(LogMessage(Levels.ERROR, "Oh no!", Clock.currTime(), LogMessageSourceContext()));
        LogMessage lastMessage = handler.messages[0];
        assert(lastMessage.level == Levels.ERROR);
        assert(lastMessage.message == "Oh no!");
    }
}

/** 
 * A log message that was created by a logger.
 */
struct LogMessage {
    public const Level level;
    public const string message;
    public const string loggerName;
    public const SysTime timestamp;
    public const LogMessageSourceContext context;
}

struct LogMessageSourceContext {
    public const string moduleName;
    public const string functionName;
}

/** 
 * A fluent builder for constructing a log message using method chaining.
 */
struct LogBuilder {
    private Level level;
    private string message;
    private Logger logger;

    package static LogBuilder forLogger(Logger logger) {
        return LogBuilder(logger.level, "", logger);
    }

    public ref LogBuilder lvl(Level level) return {
        this.level = level;
        return this;
    }

    public ref LogBuilder msg(string message) return {
        this.message = message;
        return this;
    }

    public void log(string moduleName = __MODULE__, string functionName = __PRETTY_FUNCTION__) {
        logger.log(LogMessage(
            this.level,
            this.message,
            this.logger.name,
            Clock.currTime(),
            LogMessageSourceContext(
                moduleName,
                functionName
            )
        ));
    }
}
