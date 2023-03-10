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
    configureLoggingProvider(new shared CustomProvider());
    // Use this helper function to ensure that your provider was initialized.
    assertInitialized!CustomProvider();

    auto log = getLogger();
    log.info("Testing the custom provider.");
    log.warn("Here is a warning message.");
}