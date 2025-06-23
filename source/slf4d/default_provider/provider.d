/** 
 * Module which defines the default provider's main class.
 */
module slf4d.default_provider.provider;

import slf4d.provider;
import slf4d.level;
import slf4d.handler;
import slf4d.default_provider.factory;
import slf4d.default_provider.serializers;
import slf4d.default_provider.writers;

/** 
 * The default provider class. It simply contains a shared logger factory
 * which is used to get loggers, using a single shared log handler to handle
 * any log messages.
 */
shared class DefaultProvider : LoggingProvider {
    private DefaultLoggerFactory loggerFactory;

    /** 
     * Constructs the default provider.
     * Params:
     *   handler = The log handler that will handle all log messages.
     *   rootLoggingLevel = The root logging level for all Loggers created by
     *     this provider's factory.
     */
    this(
        shared LogHandler handler,
        Level rootLoggingLevel = Levels.INFO
    ) {
        this.loggerFactory = new DefaultLoggerFactory(handler, rootLoggingLevel);
    }

    this(Level rootLoggingLevel = Levels.INFO) {
        auto handler = new SerializingLogHandler(
            new ConsoleTextLogSerializer(),
            [new StdoutLogWriter()]
        );
        this.loggerFactory = new DefaultLoggerFactory(handler, rootLoggingLevel);
    }
    
    /** 
     * Getter method to get this provider's internal factory.
     * Returns: The logger factory.
     */
    public DefaultLoggerFactory getLoggerFactory() shared {
        return this.loggerFactory;
    }

    /**
     * Gets a builder for creating a customized logging provider.
     * Returns: The builder.
     */
    static DefaultProviderBuilder builder() {
        return new DefaultProviderBuilder();
    }
}

/** 
 * A fluent-style builder for creating a customized logging provider from
 * various components offered by SLF4D's default provider module.
 */
private shared class DefaultProviderBuilder {
    import slf4d.writer;

    private LogWriter[] writers;
    private LogSerializer serializer;
    private Level rootLoggingLevel = Levels.INFO;

    /**
     * Configures the logging provider to use the given serializer to convert
     * log messages to strings for writing.
     */
    auto withSerializer(LogSerializer serializer) {
        this.serializer = cast(shared(LogSerializer)) serializer;
        return this;
    }

    /**
     * Configures the logging provider to send serialized log messages to the
     * given writer for output. Note that this can be called multiple times to
     * add multiple writers.
     * Params:
     *   writer = The writer to use.
     */
    auto withLogWriter(shared LogWriter writer) {
        this.writers ~= writer;
        return this;
    }

    /**
     * Configures the root logging level for the provider, which is the default
     * logging level assigned to all loggers created by this provider's factory
     * unless a module-specific logging level overrides it.
     * Params:
     *   level = The logging level to set.
     */
    auto withRootLoggingLevel(Level level) {
        this.rootLoggingLevel = level;
        return this;
    }

    /**
     * Builds the logging provider with the configured settings.
     * Returns: The logging provider.
     */
    DefaultProvider build() {
        if (this.serializer is null) {
            this.serializer = new shared ConsoleTextLogSerializer();
        }
        if (this.writers.length == 0) {
            this.writers ~= new StdoutLogWriter();
        }
        return new DefaultProvider(
            new SerializingLogHandler(this.serializer, this.writers),
            this.rootLoggingLevel
        );
    }
}

unittest {
    import slf4d.logger;
    DefaultProvider provider = DefaultProvider.builder()
        .withRootLoggingLevel(Levels.INFO)
        .build();
    auto factory = provider.getLoggerFactory();
    factory.setRootLevel(Levels.TRACE);
    Logger log = factory.getLogger();
    log.error("Testing default provider error message.");
    log.warn("Testing default provider warn message.");
    log.info("Testing default provider info message.");
    log.debug_("Testing default provider debug message.");
    log.trace("Testing default provider trace message.");
    log.traceF!"Testing default provider traceF message. %d"(42);
    log.info("ATTENTION! An exception and its stack trace will be shown. THIS IS EXPECTED.");

    try {
        throw new Exception("Oh no!");
    } catch (Exception e) {
        log.error(e);
    }

    log.info("Testing default provider with attributes.", null, [
        "attribute1": "value1",
        "attribute2": "value2",
        "attribute3": "value3",
        "attribute4": "This is a very long attribute value."
    ]);
}
