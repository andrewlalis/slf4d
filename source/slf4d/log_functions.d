/** 
 * Helper components for statically-generating logging functions for various
 * standard logging levels.
 */
module slf4d.log_functions;

/** 
 * A definition of a set of log functions that should be generated for a
 * given logging level.
 */
struct LogFunction {
    string level;
    string name;
    string fName;
    string builderName;
}

/** 
 * A compile-time definition of all log functions that should exist.
 */
static immutable STANDARD_LOG_FUNCTIONS = [
    LogFunction("Levels.TRACE", "trace", "traceF", "traceBuilder"),
    LogFunction("Levels.DEBUG", "debug_", "debugF", "debugBuilder"),
    LogFunction("Levels.INFO", "info", "infoF", "infoBuilder"),
    LogFunction("Levels.WARN", "warn", "warnF", "warnBuilder"),
    LogFunction("Levels.ERROR", "error", "errorF", "errorBuilder")
];

/** 
 * A mixin that generates a set of log functions, based on the given list of
 * log function structs.
 * Params:
 *   logFunctions = The list of log functions to generate.
 *   loggerRef = An expression referring to the Logger to call functions on.
 */
mixin template LogFunctionsMixin(LogFunction[] logFunctions = STANDARD_LOG_FUNCTIONS, string loggerRef = q{this}) {
    // Generate each of the functions defined below, for each LogFunction defined.
    static foreach (lf; logFunctions) {
        import std.format;

        static if (lf.name !is null) {
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
                    %s.log(%s, msg, exception, moduleName, functionName, fileName, lineNumber);
                }
            }.format(lf.name, loggerRef, lf.level));

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
                    %s.log(%s, message, exception, moduleName, functionName, fileName, lineNumber);
                }
            }.format(lf.name, loggerRef, lf.level));
        }

        // Generate the logF function.
        static if (lf.fName !is null) {
            mixin(q{
                public void %s(string fmt, T...)(
                    T args,
                    Exception exception = null,
                    string moduleName = __MODULE__,
                    string functionName = __PRETTY_FUNCTION__,
                    string fileName = __FILE__,
                    size_t lineNumber = __LINE__
                ) {
                    %s.logF!(fmt, T)(%s, args, exception, moduleName, functionName, fileName, lineNumber);
                }
            }.format(lf.fName, loggerRef, lf.level));
        }

        // Generate builder function.
        static if (lf.builderName !is null) {
            mixin(q{
                public LogBuilder %s(string moduleName = __MODULE__) {
                    return LogBuilder.forLogger(%s).lvl(%s);
                }
            }.format(lf.builderName, loggerRef, lf.level));
        }
    }
}

