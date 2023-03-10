/**
 * The main module of SLF4D, which publicly imports all of the components that
 * are typically needed in an application for logging. It also defines the
 * global shared `loggerFactory` from which all application loggers are
 * obtained.
 */
module slf4d;

public import slf4d.logger;
public import slf4d.factory;
public import slf4d.handler;
public import slf4d.level;

// Below the public imports, we define some common global state for the SLF4D
// logging system.

import slf4d.provider;
import slf4d.default_provider;
import slf4d.noop_provider;
import core.atomic;

/** 
 * The logging provider. It defaults to the default provider included in the
 * box with SLF4D, but it's intended for applications to change this via the
 * `configureLoggingProvider` function on application startup.
 */
private shared LoggingProvider loggingProvider;

/** 
 * An internal flag that's set once the logging provider is configured, and
 * used to issue warnings if the provider is re-configured when it shouldn't be.
 */
private shared bool loggingProviderSet = false;

/** 
 * Configures SLF4D to use the given logging provider. Call this once on
 * application startup. In order to improve runtime performance, access to this
 * provider is **not** synchronized, so attempts to reconfigure the logging
 * provider after startup may lead to undefined behavior.
 * Params:
 *   provider = The logging provider to use. If `null` is given then SFL4D will
 *              use its built-in `NoOpProvider` from `slf4d.noop_provider`.
 */
public void configureLoggingProvider(shared LoggingProvider provider) {
    bool alreadySet = atomicLoad(loggingProviderSet);
    if (alreadySet) {
        Logger logger = getLogger();
        static immutable string fmt = "The SLF4D logging provider has already been " ~
        "configured with the provider %s. Re-configuring the logging provider " ~
        "after it has already been configured is not supported, and may have " ~
        "unintended consequences.";
        logger.warnF!(fmt)(loggingProvider);
    }
    if (provider is null) {
        loggingProvider = new shared NoOpProvider();
    } else {
        loggingProvider = provider;
    }
    atomicStore(loggingProviderSet, true);
}

/** 
 * Gets the global shared logger factory instance. If no provider has been
 * explicitly configured, the `slf4d.default_provider` module's
 * `DefaultProvider` is used.
 * Returns: The logger factory.
 */
public shared(LoggerFactory) getLoggerFactory() {
    if (loggingProvider is null) {
        loggingProvider = new shared DefaultProvider();
    }
    return loggingProvider.getLoggerFactory();
}

/** 
 * Gets a Logger using the configured logger factory. This is a shortcut for
 * `getLoggerFactory().getLogger()`.
 * Params:
 *   name = The name of the logger. Defaults to the name of the module where
 *          this function is invoked.
 * Returns: The logger.
 */
public Logger getLogger(string name = __MODULE__) {
    return getLoggerFactory().getLogger(name);
}

// Below this line are convenience log functions that delegate to `getLogger()`.
// -----------------------------------------------------------------------------

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

public void logF(string fmt, T...)(
    Level level,
    T args,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    getLogger(moduleName).logF!(fmt, T)(level, args, exception, moduleName, functionName, fileName, lineNumber);
}

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

public void trace(
    Exception exception,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.TRACE, exception, moduleName, functionName, fileName, lineNumber);
}

public void traceF(string fmt, T...)(
    T args,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    logF!(fmt, T)(Levels.TRACE, args, exception, moduleName, functionName, fileName, lineNumber);
}

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

public void debug_(
    Exception exception,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.DEBUG, exception, moduleName, functionName, fileName, lineNumber);
}

public void debugF(string fmt, T...)(
    T args,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    logF!(fmt, T)(Levels.DEBUG, args, exception, moduleName, functionName, fileName, lineNumber);
}

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

public void info(
    Exception exception,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.INFO, exception, moduleName, functionName, fileName, lineNumber);
}

public void infoF(string fmt, T...)(
    T args,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    logF!(fmt, T)(Levels.INFO, args, exception, moduleName, functionName, fileName, lineNumber);
}

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

public void warn(
    Exception exception,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.WARN, exception, moduleName, functionName, fileName, lineNumber);
}

public void warnF(string fmt, T...)(
    T args,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    logF!(fmt, T)(Levels.WARN, args, exception, moduleName, functionName, fileName, lineNumber);
}

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

public void error(
    Exception exception,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    log(Levels.ERROR, exception, moduleName, functionName, fileName, lineNumber);
}

public void errorF(string fmt, T...)(
    T args,
    Exception exception = null,
    string moduleName = __MODULE__,
    string functionName = __PRETTY_FUNCTION__,
    string fileName = __FILE__,
    size_t lineNumber = __LINE__
) {
    logF!(fmt, T)(Levels.ERROR, args, exception, moduleName, functionName, fileName, lineNumber);
}



/** 
 * Some components that are only available during testing, which are needed
 * for checking and mutating the global state in ways that are not permitted
 * in normal operation.
 */
version(unittest) {
    import core.sync.mutex;

    /** 
     * A shared mutex you should synchronize on if you're testing anything
     * involving the global shared logging provider.
     */
    public shared Mutex loggingTestingMutex;

    static this() {
        loggingTestingMutex = new shared Mutex();
    }

    /** 
     * Asserts that the logging state is not yet initialized.
     */
    public void assertNotInitialized() {
        import std.format : format;
        assert(
            loggingProvider is null,
            format!"loggingProvider is not null when it shouldn't have been initialized yet: %s"(loggingProvider)
        );
        assert(
            loggingProviderSet == false,
            "loggingProviderSet is true the logging provider hasn't been configured yet."
        );
    }

    /** 
     * Asserts that the logging state has been initialized with a given
     * provider class.
     */
    public void assertInitialized(ProviderClass)() {
        import std.format : format;
        import std.traits;
        assert(
            loggingProvider !is null,
            "loggingProvider is null when it should have been initialized."
        );
        assert(
            loggingProviderSet,
            "loggingProviderSet is false when the logging provider should have been initialized."
        );
        assert(
            cast(ProviderClass) loggingProvider,
            format!"loggingProvider is not of the expected class %s, instead it is %s"(
                fullyQualifiedName!ProviderClass,
                loggingProvider
            )
        );
    }

    /** 
     * Resets the logging state. Call this after your test, if you configured
     * the global shared logging provider.
     */
    public void resetLoggingState() {
        loggingProvider = null;
        loggingProviderSet = false;
    }
}

// Test that a warning is issued if the provider is configured more than once.
unittest {
    import slf4d.testing_provider;
    synchronized(loggingTestingMutex) {
        assertNotInitialized();
        auto provider = new shared TestingLoggingProvider();
        configureLoggingProvider(provider);
        assert(loggingProviderSet == true, "loggingProviderSet is not true after configuring the logging provider.");
        // Now try and configure it again. A warning message should be produced.
        configureLoggingProvider(provider);
        assertInitialized!TestingLoggingProvider();
        assert(provider.messageCount == 1 && provider.messageCount(Levels.WARN) == 1);
        resetLoggingState();
    }
}

// Test that if `null` is given, the NoOpProvider is used.
unittest {
    synchronized(loggingTestingMutex) {
        assertNotInitialized();
        configureLoggingProvider(null);
        assertInitialized!NoOpProvider();
        resetLoggingState();
    }
}
