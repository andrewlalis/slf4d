/**
 * The handler module defines the `LogHandler` interface, as well as several
 * simple handler implementations that can be used or extended by SLF4D
 * providers.
 */
module slf4d.handler;

import slf4d.logger : LogMessage;
import slf4d.level;

/**
 * The interface for any component that consumes log messages generated by a
 * `Logger`. Only messages whose level is greater than or equal to the logger's
 * level will be sent to handlers. For example, a Logger configured at an INFO
 * log level will send INFO, WARN, and ERROR messages, but not DEBUG or TRACE.
 *
 * Each Logger has a single root LogHandler instance. This "root handler" can
 * be a very simple handler that sends messages to stdout, or it could be a
 * more complex composition of handlers to distribute logs to various locations
 * according to filtering logic.
 */
shared interface LogHandler {
    /** 
     * Handles a log message.
     * Params:
     *   msg = The log message that was generated.
     */
    void handle(immutable LogMessage msg);
}

/**
 * A log handler that serializes incoming messages, and uses one or more
 * `LogWriter` instances to write the serialized messages to some output
 * resources, like the console, files, or network devices.
 */
shared class SerializingLogHandler : LogHandler {
    import slf4d.writer : LogSerializer, LogWriter;

    private LogSerializer serializer;
    private LogWriter[] writers;

    public this(shared LogSerializer serializer, shared LogWriter[] writers) {
        this.serializer = serializer;
        this.writers = writers;
    }

    void handle(immutable LogMessage msg) {
        import std.stdio;
        try {
            string serialized = this.serializer.serialize(msg);
            foreach (writer; this.writers) {
                try {
                    writer.write(msg, serialized);
                } catch (Exception e) {
                    stderr.writefln!"Failed to write log message: %s"(e.msg);
                }
            }
        } catch (Exception e) {
            stderr.writefln!"Failed to serialize log message: %s"(e.msg);
        }
    }
}

unittest {
    import slf4d.writer;
    import slf4d.logger;

    class TestSerializer : LogSerializer {
        string serialize(immutable LogMessage msg) shared {
            return msg.message;
        }
    }

    class TestWriter : LogWriter {
        string[] messages;
        void write(immutable LogMessage _, string serializedMessage) shared {
            messages ~= serializedMessage;
        }
    }

    auto writer = new shared TestWriter();
    auto writer2 = new shared TestWriter();
    auto handler = new SerializingLogHandler(
        new shared TestSerializer(),
        [writer, writer2]
    );
    Logger logger = Logger(handler);
    logger.info("Testing");
    logger.warn("This is another message.");
    assert(writer.messages.length == 2);
    assert(writer.messages[0] == "Testing");
    assert(writer.messages[1] == "This is another message.");
    assert(writer2.messages.length == 2);
    assert(writer2.messages[0] == "Testing");
    assert(writer2.messages[1] == "This is another message.");
}

/**
 * A log handler that discards all messages. Useful for testing.
 */
class DiscardingLogHandler : LogHandler {
    public void handle(immutable LogMessage _) shared {
        // Do nothing.
    }
}

/**
 * A log handler that simply appends all messages it receives to an internal
 * array. This can be useful for testing, but should not be used for general
 * runtime logging due to the need to synchronize access to the internal
 * message cache.
 */
shared class CachingLogHandler : LogHandler {
    /**
     * The internal cache of messages.
     */
    private LogMessage[] messages;

    /**
     * "Handles" a log message by appending it to this handler's internal list
     * of messages, for later inspection.
     * Params:
     *   msg = The message to handle.
     */
    public void handle(immutable LogMessage msg) shared {
        synchronized(this) {
            this.messages ~= msg;
        }
    }

    /**
     * Resets this handler's internal message cache to an empty list.
     */
    public void reset() {
        synchronized(this) {
            this.messages = [];
        }
    }

    /**
     * Gets an immutable duplication of the list of messages this handler has
     * handled since the last `reset()` call.
     * Returns: The list of messages.
     */
    public LogMessage[] getMessages() {
        synchronized(this) {
            return cast(LogMessage[]) messages.idup;
        }
    }

    /**
     * Gets the number of messages that this handler has handled since the last
     * `reset()` call.
     * Returns: The number of messages.
     */
    public size_t messageCount() {
        synchronized(this) {
            return messages.length;
        }
    }

    /**
     * Determines if no messages have been logged since the last time `reset()`
     * was called.
     * Returns: True if there are no messages, or false otherwise.
     */
    public bool empty() {
        return messageCount == 0;
    }
}

