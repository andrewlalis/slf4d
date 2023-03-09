/** 
 * Module which defines the default provider's main class.
 */
module slf4d.default_provider.provider;

import slf4d.provider;
import slf4d.level;
import slf4d.default_provider.factory;
import slf4d.default_provider.handler;

/** 
 * The default provider class.
 */
class DefaultProvider : LoggingProvider {
    private shared DefaultLoggerFactory loggerFactory;
    private shared DefaultLogHandler handler;

    /** 
     * Constructs the default provider.
     * Params:
     *   colored = Whether to color output.
     *   rootLoggingLevel = The root logging level for all Loggers created by
     *                      this provider's factory.
     */
    public shared this(bool colored = true, Level rootLoggingLevel = Levels.INFO) {
        this.handler = new shared DefaultLogHandler(colored);
        this.loggerFactory = new shared DefaultLoggerFactory(this.handler, rootLoggingLevel);
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