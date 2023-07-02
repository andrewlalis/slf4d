/**
 * This module defines a set of logging functions that can be used in any
 * application. There is a set of basic `log` functions that accept any logging
 * level, as well as pre-defined functions for the standard SLF4D logging
 * levels.
 * 
 * ### Basic Log Functions
 * ---
 * log(Levels.WARN, "Warning message");
 * log(Levels.ERROR, new Exception("Oh no!"));
 * logF!"Info message: %d"(Levels.INFO, 42);
 * ---
 */
module slf4d.log_functions;

import slf4d.level;
import slf4d : getLogger;

/** 
 * Writes a log message.
 * Params:
 *   level = The logging level.
 *   msg = The message.
 *   exception = An optional exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
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
    getLogger(moduleName).log(level, msg, exception, moduleName, functionName, fileName, lineNumber);
}

/** 
 * Writes an exception log message.
 * Params:
 *   level = The logging level.
 *   exception = The exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void log(
    Level level,
    Exception exception,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    getLogger(moduleName).log(level, exception, moduleName, functionName, fileName, lineNumber);
}

/** 
 * Writes a formatted log message.
 * Params:
 *   level = The logging level.
 *   args = The arguments to provide to the format string.
 *   exception = An optional exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
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
    auto logger = getLogger(moduleName);
    if (logger.level.value <= level.value) {
        import std.format : format;
        logger.log(level, format!(fmt)(args), exception, moduleName, functionName, fileName, lineNumber);
    }
}

/** 
 * Writes a trace log message.
 * Params:
 *   msg = The message.
 *   exception = An optional exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void trace(
    string msg,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.TRACE, msg, exception, moduleName, functionName, fileName, lineNumber);
}

/** 
 * Writes an exception trace log message.
 * Params:
 *   level = The logging level.
 *   exception = The exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void trace(
    Exception exception,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.TRACE, exception, moduleName, functionName, fileName, lineNumber);
}

/** 
 * Writes a formatted trace log message.
 * Params:
 *   level = The logging level.
 *   args = The arguments to provide to the format string.
 *   exception = An optional exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void traceF(string fmt, T...)(
    T args,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    auto logger = getLogger(moduleName);
    if (logger.level.value <= Levels.TRACE.value) {
        import std.format : format;
        logger.log(Levels.TRACE, format!(fmt)(args), exception, moduleName, functionName, fileName, lineNumber);
    }
}

/** 
 * Writes a debug log message.
 * Params:
 *   msg = The message.
 *   exception = An optional exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void debug_(
    string msg,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.DEBUG, msg, exception, moduleName, functionName, fileName, lineNumber);
}

/** 
 * Writes an exception debug log message.
 * Params:
 *   level = The logging level.
 *   exception = The exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void debug_(
    Exception exception,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.DEBUG, exception, moduleName, functionName, fileName, lineNumber);
}

/** 
 * Writes a formatted debug log message.
 * Params:
 *   level = The logging level.
 *   args = The arguments to provide to the format string.
 *   exception = An optional exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void debugF(string fmt, T...)(
    T args,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    auto logger = getLogger(moduleName);
    if (logger.level.value <= Levels.DEBUG.value) {
        import std.format : format;
        logger.log(Levels.DEBUG, format!(fmt)(args), exception, moduleName, functionName, fileName, lineNumber);
    }
}

/** 
 * Writes an info log message.
 * Params:
 *   msg = The message.
 *   exception = An optional exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void info(
    string msg,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.INFO, msg, exception, moduleName, functionName, fileName, lineNumber);
}

/** 
 * Writes an exception info log message.
 * Params:
 *   level = The logging level.
 *   exception = The exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void info(
    Exception exception,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.INFO, exception, moduleName, functionName, fileName, lineNumber);
}

/** 
 * Writes a formatted info log message.
 * Params:
 *   level = The logging level.
 *   args = The arguments to provide to the format string.
 *   exception = An optional exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void infoF(string fmt, T...)(
    T args,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    auto logger = getLogger(moduleName);
    if (logger.level.value <= Levels.INFO.value) {
        import std.format : format;
        logger.log(Levels.INFO, format!(fmt)(args), exception, moduleName, functionName, fileName, lineNumber);
    }
}

/** 
 * Writes a warn log message.
 * Params:
 *   msg = The message.
 *   exception = An optional exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void warn(
    string msg,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.WARN, msg, exception, moduleName, functionName, fileName, lineNumber);
}

/** 
 * Writes an exception warn log message.
 * Params:
 *   level = The logging level.
 *   exception = The exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void warn(
    Exception exception,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.WARN, exception, moduleName, functionName, fileName, lineNumber);
}

/** 
 * Writes a formatted warn log message.
 * Params:
 *   level = The logging level.
 *   args = The arguments to provide to the format string.
 *   exception = An optional exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void warnF(string fmt, T...)(
    T args,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    auto logger = getLogger(moduleName);
    if (logger.level.value <= Levels.WARN.value) {
        import std.format : format;
        logger.log(Levels.WARN, format!(fmt)(args), exception, moduleName, functionName, fileName, lineNumber);
    }
}

/** 
 * Writes an error log message.
 * Params:
 *   msg = The message.
 *   exception = An optional exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void error(
    string msg,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.ERROR, msg, exception, moduleName, functionName, fileName, lineNumber);
}

/** 
 * Writes an exception error log message.
 * Params:
 *   level = The logging level.
 *   exception = The exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void error(
    Exception exception,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.ERROR, exception, moduleName, functionName, fileName, lineNumber);
}

/** 
 * Writes a formatted error log message.
 * Params:
 *   level = The logging level.
 *   args = The arguments to provide to the format string.
 *   exception = An optional exception to log.
 *   moduleName = The name of the module where this log message was written.
 *   functionName = The name of the function where this log message was written.
 *   fileName = The name of the source file where this log message was written.
 *   lineNumber = The line number where this log message was written.
 */
public void errorF(string fmt, T...)(
    T args,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    auto logger = getLogger(moduleName);
    if (logger.level.value <= Levels.ERROR.value) {
        import std.format : format;
        logger.log(Levels.ERROR, format!(fmt)(args), exception, moduleName, functionName, fileName, lineNumber);
    }
}

unittest {
    import slf4d.test;
    synchronized (loggingTestingMutex) {
        shared TestingLoggingProvider provider = getTestingProvider();
        
        // Test formatted functions without any format specifiers.
        logF!"Testing"(Levels.INFO);
        provider.assertHasMessage("Testing");

        traceF!"Testing trace"();
        provider.assertHasMessage("Testing trace");
        debugF!"Testing debug"();
        provider.assertHasMessage("Testing debug");
        infoF!"Testing info"();
        provider.assertHasMessage("Testing info");
        warnF!"Testing warn"();
        provider.assertHasMessage("Testing warn");
        errorF!"Testing error"();
        provider.assertHasMessage("Testing error");

        resetLoggingState();
    }
}
