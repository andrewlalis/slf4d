# Using SLF4D

It's easy to write log messages with SLF4D. All you need to do is `import slf4d;`, and call the log message of your choice.

```d
import slf4d;

void doSomething() {
    try {
        info("Doing something risky...");
        throw new Exception("Yikes");
    } catch (Exception e) {
        error("Uh oh, an error occurred!", e);
    }
}
```

## Logging Levels

SLF4D defines a [Level](ddoc-slf4d.level.Level) struct with a `name` and an integer `value` that depicts its severity (with higher values being more severe). While you can create your own custom logging levels if you need, SLF4D provides a standard set of logging levels via the [Levels](ddoc-slf4d.level.Levels) enum.

| Level | Value | Meaning |
|---    |---    |---      |
| `Levels.TRACE` | 10 | The lowest severity log level defined by SLF4D, usually for fine-grained debugging of individual statements and control flow. |
| `Levels.DEBUG` | 20 | A low severity log level used for extra information that's only useful when debugging a program's behavior. |
| `Levels.INFO` | 30 | A medium severity log level used for reporting information during standard, nominal program operation. |
| `Levels.WARN` | 40 | A higher severity log level for reporting anomalous but non-fatal issues that arise at runtime. |
| `Levels.ERROR` | 50 | A severe log level for program errors that indicate a fatal bug that leads to program failure or inconsistent state. |

## The Logger

All log messages are generated using a [Logger](ddoc-slf4d.logger.Logger) struct. You can obtain a logger via the [getLogger()](ddoc-slf4d.getLogger) function. Each logger has a `name`, which defaults to the name of the D module from which `getLogger()` was called.

```d
Logger log = getLogger();
log.info("Log message");

Logger namedLog = getLogger("custom-name");
namedLog.info("Log message from named logger.");
```

### Base Logging Functions

Each logger provides the following base log functions:

```d
Logger logger = getLogger();

// Log a string message. Optionally provide an exception.
logger.log(Levels.INFO, "Message");
logger.log(Levels.WARN, "Something went wrong.", new Exception("Uh oh!"));

// Log an exception.
logger.log(Levels.ERROR, new Exception("Uh oh!"));

// Log a formatted string.
logger.logF!"This is a formatted message: %d"(42);

// Build a log message using a fluent builder.
logger.builder()
    .msg("Message")
    .lvl(Levels.WARN)
    .exc(new Exception("Oh no!"))
    .log();
```

### Standard Level Logging Functions

It would get tedious to have to write out each log message's level each time you wanted to log something. That's why the Logger comes with a set of pre-generated functions for logging at each of the 5 [standard logging levels](./using-slf4d.md#logging-levels).

```d
Logger logger = getLogger();

logger.log(Levels.INFO, "Message"); // This...
logger.info("Message"); // is the same as this!

// Formatted messages work too.
logger.infoF!"Message %d"(42);

// So do builders.
logger.warnBuilder().msg("Uh oh.").log();
```

> Note: Because `debug` is a D language keyword, instead of writing `log.debug("msg");`, you should write `log.debug_("msg");`.

These functions are also defined in the scope of the `slf4d` package, as a shortcut so you don't always have to call `getLogger()` to start logging.

```d
import slf4d;

void doStuff() {
    // You can do this:
    Logger logger = getLogger();
    logger.info("Testing");

    // Or this for short.
    info("Testing");
}
```
