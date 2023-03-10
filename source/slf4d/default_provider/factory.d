/** 
 * Module containing the default logger factory and associated components.
 */
module slf4d.default_provider.factory;

import slf4d;
import core.sync.rwmutex;

/** 
 * A basic LoggerFactory implementation that just creates a `Logger` with a
 * handler and pre-set logging level.
 */
class DefaultLoggerFactory : LoggerFactory {
    private shared LogHandler handler;
    private Level rootLoggingLevel;
    private ModuleLoggingLevelMapping[] moduleMappings;
    private shared ReadWriteMutex mutex;

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
        this.mutex = new shared ReadWriteMutex();
    }

    /** 
     * Sets the root logging level for this factory.
     * Params:
     *   level = The root logging level.
     */
    public shared void setRootLevel(Level level) {
        synchronized(this.mutex.writer) {
            this.rootLoggingLevel = level;
        }
    }

    /** 
     * Sets the logging level for a given module pattern.
     * Params:
     *   modulePattern = The module pattern to match against.
     *   level = The logging level to apply to Loggers whose name matches the
     *           given module pattern.
     */
    public shared void setModuleLevel(string modulePattern, Level level) {
        synchronized(this.mutex.writer) {
            this.moduleMappings ~= ModuleLoggingLevelMapping(modulePattern, level);
        }
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
        synchronized(this.mutex.reader) {
            Level level = this.rootLoggingLevel;
            foreach (mapping; this.moduleMappings) {
                if (startsWith(name, mapping.modulePattern)) {
                    level = mapping.level;
                }
            }
            return Logger(this.handler, level, name);
        }
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
    assert(handler.getMessages().length == 0);
    log1.warn("Testing");
    assert(handler.getMessages().length == 1);
    handler.reset();

    f1.setRootLevel(Levels.TRACE);
    Logger log2 = f1.getLogger();
    log2.debug_("Testing");
    assert(handler.getMessages().length == 1);
    handler.reset();

    auto f2 = new shared DefaultLoggerFactory(handler);
    f2.setModuleLevel("my_module.a", Levels.DEBUG);
    f2.setModuleLevel("my_module.b", Levels.TRACE);
    Logger log3 = f2.getLogger("my_module.a");
    log3.info("Testing");
    assert(handler.getMessages().length == 1);
    log3.debug_("Testing debug");
    assert(handler.getMessages().length == 2);
    log3.trace("Testing trace");
    assert(handler.getMessages().length == 2);
    handler.reset();

    Logger log4 = f2.getLogger("my_module.b");
    log4.info("Testing");
    assert(handler.getMessages().length == 1);
    log4.info("Testing trace");
    assert(handler.getMessages().length == 2);
}