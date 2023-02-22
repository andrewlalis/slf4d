module custom_provider;

import slf4d;
import slf4d.provider;

class CustomProvider : LoggingProvider {
    shared shared(LoggerFactory) defineLoggerFactory() {
        return new shared DefaultLoggerFactory(
            new shared CustomLogHandler()
        );
    }
}

class CustomLogHandler : LogHandler {
    shared void handle(LogMessage msg) {
        import std.stdio;
        writeln(msg.level.name ~ ": " ~ msg.message);
    }
}

unittest {
    configureLoggingProvider(new shared CustomProvider());
    auto log = getLogger();
    log.info("Testing the custom provider.");
    log.warn("Here is a warning message.");
}