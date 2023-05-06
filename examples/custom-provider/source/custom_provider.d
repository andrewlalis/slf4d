module custom_provider;

import slf4d;
import slf4d.provider;
import slf4d.default_provider : DefaultLoggerFactory;

class CustomProvider : LoggingProvider {
    shared shared(LoggerFactory) getLoggerFactory() {
        return new shared DefaultLoggerFactory(
            new shared CustomLogHandler()
        );
    }
}

class CustomLogHandler : LogHandler {
    shared void handle(immutable LogMessage msg) {
        import std.stdio;
        writeln(msg.level.name ~ ": " ~ msg.message);
    }
}

unittest {
    import slf4d.test;
    acquireLoggingTestingLock();

    configureLoggingProvider(new shared CustomProvider());
    auto log = getLogger();
    log.info("Testing the custom provider.");
    log.warn("Here is a warning message.");

    releaseLoggingTestingLock();
}