/**
 * An SLF4D logging provider that simply discards all log messages. This can be
 * used during testing, if you'd like to suppress expected log messages.
 */
module slf4d.noop_provider;

import slf4d;
import slf4d.provider;

/** 
 * The no-op provider class.
 */
class NoOpProvider : LoggingProvider {
    shared shared(LoggerFactory) defineLoggerFactory() {
        return new shared SimpleLoggerFactory(
            new DiscardingLogHandler(),
            Levels.TRACE
        );
    }
}

unittest {
    auto factory = new shared NoOpProvider().defineLoggerFactory();
    auto log = factory.getLogger();
    log.info("This is discarded.");
    log.error("This is also discarded.");
}