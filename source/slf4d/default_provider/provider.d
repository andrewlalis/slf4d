/** 
 * Module which defines the default provider's main class.
 */
module slf4d.default_provider.provider;

import slf4d.provider;
import slf4d.default_provider.factory;
import slf4d.default_provider.handler;

/** 
 * The default provider class.
 */
class DefaultProvider : LoggingProvider {
    private shared DefaultLoggerFactory loggerFactory;
    
    /** 
     * Getter method to get this provider's internal factory. It will lazily
     * initialize the factory if it hasn't already been initialized.
     * Returns: The logger factory.
     */
    public shared shared(DefaultLoggerFactory) getLoggerFactory() {
        if (loggerFactory is null) {
            loggerFactory = new shared DefaultLoggerFactory(new shared DefaultLogHandler());
        }
        return loggerFactory;
    }
}