/**
 * An SLF4D logging provider that simply discards all log messages. This can be
 * used during testing, if you'd like to suppress expected log messages.
 */
module slf4d.noop_provider;

import slf4d;
import slf4d.provider;

/** 
 * A custom logging level that's beyond any other level, to short-circuit
 * logger logic right away and have it discard log messages.
 */
const Level NO_OP_LEVEL = Level(1_000_000, "NO-OP");

/** 
 * The no-op provider class. This provider defines a logger factory that
 * produces Loggers whose handler discards any log messages sent to them.
 */
class NoOpProvider : LoggingProvider {
    private shared NoOpLoggerFactory factory = new shared NoOpLoggerFactory();

    shared shared(LoggerFactory) getLoggerFactory() {
        return factory;
    }
}

package class NoOpLoggerFactory : LoggerFactory {
    shared Logger getLogger(string name = __MODULE__) {
        return Logger(new DiscardingLogHandler(), NO_OP_LEVEL, name);
    }
}

unittest {
    auto factory = new shared NoOpProvider().getLoggerFactory();
    auto log = factory.getLogger();
    log.info("This is discarded.");
    log.error("This is also discarded.");
}