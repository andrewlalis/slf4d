/**
 * This module defines the `LoggerFactory`, a component that's part of a
 * LoggingProvider's implementation, and produces `Logger` instances to use at
 * runtime.
 */
module slf4d.factory;

import slf4d.logger : Logger;

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
    shared Logger getLogger(string name = __MODULE__);
}
