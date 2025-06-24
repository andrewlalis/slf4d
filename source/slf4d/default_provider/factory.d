/** 
 * Module containing the default logger factory and associated components.
 */
module slf4d.default_provider.factory;

import slf4d;
import std.regex;
import core.sync.rwmutex;

/** 
 * A basic LoggerFactory implementation that just creates a `Logger` with a
 * handler and pre-set logging level. It also includes methods for defining
 * custom logging levels for individual module patterns, so that you can, for
 * example, only show debug messages from a single module.
 */
shared class DefaultLoggerFactory : LoggerFactory {
    private LogHandler handler;
    private Level rootLoggingLevel;
    private ModuleLoggingLevelMapping[] moduleMappings;
    private ReadWriteMutex mutex;

    /** 
     * Constructs the factory with the given handler, and optionally a root
     * logging level.
     * Params:
     *   handler = The handler that will handle all log messages.
     *   rootLoggingLevel = The root logging level, which is the default level
     *   assigned to all Loggers produced by this factory, unless a module
     *   specific level is set.
     */
    public this(shared LogHandler handler, Level rootLoggingLevel = Levels.INFO) {
        this.handler = handler;
        this.rootLoggingLevel = rootLoggingLevel;
        this.mutex = new shared ReadWriteMutex();
    }

    /** 
     * Sets the root logging level for this factory.
     * Params:
     *   level = The root logging level.
     */
    public void setRootLevel(Level level) {
        synchronized(this.mutex.writer) {
            this.rootLoggingLevel = level;
        }
    }

    /** 
     * Sets the logging level for a given module pattern regular expression.
     * When this factory prepares a logger for a given module (or logger name
     * if the developer has defined a custom name), it will give that logger a
     * logging level according to the configured `rootLoggingLevel` of this
     * factory. Then, if it finds a module pattern set using this function, it
     * will use the declared level instead. Module patterns are searched in the
     * order that they're defined.
     * Params:
     *   modulePattern = The module pattern to match against. This is compiled
     *                   as a regular expression.
     *   level = The logging level to apply to Loggers whose name matches the
     *           given module pattern.
     */
    public void setModuleLevel(string modulePattern, Level level) {
        synchronized(this.mutex.writer) {
            auto safeUnsharedMappings = cast(ModuleLoggingLevelMapping[]*) &this.moduleMappings;
            *safeUnsharedMappings ~= ModuleLoggingLevelMapping(
                regex(modulePattern),
                level
            );
        }
    }

    /** 
     * Sets the logging level for a given module prefix. This is a convenience
     * wrapper around `setModuleLevel`, which simply prepares a regular
     * expression that matches the beginning of a logger's module (or name)
     * with the given `modulePrefix`.
     * Params:
     *   modulePrefix = The module's prefix.
     *   level = The logging level to apply to Loggers whose name matches the
     *           given module prefix.
     */
    public void setModuleLevelPrefix(string modulePrefix, Level level) {
        string pattern = "^" ~ replaceAll(modulePrefix, regex("\\."), "\\.") ~ ".*";
        this.setModuleLevel(pattern, level);
    }

    /** 
     * Gets a Logger. The Logger's level is set according to the root logging
     * level, unless there exists a module-specific level that was set via
     * `setModuleLevel`.
     * Params:
     *   name = The logger's name, which defaults to the current module name.
     * Returns: The Logger.
     */
    public Logger getLogger(string name = __MODULE__) shared {
        import std.algorithm : startsWith;
        synchronized(this.mutex.reader) {
            Level level = this.rootLoggingLevel;
            auto safeUnsharedMappings = cast(ModuleLoggingLevelMapping[]*) &this.moduleMappings;
            foreach (mapping; *safeUnsharedMappings) {
                if (matchFirst(name, mapping.modulePattern)) {
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
    private Regex!char modulePattern;
    private immutable Level level;
}

unittest {
    import slf4d.handler;
    auto handler = new CachingLogHandler();

    auto f1 = new DefaultLoggerFactory(handler, Levels.INFO);
    Logger log1 = f1.getLogger();
    log1.debug_("Testing");
    assert(handler.messageCount() == 0);
    log1.warn("Testing");
    assert(handler.messageCount() == 1);
    handler.reset();

    f1.setRootLevel(Levels.TRACE);
    Logger log2 = f1.getLogger();
    log2.debug_("Testing");
    assert(handler.messageCount() == 1);
    handler.reset();

    // Test setModuleLevel regular expression matching.
    auto f2 = new DefaultLoggerFactory(handler, Levels.WARN);
    f2.setModuleLevel("^my_module\\.a$", Levels.DEBUG);
    f2.setModuleLevel("^my_module\\.b$", Levels.TRACE);
    Logger log3 = f2.getLogger("my_module.a"); // First a logger that matches the first module level.
    log3.info("Testing");
    assert(handler.messageCount() == 1);
    log3.debug_("Testing debug");
    assert(handler.messageCount() == 2);
    log3.trace("Testing trace. This should not be added to the messages.");
    assert(handler.messageCount() == 2);
    handler.reset();

    Logger log4 = f2.getLogger("my_module.b"); // Then a logger that matches the second module level.
    log4.info("Testing");
    assert(handler.messageCount() == 1);
    log4.info("Testing trace");
    assert(handler.messageCount() == 2);
    handler.reset();

    Logger log5 = f2.getLogger("other_module"); // Finally, a logger that shouldn't match either, and uses root level.
    log5.debug_("This should not appear.");
    assert(handler.messageCount() == 0);
    log5.trace("This should also not appear.");
    assert(handler.messageCount() == 0);
    log5.warn("This should appear!");
    assert(handler.messageCount() == 1);
    handler.reset();

    // Test setModuleLevelPrefix matching.
    auto f3 = new DefaultLoggerFactory(handler, Levels.WARN);
    f3.setModuleLevelPrefix("first_mod.second_mod", Levels.TRACE);
    f3.setModuleLevelPrefix("first_mod.third_mod.", Levels.DEBUG);
    Logger log6 = f3.getLogger("first_mod.second_mod"); // A logger that matches the first module level.
    log6.trace("This should appear!");
    assert(handler.messageCount() == 1);
    handler.reset();

    Logger log7 = f3.getLogger("first_mod.second_mod.another"); // A logger that still matches the first module.
    log7.trace("This should appear!");
    assert(handler.messageCount() == 1);
    handler.reset();

    Logger log8 = f3.getLogger("first_mod.third_mod.a"); // A logger that matches the second module.
    log8.trace("This should not appear.");
    assert(handler.messageCount() == 0);
    log8.debug_("This should appear!");
    assert(handler.messageCount() == 1);
    handler.reset();

    Logger log9 = f3.getLogger("other_module"); // A logger that doesn't match any module levels.
    log9.trace("This should not appear.");
    log9.info("This should also not appear.");
    assert(handler.messageCount() == 0);
    log9.error("This should appear!");
    assert(handler.messageCount() == 1);
    handler.reset();
}