unittest {// Test basic functionality.
    import slf4d.logger : Logger;
    auto handler = new CachingLogHandler();
    auto logger = Logger(handler);
    assert(handler.getMessages().length == 0);
    logger.info("Hello world!");
    assert(handler.getMessages().length == 1);
}

unittest {// Test thread-safety.
    import core.thread;
    import slf4d.logger : Logger;
    CachingLogHandler handler = new CachingLogHandler();
    Thread[] threads;
    for (int i = 0; i < 10; i++) {
        threads ~= new Thread({
            Logger logger = Logger(handler);
            for (int j = 0; j < 100; j++) {
                logger.infoF!"Message from thread %s: %d"(Thread.getThis().name, j);
            }
        });
    }
    foreach (t; threads) t.start();
    foreach (t; threads) t.join();
    // Check that all messages were logged.
    assert(handler.messageCount() == 1000);
}

/**
 * A log handler that simply passes any log message it receives to a list of
 * other handlers. Note that handlers should only be added at application
 * startup, because the `handle` method is not synchronized to improve
 * performance.
 */
shared class MultiLogHandler : LogHandler {
    private shared(LogHandler)[] handlers;

    /**
     * Constructs this multi-log handler using the given list of sub-handlers.
     * Params:
     *   handlers = The handlers that should each handle every message this
     *              multi-handler receives.
     */
    public this(shared(LogHandler)[] handlers) {
        this.handlers = handlers;
    }

    /**
     * Adds a handler to this multi-handler's list of handlers.
     * Params:
     *   handler = The handler to add.
     * Returns: A reference to this multi-handler.
     */
    public MultiLogHandler addHandler(shared(LogHandler) handler) {
        this.handlers ~= handler;
        return this;
    }

    /**
     * Handles a log message by calling each of its sub-handlers' `handle`
     * methods on it.
     * Params:
     *   msg = The message to handle.
     */
    public void handle(immutable LogMessage msg) shared {
        foreach (handler; handlers) {
            handler.handle(msg);
        }
    }
}

unittest {
    import slf4d.logger : Logger;
    auto h1 = new CachingLogHandler();
    auto h2 = new CachingLogHandler();
    auto multiHandler = new MultiLogHandler([h1, h2]);
    auto logger = Logger(multiHandler);
    logger.info("Hello world!");
    assert(h1.getMessages().length == 1);
    assert(h2.getMessages().length == 1);
}

/**
 * A handler that applies a filter to log messages, and only passes messages to
 * its internal handler if the filter returns `true`.
 */
shared class FilterLogHandler : LogHandler {
    private bool function (LogMessage) filterFunction;
    private LogHandler handler;

    public this(shared(LogHandler) handler, bool function (LogMessage) filterFunction) {
        this.handler = handler;
        this.filterFunction = filterFunction;
    }

    void handle(immutable LogMessage msg) {
        if (this.filterFunction(msg)) {
            this.handler.handle(msg);
        }
    }
}

unittest {
    import slf4d.logger : Logger;
    auto baseHandler = new CachingLogHandler();
    auto filterHandler = new FilterLogHandler(
        baseHandler,
        (msg) {
            return msg.message.length > 10;
        }
    );
    Logger logger = Logger(filterHandler);
    logger.info("Testing");
    assert(baseHandler.getMessages().length == 0);
    logger.info("This is a long string!");
    assert(baseHandler.getMessages().length == 1);
}

/**
 * A handler that sends log messages to different handlers depending on the
 * level of the message. For example, you could create a level-mapped log
 * handler that sends INFO messages to stdout, but sends ERROR messages to
 * an email notification service.
 */
