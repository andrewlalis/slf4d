/**
 * This module defines the `Logger`; the central component from which all log
 * messages originate. You 
 */
module slf4d.logger;

import slf4d.level;
import slf4d.handler;
import std.datetime : Clock, SysTime;
import std.typecons : Nullable, nullable;

/** 
 * The logger is the core component of SLF4D. Use it to generate log messages
 * in your code. An ad-hoc Logger can be created and used anywhere, but usually
 * you'll want to use the `getLogger()` function to obtain a pre-configured
 * Logger that has been set up with an application-specific LogHandler. The
 * configured LogHandler is marked as `shared`, because only one handler
 * instance exists per application.
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
    private shared LogHandler handler;
    private const Level level;
    private const string name;

    /** 
     * Initializes a new logger. Usually, you won't use this constructor, and
     * instead, you should obtain a Logger via `loggerFactory.getLogger()`.
     * Params:
     *   handler = The handler to handle log messages.
     *   level = The log level of this logger. Only log messages with a level
     *           of equal or greater severity will be logged by this logger.
     *   name = The name of the logger. It defaults to the name of the module
     *          where the logger was initialized.
     */
    public this(shared LogHandler handler, Level level = Levels.TRACE, string name = __MODULE__) {
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
    public void log(immutable LogMessage msg) {
        if (this.level.value <= msg.level.value) {
            this.handler.handle(msg);
        }
    }

    // Test the basic `log` method to ensure log messages are filtered according to the Logger's level.
    unittest {
        auto handler = new shared CachingLogHandler();
        Logger log = Logger(handler, Levels.INFO);

        // Test logging something that's of a sufficient level.
        LogMessage errorMessage = LogMessage(
            Levels.ERROR,
            "Oh no!",
            log.name,
            Clock.currTime(),
            ExceptionInfo.from(new Exception("Oh no!")),
            LogMessageSourceContext()
        );
        log.log(errorMessage);
        LogMessage lastMessage = handler.getMessages()[0];
        assert(lastMessage == errorMessage);
        handler.reset();

        // Test logging something that's not of a sufficient level, and should not show up.
        LogMessage traceMessage = LogMessage(
            Levels.TRACE,
            "Trace message",
            log.name,
            Clock.currTime(),
            ExceptionInfo.from(null),
            LogMessageSourceContext()
        );
        log.log(traceMessage);
        assert(handler.empty);
    }

    /** 
     * Logs a message.
     * Params:
     *   level = The log level.
     *   msg = The string message to log.
     *   exception = The exception that prompted this log. This may be null.
     *   moduleName = The name of the module. This will resolve to the current
     *                module name by default.
     *   functionName = The name of the function. This will resolve to the
     *                current function name by default.
     *   fileName = The name of the source file. This will resolve to the
     *              current source file by default.
     *   lineNumber = The line number in the source file. This will resolve to
     *                the current source file's line number by default.
     */
    public void log(
        Level level,
        string msg,
        Exception exception = null,
        string moduleName = __MODULE__,
        string functionName = __PRETTY_FUNCTION__,
        string fileName = __FILE__,
        size_t lineNumber = __LINE__
    ) {
        this.log(LogMessage(
            level,
            msg,
            this.name,
            Clock.currTime(),
            ExceptionInfo.from(exception),
            LogMessageSourceContext(moduleName, functionName, fileName, lineNumber)
        ));
    }

    /** 
     * Logs a formatted string message.
     * Params:
     *   level = The log level.
     *   args = The arguments for the formatted string.
     *   exception = The exception that prompted this log. This may be null.
     *   moduleName = The name of the module. This will resolve to the current
     *                module name by default.
     *   functionName = The name of the function. This will resolve to the
     *                current function name by default.
     *   fileName = The name of the source file. This will resolve to the
     *              current source file by default.
     *   lineNumber = The line number in the source file. This will resolve to
     *                the current source file's line number by default.
     */
    public void logF(string fmt, T...)(
        Level level,
        T args,
        Exception exception = null,
        string moduleName = __MODULE__,
        string functionName = __PRETTY_FUNCTION__,
        string fileName = __FILE__,
        size_t lineNumber = __LINE__
    ) {
        if (this.level.value <= level.value) {
            import std.format : format;
            this.log(level, format!(fmt)(args), exception, moduleName, functionName, fileName, lineNumber);
        }
    }

    // Compile-time definitions of the various log functions that this Logger provides.

    private static struct LogFunction {
        string level;
        string name;
        string fName;
        string builderName;
    }

    private static immutable LogFunctions = [
        LogFunction("Levels.TRACE", "trace", "traceF", "traceBuilder"),
        LogFunction("Levels.DEBUG", "debug_", "debugF", "debugBuilder"),
        LogFunction("Levels.INFO", "info", "infoF", "infoBuilder"),
        LogFunction("Levels.WARN", "warn", "warnF", "warnBuilder"),
        LogFunction("Levels.ERROR", "error", "errorF", "errorBuilder")
    ];

    // Generate each of the functions defined below, for each LogFunction defined.
    static foreach (lf; LogFunctions) {
        import std.format;

        // Generate the basic log function.
        mixin(q{
            public void %s(
                string msg,
                Exception exception = null,
                string moduleName = __MODULE__,
                string functionName = __PRETTY_FUNCTION__,
                string fileName = __FILE__,
                size_t lineNumber = __LINE__
            ) {
                this.log(%s, msg, exception, moduleName, functionName, fileName, lineNumber);
            }
        }.format(lf.name, lf.level));

        // Generate log function that takes an exception without a message.
        mixin(q{
            public void %s(
                Exception exception,
                string moduleName = __MODULE__,
                string functionName = __PRETTY_FUNCTION__,
                string fileName = __FILE__,
                size_t lineNumber = __LINE__
            ) {
                string message = exception.classinfo.name ~ ": " ~ exception.msg;
                this.log(%s, message, exception, moduleName, functionName, fileName, lineNumber);
            }
        }.format(lf.name, lf.level));

        // Generate the logF function.
        mixin(q{
            public void %s(string fmt, T...)(
                T args,
                Exception exception = null,
                string moduleName = __MODULE__,
                string functionName = __PRETTY_FUNCTION__,
                string fileName = __FILE__,
                size_t lineNumber = __LINE__
            ) {
                this.logF!(fmt, T)(%s, args, exception, moduleName, functionName, fileName, lineNumber);
            }
        }.format(lf.fName, lf.level));

        // Generate builder function.
        mixin(q{
            public LogBuilder %sBuilder() {
                return LogBuilder.forLogger(this).lvl(%s);
            }
        }.format(lf.builderName, lf.level));
    }
}

