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
interface LoggerFactory {
    /** 
     * Gets a logger.
     * Params:
     *   name = The name associated with the logger. This will default to the
     *          current module name, which is sufficient for most use cases.
     */
    Logger getLogger(string name = __MODULE__);
}

/** 
 * A basic LoggerFactory implementation that just creates a `Logger` with a
 * handler and pre-set logging level.
 */
class SimpleLoggerFactory : LoggerFactory {
    private LogHandler handler;
    private Level level;

    public this(LogHandler handler, Level level) {
        this.handler = handler;
        this.level = level;
    }

    Logger getLogger(string name = __MODULE__) {
        return Logger(this.handler, this.level, name);
    }
}
