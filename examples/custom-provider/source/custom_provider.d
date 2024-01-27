module custom_provider;

import slf4d;
import slf4d.provider;
import slf4d.default_provider : DefaultLoggerFactory;

class CustomProvider : LoggingProvider {
    LoggerFactory getLoggerFactory() {
        return new DefaultLoggerFactory(
            new CustomLogHandler()
        );
    }
}

class CustomLogHandler : LogHandler {
    void handle(immutable LogMessage msg) {
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