/** 
 * A log message that was created by a logger.
 */
struct LogMessage {
    /** 
     * The log level for this message. This is an indication of the severity.
     */
    public immutable Level level;

    /** 
     * The actual content of the log message.
     */
    public immutable string message;

    /** 
     * The name of the logger that produced this log message.
     */
    public immutable string loggerName;

    /** 
     * The time at which this message occurred.
     */
    public immutable SysTime timestamp;

    /** 
     * The exception (if any) that was thrown when this message was logged.
     */
    public immutable Nullable!ExceptionInfo exception;

    /** 
     * Additional context about where this log message was generated in the
     * program's source.
     */
    public immutable LogMessageSourceContext sourceContext;
}

/** 
 * Container for information about where a log message was created in a
 * program's source.
 */
struct LogMessageSourceContext {
    /** 
     * The name of the D module that the log message was generated from.
     */
    public immutable string moduleName;

    /** 
     * The name of the function that the message was generated from.
     */
    public immutable string functionName;

    /** 
     * The name of the file that the message was generated from.
     */
    public immutable string fileName;

    /** 
     * The line number in the file where this message was generated.
     */
    public immutable size_t lineNumber;
}

/** 
 * Container for information about an exception that was logged.
 */
struct ExceptionInfo {
    /** 
     * The exception's message.
     */
    public immutable string message;

    /** 
     * The source file in which the exception occurred.
     */
    public immutable string sourceFileName;

    /** 
     * The line number at which the exception occurred.
     */
    public immutable size_t sourceLineNumber;

    /** 
     * The name of the exception class that was thrown.
     */
    public immutable string exceptionClassName;

    /** 
     * The stack trace for the exception, if it's available.
     */
    public immutable Nullable!string stackTrace;

    /** 
     * Constructs a nullable ExceptionInfo from an Exception object.
     * Params:
     *   e = The exception.
     * Returns: A nullable ExceptionInfo.
     */
    public static Nullable!ExceptionInfo from(Exception e) {
        if (e is null) return Nullable!ExceptionInfo.init;

        Nullable!string st;
        if (e.info !is null) {
            st = e.info.toString();
        }
        return ExceptionInfo(e.msg, e.file, e.line, e.classinfo.name, st).nullable;
    }

    unittest {
        assert(ExceptionInfo.from(null).isNull);

        try {
            throw new Exception("Oh no!");
        } catch (Exception e) {
            auto info = ExceptionInfo.from(e);
            assert(!info.isNull);
            assert(info.get.message == "Oh no!");
            assert(info.get.exceptionClassName == "object.Exception");
        }
    }
}

/** 
 * A fluent builder for constructing a log message using method chaining.
 */
struct LogBuilder {
    private Level level;
    private string message;
    private Logger logger;
    private Exception exception;

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
     * Sets the exception of the log.
     * Params:
     *   exception = The exception to set.
     * Returns: A reference to the builder.
     */
    public ref LogBuilder exc(Exception exception) return {
        this.exception = exception;
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
     *   fileName = The name of the source file. This will resolve to the
     *              current source file by default.
     *   lineNumber = The line number in the source file. This will resolve to
     *                the current source file's line number by default.
     */
    public void log(
        string moduleName = __MODULE__,
        string functionName = __PRETTY_FUNCTION__,
        string fileName = __FILE__,
        size_t lineNumber = __LINE__
    ) {
        logger.log(LogMessage(
            this.level,
            this.message,
            this.logger.name,
            Clock.currTime(),
            ExceptionInfo.from(this.exception),
            LogMessageSourceContext(
                moduleName,
                functionName,
                fileName,
                lineNumber
            )
        ));
    }
}
