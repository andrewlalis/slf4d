module slf4d.testing_provider;

import slf4d.factory;
import slf4d.provider;
import slf4d.level;
import slf4d.logger;
import slf4d.handler : CachingLogHandler;

/** 
 * A convenient logging provider to use in unit tests, which uses a factory
 * that creates Loggers that send messages to a `CachingLogHandler` for
 * inspection.
 */
class TestingLoggingProvider : LoggingProvider {
    /** 
     * The logger factory that this provider uses.
     */
    public shared TestingLoggerFactory factory = new TestingLoggerFactory();

    public shared shared(TestingLoggerFactory) getLoggerFactory() {
        return this.factory;
    }

    /** 
     * Convenience method to get the list of log messages that have been logged
     * to this provider since the last time it was reset.
     * Returns: The messages that have been logged to this provider.
     */
    public shared LogMessage[] messages() {
        return this.factory.handler.getMessages();
    }

    /** 
     * Convenience method to clear this provider's cached list of messages.
     */
    public shared void reset() {
        this.factory.handler.reset();
    }
}

/** 
 * A convenient LoggerFactory implementation for testing logging in an isolated
 * manner.
 */
class TestingLoggerFactory : LoggerFactory {
    public shared CachingLogHandler handler;
    public Level logLevel = Levels.TRACE;

    shared Logger getLogger(string name = __MODULE__) {
        return Logger(this.handler, this.logLevel, name);
    }
}

unittest {
    import slf4d;

    TestingLoggingProvider p = new shared TestingLoggingProvider();
    assert(p.messages.length == 0);
    configureLoggingProvider(p);

    auto log = getLogger();
    log.info("Testing");
    assert(p.messages.length == 1);
    p.reset();
    assert(p.messages.length == 0);
}