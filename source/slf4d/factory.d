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
shared class DefaultLoggerFactory : LoggerFactory {
    private shared LogHandler handler;
    private Level rootLoggingLevel;
    private ModuleLoggingLevelMapping[] moduleMappings;

    /** 
     * Constructs the factory with the given handler, and optionally a root
     * logging level.
     * Params:
     *   handler = The handler that will handle all log messages.
     *   rootLoggingLevel = The root logging level, which is the default level
     *   assigned to all Loggers produced by this factory, unless a module
     *   specific level is set.
     */
    public shared this(shared LogHandler handler, Level rootLoggingLevel = Levels.INFO) {
        this.handler = handler;
        this.rootLoggingLevel = rootLoggingLevel;
    }

    /** 
     * Sets the root logging level for this factory.
     * Params:
     *   level = The root logging level.
     */
    public shared void setRootLevel(Level level) {
        this.rootLoggingLevel = level;
    }

    /** 
     * Sets the logging level for a given module pattern.
     * Params:
     *   modulePattern = The module pattern to match against.
     *   level = The logging level to apply to Loggers whose name matches the
     *           given module pattern.
     */
    public shared void setModuleLevel(string modulePattern, Level level) {
        this.moduleMappings ~= ModuleLoggingLevelMapping(modulePattern, level);
    }

    /** 
     * Gets a Logger. The Logger's level is set according to the root logging
     * level, unless there exists a module-specific level that was set via
     * `setModuleLevel`.
     * Params:
     *   name = The logger's name, which defaults to the current module name.
     * Returns: The Logger.
     */
    public shared Logger getLogger(string name = __MODULE__) {
        import std.algorithm : startsWith;
        Level level = this.rootLoggingLevel;
        foreach (mapping; this.moduleMappings) {
            if (startsWith(name, mapping.modulePattern)) {
                level = mapping.level;
            }
        }
        return Logger(this.handler, level, name);
    }
}

/** 
 * A simple mapping struct that maps a module pattern string to a particular
 * logging level, used by the DefaultLoggerFactory to configure module-specific
 * logging levels.
 */
package struct ModuleLoggingLevelMapping {
    private string modulePattern;
    private const Level level;
}

unittest {
    import slf4d.handler;
    auto handler = new shared CachingLogHandler();
    auto f1 = new shared DefaultLoggerFactory(handler, Levels.INFO);
    Logger log1 = f1.getLogger();
    log1.debug_("Testing");
    assert(handler.messages.length == 0);
    log1.warn("Testing");
    assert(handler.messages.length == 1);
    handler.reset();

    f1.setRootLevel(Levels.TRACE);
    Logger log2 = f1.getLogger();
    log2.debug_("Testing");
    assert(handler.messages.length == 1);
    handler.reset();

    auto f2 = new shared DefaultLoggerFactory(handler);
    f2.setModuleLevel("my_module.a", Levels.DEBUG);
    f2.setModuleLevel("my_module.b", Levels.TRACE);
    Logger log3 = f2.getLogger("my_module.a");
    log3.info("Testing");
    assert(handler.messages.length == 1);
    log3.debug_("Testing debug");
    assert(handler.messages.length == 2);
    log3.trace("Testing trace");
    assert(handler.messages.length == 2);
    handler.reset();

    Logger log4 = f2.getLogger("my_module.b");
    log4.info("Testing");
    assert(handler.messages.length == 1);
    log4.info("Testing trace");
    assert(handler.messages.length == 2);
}
