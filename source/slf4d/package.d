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
 * Configures SLF4D to use the given logging provider. Call this once on
 * application startup. In order to improve runtime performance, access to this
 * provider is **not** synchronized, so attempts to reconfigure the logging
 * provider after startup may lead to undefined behavior.
 * Params:
 *   provider = The logging provider to use. If `null` is given then SFL4D will
 *              use its built-in `NoOpProvider` from `slf4d.noop_provider`.
 */
public void configureLoggingProvider(shared LoggingProvider provider) {
    if (provider is null) {
        loggingProvider = new shared NoOpProvider();
    } else {
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

// Compile-time generated general-purpose convenient log functions that get a
// logger via shared provider.
// Note that we can define the mixin's `loggerRef` template argument using
// `getLogger(moduleName)` since every function provides a `moduleName` arg.
import slf4d.log_functions : LogFunctionsMixin, STANDARD_LOG_FUNCTIONS;
mixin LogFunctionsMixin!(STANDARD_LOG_FUNCTIONS, q{getLogger(moduleName)});
