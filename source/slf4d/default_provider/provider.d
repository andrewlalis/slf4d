/** 
 * Module which defines the default provider's main class.
 */
module slf4d.default_provider.provider;

import slf4d.provider;
import slf4d.level;
import slf4d.handler;
import slf4d.default_provider.factory;
import slf4d.default_provider.handler;

import std.typecons;

/** 
 * The default provider class.
 */
class DefaultProvider : LoggingProvider {
    private shared DefaultLoggerFactory loggerFactory;

    /** 
     * Constructs the default provider.
     * Params:
     *   colored = Whether to color output.
     *   rootLoggingLevel = The root logging level for all Loggers created by
     *     this provider's factory.
     *   logFileDir = A directory in which to write log files. If `null`, no
     *     files are written.
     */
    public shared this(
        bool colored = false,
        Level rootLoggingLevel = Levels.INFO,
        string logFileDir = null
    ) {
        shared LogHandler[] handlers = [new shared DefaultLogHandler(colored)];
        if (logFileDir !is null && logFileDir.length > 0) {
            import slf4d.writer;
            handlers ~= new shared SerializingLogHandler(
                new DefaultStringLogSerializer(false),
                new RotatingFileLogWriter(logFileDir)
            );
        }
        auto baseHandler = new shared MultiLogHandler(handlers);
        this.loggerFactory = new shared DefaultLoggerFactory(baseHandler, rootLoggingLevel);
    }
    
    /** 
     * Getter method to get this provider's internal factory. It will lazily
     * initialize the factory if it hasn't already been initialized.
     * Returns: The logger factory.
     */
    public shared shared(DefaultLoggerFactory) getLoggerFactory() {
        return this.loggerFactory;
    }
}
