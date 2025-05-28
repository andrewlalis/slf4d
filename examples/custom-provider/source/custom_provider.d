module custom_provider;

import slf4d;
import slf4d.provider;
import slf4d.default_provider : DefaultLoggerFactory;

shared class CustomProvider : LoggingProvider {
    shared(LoggerFactory) getLoggerFactory() shared {
        return new DefaultLoggerFactory(
            new CustomLogHandler()
        );
    }
}

shared class CustomLogHandler : LogHandler {
    void handle(immutable LogMessage msg) shared {
        import std.stdio;
        writeln(msg.level.name ~ ": " ~ msg.message);
    }
}

unittest {
    import slf4d.test;
    withTestingLock(() {
        configureLoggingProvider(new CustomProvider());
        auto log = getLogger();
        log.info("Testing the custom provider.");
        log.warn("Here is a warning message.");
    });
}