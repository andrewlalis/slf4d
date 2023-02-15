/**
 * This module contains extensible factory components for creating loggers.
 */
module slf4d.factory;

import slf4d.logger;
import slf4d.handler;
import slf4d.level;

/** 
 * A factory that initializes a `Logger` wherever it's needed. Generally a
 * single factory is needed for your application, and this factory will take
 * any implementation-specific options into account when building the logger.
 */
shared interface LoggerFactory {
    /** 
     * Gets a logger.
     * Params:
     *   name = The name associated with the logger. This will default to the
     *          current module name, which is sufficient for most use cases.
     */
    shared Logger getLogger(string name = __MODULE__);
}

/** 
 * A basic LoggerFactory implementation that just creates a `Logger` with a
 * handler and pre-set logging level.
 */
shared class SimpleLoggerFactory : LoggerFactory {
    private shared LogHandler handler;
    private const Level level;

    public shared this(shared LogHandler handler, Level level) {
        this.handler = handler;
        this.level = level;
    }

    shared Logger getLogger(string name = __MODULE__) {
        return Logger(this.handler, this.level, name);
    }
}