shared class LevelMappedLogHandler : LogHandler {

    private static struct LevelRange {
        public const int minValue;
        public const bool hasMinValue;
        public const int maxValue;
        public const bool hasMaxValue;

        public static LevelRange infinite() {
            return LevelRange(-1, false, -1, false);
        }

        public static LevelRange of(int minValue, int maxValue) {
            return LevelRange(minValue, true, maxValue, true);
        }

        public static LevelRange of(int value) {
            return LevelRange(value, true, value, true);
        }

        public static LevelRange ofMin(int minValue) {
            return LevelRange(minValue, true, -1, false);
        }

        public static LevelRange ofMax(int maxValue) {
            return LevelRange(-1, false, maxValue, true);
        }
    }

    private static struct Mapping {
        public const LevelRange range;
        public shared(LogHandler) handler;
    }

    private Mapping[] mappings;

    public void addLevelMapping(Level level, shared(LogHandler) handler) {
        this.mappings ~= cast(shared(Mapping)) Mapping(LevelRange.of(level.value), handler);
    }

    public void addRangeLevelMapping(Level minLevel, Level maxLevel, shared(LogHandler) handler) {
        if (minLevel.value > maxLevel.value) {
            Level tmp = minLevel;
            minLevel = maxLevel;
            maxLevel = tmp;
        }
        this.mappings ~= cast(shared(Mapping)) Mapping(LevelRange.of(minLevel.value, maxLevel.value), handler);
    }

    public void addMinLevelMapping(Level minLevel, shared(LogHandler) handler) {
        this.mappings ~= cast(shared(Mapping)) Mapping(LevelRange.ofMin(minLevel.value), handler);
    }

    public void addMaxLevelMapping(Level maxLevel, shared(LogHandler) handler) {
        this.mappings ~= cast(shared(Mapping)) Mapping(LevelRange.ofMax(maxLevel.value), handler);
    }

    public void addAnyLevelMapping(shared(LogHandler) handler) {
        this.mappings ~= cast(shared(Mapping)) Mapping(LevelRange.infinite, handler);
    }

    public void handle(immutable LogMessage msg) shared {
        foreach (mapping; mappings) {
            if (
                (!mapping.range.hasMinValue || msg.level.value >= mapping.range.minValue) &&
                (!mapping.range.hasMaxValue || msg.level.value <= mapping.range.maxValue)
            ) {
                mapping.handler.handle(msg);
            }
        }
    }
}

unittest {
    import slf4d.logger : Logger;
    CachingLogHandler baseHandler = new CachingLogHandler();
    
    // Test single-level mappings.
    auto handler = new LevelMappedLogHandler();
    handler.addLevelMapping(Levels.INFO, baseHandler);

    Logger logger = Logger(handler);
    logger.debug_("This should not be logged.");
    assert(baseHandler.empty);
    logger.warn("This should also not be logged.");
    assert(baseHandler.empty);
    logger.trace("Also not logged.");
    assert(baseHandler.empty);
    logger.info("This should be logged!");
    assert(baseHandler.messageCount == 1);
    baseHandler.reset();
    
    // Test range mappings.
    handler = new LevelMappedLogHandler();
    handler.addRangeLevelMapping(Levels.DEBUG, Levels.WARN, baseHandler);

    Logger logger2 = Logger(handler);
    logger2.trace("This should not be logged.");
    assert(baseHandler.empty);
    logger2.error("This should also not be logged.");
    assert(baseHandler.empty);
    logger2.warn("This should be logged.");
    logger2.info("Also this!");
    logger2.debug_("And this!");
    assert(baseHandler.messageCount == 3);
    baseHandler.reset();

    // Test min mappings.
    handler = new LevelMappedLogHandler();
    handler.addMinLevelMapping(Levels.INFO, baseHandler);

    Logger logger3 = Logger(handler);
    logger3.debug_("This should not be logged.");
    assert(baseHandler.empty);
    logger3.info("This should be logged.");
    logger3.error("This too!");
    assert(baseHandler.messageCount == 2);
    baseHandler.reset();

    // Test max mappings.
    handler = new LevelMappedLogHandler();
    handler.addMaxLevelMapping(Levels.WARN, baseHandler);
    
    Logger logger4 = Logger(handler);
    logger4.error("This should not be logged.");
    assert(baseHandler.empty);
    logger4.warn("This should be logged.");
    logger4.trace("This too!");
    assert(baseHandler.messageCount == 2);
}
