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
import core.sync.rwmutex;

/** 
 * The logger factory used to obtain new Loggers wherever SLF4D is used. This
 * is supplied by the configured LoggingProvider.
 */
private shared LoggerFactory loggerFactory;

/** 
 * The logging provider. It defaults to the default provider included in the
 * box with SLF4D, but it's intended for applications to change this via the
 * `configureLoggingProvider` function on application startup.
 */
private shared LoggingProvider loggingProvider;

/** 
 * A mutex used to control multi-threaded access to the logging provider.
 */
private shared ReadWriteMutex loggingProviderMutex;

static this() {
    loggingProviderMutex = new shared ReadWriteMutex();
}

/** 
 * Configures SLF4D to use the given logging provider. Call this once on
 * application startup.
 * Params:
 *   provider = The logging provider to use.
 */
public void configureLoggingProvider(shared LoggingProvider provider) {
    synchronized(loggingProviderMutex.writer) {
        loggingProvider = provider;
    }
}

/** 
 * Gets the global shared logger factory instance. If no provider has been
 * explicitly configured, the `slf4d.default_provider` module's
 * `DefaultProvider` is used.
 * Returns: The logger factory.
 */
public shared(LoggerFactory) getLoggerFactory() {
    synchronized(loggingProviderMutex.reader) {
        if (loggingProvider is null) {
            synchronized(loggingProviderMutex.writer) {
                loggingProvider = new shared DefaultProvider();
            }
        }
        return loggingProvider.getLoggerFactory();
    }
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
