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
 *
 * Note that the D language offers some special keywords like `__MODULE__` and
 * `__PRETTY_FUNCTION__` which at compile time resolve to the respective source
 * symbols, and are used heavily here for adding context to log messages.
 * Because these must be resolved in the actual source location and *not* in
 * the logger's own code, we make use of default values for most logging
 * functions. Functions will usually end with a list of arguments that default
 * to these keywords, and you shouldn't need to ever provide a value for these.
 */
struct Logger {
    private LogHandler handler;
    private const Level level;
    private const string name;

    /** 
     * Initializes a new logger. Usually, you won't use this constructor, and
     * instead, you should obtain a Logger via `LoggerFactory.getLogger()`.
     * Params:
     *   handler = The handler to handle log messages.
     *   level = The log level of this logger. Only log messages with a level
     *           of equal or greater severity will be logged by this logger.
     *   name = The name of the logger. It defaults to the name of the module
     *          where the logger was initialized.
     */
    public this(LogHandler handler, Level level = Levels.TRACE, string name = __MODULE__) {
        this.handler = handler;
        this.level = level;
        this.name = name;
    }

    /** 
     * Gets a builder that can be used to fluently build a log message.
     * Returns: The builder.
     */
    public LogBuilder builder() {
        return LogBuilder.forLogger(this);
    }

    /** 
     * Logs a message. Only messages whose level is greater than or equal to
     * this logger's level will be logged.
     * Params:
     *   msg = The message to log.
     */
    public void log(LogMessage msg) {
        if (this.level.value <= msg.level.value) {
            this.handler.handle(msg);
        }
    }

    /** 
     * Logs a message.
     * Params:
     *   level = The log level.
     *   msg = The string message to log.
     *   moduleName = The name of the module. This will resolve to the current
     *                module name by default.
     *   functionName = The name of the function. This will resolve to the
     *                current function name by default.
     */
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

    /** 
     * Logs a formatted string message.
     * Params:
     *   level = The log level.
     *   args = The arguments for the formatted string.
     *   moduleName = The name of the module. This will resolve to the current
     *                module name by default.
     *   functionName = The name of the function. This will resolve to the
     *                current function name by default.
     */
    public void logF(string fmt, T...)(
        Level level,
        T args,
        string moduleName = __MODULE__,
        string functionName = __PRETTY_FUNCTION__
    ) {
        import std.format;
        this.log(level, format!(fmt)(args), moduleName, functionName);
    }

    // TRACE functions

    public LogBuilder traceBuilder() {
        return LogBuilder.forLogger(this).lvl(Levels.TRACE);
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

    // ERROR functions

    public LogBuilder errorBuilder() {
        return LogBuilder.forLogger(this).lvl(Levels.ERROR);
    }

    public void error(
        string msg,
        string moduleName = __MODULE__,
        string functionName = __PRETTY_FUNCTION__
    ) {
        this.log(Levels.ERROR, msg, moduleName, functionName);
    }

    public void errorF(string fmt, T...)(
        T args,
        string moduleName = __MODULE__,
        string functionName = __PRETTY_FUNCTION__
    ) {
        this.logF!(fmt, T)(Levels.ERROR, args, moduleName, functionName);
    }

    unittest {
        auto handler = new CachingLogHandler();
        Logger log = Logger(handler, Levels.INFO);
        log.log(LogMessage(Levels.ERROR, "Oh no!", log.name, Clock.currTime(), LogMessageSourceContext()));
        LogMessage lastMessage = handler.messages[0];
        assert(lastMessage.level == Levels.ERROR);
        assert(lastMessage.message == "Oh no!");
    }
}

/** 
 * A log message that was created by a logger.
 */
struct LogMessage {
    /** 
     * The log level for this message. This is an indication of the severity.
     */
    public const Level level;

    /** 
     * The actual content of the log message.
     */
    public const string message;

    /** 
     * The name of the logger that produced this log message.
     */
    public const string loggerName;

    /** 
     * The time at which this message occurred.
     */
    public const SysTime timestamp;

    /** 
     * Additional context about where this log message was generated in the
     * program's source.
     */
    public const LogMessageSourceContext sourceContext;
}

/** 
 * Container for information about where a log message was created in a
 * program's source.
 */
struct LogMessageSourceContext {
    /** 
     * The name of the D module that the log message was generated from.
     */
    public const string moduleName;

    /** 
     * The name of the function that the message was generated from.
     */
    public const string functionName;
}

/** 
 * A fluent builder for constructing a log message using method chaining.
 */
struct LogBuilder {
    private Level level;
    private string message;
    private Logger logger;

    /** 
     * Creates a log builder for the given logger.
     * Params:
     *   logger = The logger that this builder will add the log message to.
     * Returns: The log builder.
     */
    package static LogBuilder forLogger(Logger logger) {
        return LogBuilder(logger.level, "", logger);
    }

    /** 
     * Sets the level of the log message.
     * Params:
     *   level = The log level.
     * Returns: A reference to the builder.
     */
    public ref LogBuilder lvl(Level level) return {
        this.level = level;
        return this;
    }

    /** 
     * Sets the message of the log.
     * Params:
     *   message = The message to set.
     * Returns: A reference to the builder.
     */
    public ref LogBuilder msg(string message) return {
        this.message = message;
        return this;
    }

    /** 
     * Builds the log message and adds it to the logger associated with this
     * builder, and adds source context information using default function
     * arguments.
     * Params:
     *   moduleName = The name of the module. This will resolve to the current
     *                module name by default.
     *   functionName = The name of the function. This will resolve to the
     *                current function name by default.
     */
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
