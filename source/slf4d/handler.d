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
 *
 * Note that the handler is `shared`. One handler instance exists and is used
 * by all application threads.
 */
shared interface LogHandler {
    /** 
     * Handles a log message.
     * Params:
     *   msg = The log message that was generated.
     */
    shared void handle(LogMessage msg);
}

/** 
 * A log handler that discards all messages. Useful for testing.
 */
class DiscardingLogHandler : LogHandler {
    public shared void handle(LogMessage msg) {
        // Do nothing.
    }
}

/** 
 * A log handler that simply appends all messages it receives to an internal
 * array. This can be useful for testing.
 */
synchronized class CachingLogHandler : LogHandler {
    private shared LogMessage[] messages;

    public shared void handle(LogMessage msg) {
        this.messages ~= msg;
    }

    public shared void reset() {
        this.messages = [];
    }

    public shared LogMessage[] getMessages() {
        return cast(LogMessage[]) messages.idup;
    }

    public shared size_t messageCount() {
        return messages.length;
    }

    public shared bool empty() {
        return messages.length == 0;
    }
}

unittest {
    import slf4d.logger : Logger;
    auto handler = new shared CachingLogHandler();
    auto logger = Logger(handler);
    assert(handler.getMessages().length == 0);
    logger.info("Hello world!");
    assert(handler.getMessages().length == 1);
}

/** 
 * A log handler that simply passes any log message it receives to a list of
 * other handlers. Note that handlers should only be added at application
 * startup, because the `handle` method is not synchronized to improve
 * performance.
 */
class MultiLogHandler : LogHandler {
    private shared LogHandler[] handlers;

    public shared this(shared LogHandler[] handlers) {
        this.handlers = handlers;
    }

    public shared shared(MultiLogHandler) addHandler(shared LogHandler handler) {
        this.handlers ~= handler;
        return this;
    }

    public shared void handle(LogMessage msg) {
        foreach (handler; handlers) {
            handler.handle(msg);
        }
    }
}

unittest {
    import slf4d.logger : Logger;
    auto h1 = new shared CachingLogHandler();
    auto h2 = new shared CachingLogHandler();
    auto multiHandler = new shared MultiLogHandler([h1, h2]);
    auto logger = Logger(multiHandler);
    logger.info("Hello world!");
    assert(h1.getMessages().length == 1);
    assert(h2.getMessages().length == 1);
}

/** 
 * A handler that applies a filter to log messages, and only passes messages to
 * its internal handler if the filter returns `true`.
 */
class FilterLogHandler : LogHandler {
    private bool function (LogMessage) filterFunction;
    private shared LogHandler handler;

    public shared this(shared LogHandler handler, bool function (LogMessage) filterFunction) {
        this.handler = handler;
        this.filterFunction = filterFunction;
    }

    shared void handle(LogMessage msg) {
        if (this.filterFunction(msg)) {
            this.handler.handle(msg);
        }
    }
}

unittest {
    import slf4d.logger : Logger;
    auto baseHandler = new shared CachingLogHandler();
    auto filterHandler = new shared FilterLogHandler(
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
class LevelMappedLogHandler : LogHandler {

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
        public shared LogHandler handler;
    }

    private Mapping[] mappings;

    public shared void addLevelMapping(Level level, shared LogHandler handler) {
        this.mappings ~= Mapping(LevelRange.of(level.value), handler);
    }

    public shared void addRangeLevelMapping(Level minLevel, Level maxLevel, shared LogHandler handler) {
        if (minLevel.value > maxLevel.value) {
            Level tmp = minLevel;
            minLevel = maxLevel;
            maxLevel = tmp;
        }
        this.mappings ~= Mapping(LevelRange.of(minLevel.value, maxLevel.value), handler);
    }

    public shared void addMinLevelMapping(Level minLevel, shared LogHandler handler) {
        this.mappings ~= Mapping(LevelRange.ofMin(minLevel.value), handler);
    }

    public shared void addMaxLevelMapping(Level maxLevel, shared LogHandler handler) {
        this.mappings ~= Mapping(LevelRange.ofMax(maxLevel.value), handler);
    }

    public shared void addAnyLevelMapping(shared LogHandler handler) {
        this.mappings ~= Mapping(LevelRange.infinite, handler);
    }

    public shared void handle(LogMessage msg) {
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
    auto baseHandler = new shared CachingLogHandler();
    
    // Test single-level mappings.
    auto handler = new shared LevelMappedLogHandler();
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
    handler = new shared LevelMappedLogHandler();
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
    handler = new shared LevelMappedLogHandler();
    handler.addMinLevelMapping(Levels.INFO, baseHandler);

    Logger logger3 = Logger(handler);
    logger3.debug_("This should not be logged.");
    assert(baseHandler.empty);
    logger3.info("This should be logged.");
    logger3.error("This too!");
    assert(baseHandler.messageCount == 2);
    baseHandler.reset();

    // Test max mappings.
    handler = new shared LevelMappedLogHandler();
    handler.addMaxLevelMapping(Levels.WARN, baseHandler);
    
    Logger logger4 = Logger(handler);
    logger4.error("This should not be logged.");
    assert(baseHandler.empty);
    logger4.warn("This should be logged.");
    logger4.trace("This too!");
    assert(baseHandler.messageCount == 2);
}