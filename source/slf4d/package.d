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

/** 
 * The logger factory used to obtain new Loggers wherever SLF4D is used. This
 * is considered a global variable that's shared among all threads of the
 * application, and should only be initialized once on application startup.
 *
 * Note to library developers: If your library uses SLF4D to send log messages,
 * *do not* modify this global shared factory! The end-user application decides
 * which factory it would like to use system-wide logging, and libraries simply
 * use whatever factory was chosen.
 */
private shared LoggerFactory loggerFactory;

/** 
 * The logging provider. It defaults to the default provider included in the
 * box with SLF4D, but it's intended for applications to change this via the
 * `configureLoggingProvider` function on application startup.
 */
private shared LoggingProvider loggingProvider;

/** 
 * Configures SLF4D to use the given logging provider. Call this once on
 * application startup.
 * Params:
 *   provider = The logging provider to use.
 */
public void configureLoggingProvider(shared LoggingProvider provider) {
    loggingProvider = provider;
}

/** 
 * Gets the global shared logger factory instance.
 * Returns: The logger factory.
 */
public shared(LoggerFactory) getLoggerFactory() {
    if (loggerFactory is null) {
        if (loggingProvider is null) {
            import slf4d.default_provider;
            loggerFactory = new shared DefaultProvider().defineLoggerFactory();
        } else {
            loggerFactory = loggingProvider.defineLoggerFactory();
        }
    }
    return loggerFactory;
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
