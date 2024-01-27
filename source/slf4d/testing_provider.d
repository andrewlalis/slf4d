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
    public TestingLoggerFactory factory;

    public this() {
        this.factory = new TestingLoggerFactory();
    }

    public TestingLoggerFactory getLoggerFactory() {
        return this.factory;
    }

    /** 
     * Convenience method to get the list of log messages that have been logged
     * to this provider since the last time it was reset.
     * Returns: The messages that have been logged to this provider.
     */
    public LogMessage[] messages() {
        return this.factory.handler.getMessages();
    }

    /** 
     * Convenience method to clear this provider's cached list of messages.
     */
    public void reset() {
        this.factory.handler.reset();
    }

    /** 
     * Gets the number of messages that have been logged.
     * Returns: The number of messages that have been logged.
     */
    public size_t messageCount() {
        return this.factory.handler.messageCount;
    }

    /** 
     * Gets the number of messages that have been logged at a given level.
     * Params:
     *   levelFilter = The level to filter by.
     * Returns: The number of messages that have been logged at the given level.
     */
    public size_t messageCount(Level levelFilter) {
        import std.algorithm : count;
        return cast(size_t) this.messages().count!(m => m.level == levelFilter);
    }

    /** 
     * Asserts that this provider has exactly an expected amount of messages.
     * Params:
     *   expected = The expected message count.
     */
    public void assertMessageCount(size_t expected) {
        import std.format : format;
        size_t actual = this.messageCount();
        assert(actual == expected, format!"Actual message count %d does not match expected %d."(actual, expected));
    }

    /** 
     * Asserts that this provider has exactly an expected amount of messages
     * at the given logging level.
     * Params:
     *   level = The level to filter by.
     *   expected = The expected message count.
     */
    public void assertMessageCount(Level level, size_t expected) {
        import std.format : format;
        size_t actual = this.messageCount(level);
        assert(
            actual == expected,
            format!"Actual message count %d for level %s does not match expected %d."(actual, level.name, expected)
        );
    }

    /** 
     * Asserts that this provider has no cached messages.
     */
    public void assertNoMessages() {
        this.assertMessageCount(0);
    }

    /** 
     * Asserts that this provider has no cached messages at the given logging
     * level.
     * Params:
     *   level = The level to filter by.
     */
    public void assertNoMessages(Level level) {
        this.assertMessageCount(level, 0);
    }

    /** 
     * Asserts that this provider has a cached log message that satisfies the
     * given boolean delegate function.
     * Params:
     *   dg = A delegate function that takes a log message, and returns true if
     *        the message matches, or false otherwise.
     *   message = The message to show if no matching log messages are found.
     */
    public void assertHasMessage(
        bool delegate(LogMessage) dg,
        string message = "No matching log message for delegate function."
    ) {
        import std.algorithm : any;
        assert(any!(m => dg(m))(this.messages()), message);
    }

    /** 
     * Asserts that this provider has a cached log message with the given
     * string message.
     * Params:
     *   expected = The expected string message.
     *   caseSensitive = Whether to do a case-sensitive search. True by default.
     */
    public void assertHasMessage(string expected, bool caseSensitive = true) {
        import std.format : format;
        import std.string : toLower;
        this.assertHasMessage(
            (m) {
                if (!caseSensitive) {
                    return toLower(m.message) == toLower(expected);
                }
                return m.message == expected;
            },
            format!"Cached log messages do not contain expected message \"%s\"."(expected)
        );
    }

    /** 
     * Asserts that this provider has a cached log message with the given level.
     * Params:
     *   level = The logging level to look for.
     */
    public void assertHasMessage(Level level) {
        import std.format : format;
        this.assertHasMessage(
            m => m.level == level,
            format!"No cached log message with level %s."(level.name)
        );
    }
}

/** 
 * A convenient LoggerFactory implementation for testing logging in an isolated
 * manner.
 */
class TestingLoggerFactory : LoggerFactory {
    public CachingLogHandler handler;
    public Level logLevel = Levels.TRACE;

    public this() {
        this.handler = new CachingLogHandler();
    }

    Logger getLogger(string name = __MODULE__) {
        return Logger(this.handler, this.logLevel, name);
    }
}

unittest {
    import slf4d;

    auto p = new TestingLoggingProvider();
    assert(p.messages.length == 0);
    p.assertMessageCount(0);
    p.assertNoMessages();

    auto log = p.getLoggerFactory().getLogger();
    log.info("Testing");
    assert(p.messages.length == 1);
    p.assertMessageCount(1);
    p.assertMessageCount(Levels.INFO, 1);
    p.assertMessageCount(Levels.WARN, 0);
    p.assertNoMessages(Levels.ERROR);
    p.assertHasMessage("Testing");
    p.assertHasMessage("testing", false);
    p.reset();
    assert(p.messages.length == 0);
}