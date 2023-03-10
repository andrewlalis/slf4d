/**
 * An SLF4D provider that is intended to be used for testing. The provider
 * class, `TestingLoggingProvider`, includes some convenience methods to
 * inspect the log messages generated while it's active.
 */
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
    public shared TestingLoggerFactory factory;

    public shared this() {
        this.factory = new shared TestingLoggerFactory();
    }

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

    /** 
     * Gets the number of messages that have been logged.
     * Returns: The number of messages that have been logged.
     */
    public shared size_t messageCount() {
        return this.factory.handler.messageCount;
    }

    /** 
     * Gets the number of messages that have been logged at a given level.
     * Params:
     *   levelFilter = The level to filter by.
     * Returns: The number of messages that have been logged at the given level.
     */
    public shared size_t messageCount(Level levelFilter) {
        import std.algorithm : count;
        return cast(size_t) this.messages().count!(m => m.level == levelFilter);
    }
}

/** 
 * A convenient LoggerFactory implementation for testing logging in an isolated
 * manner.
 */
class TestingLoggerFactory : LoggerFactory {
    public shared CachingLogHandler handler;
    public Level logLevel = Levels.TRACE;

    public shared this() {
        this.handler = new shared CachingLogHandler();
    }

    shared Logger getLogger(string name = __MODULE__) {
        return Logger(this.handler, this.logLevel, name);
    }
}

unittest {
    import slf4d;

    auto p = new shared TestingLoggingProvider();
    assert(p.messages.length == 0);
    

    auto log = p.getLoggerFactory().getLogger();
    log.info("Testing");
    assert(p.messages.length == 1);
    p.reset();
    assert(p.messages.length == 0);
}