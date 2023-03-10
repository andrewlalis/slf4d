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
Logger logger = getLogger();
Logger namedLogger = getLogger("custom-name");
```

> Note: Unless you want a logger with a custom name, it's easier to just use the [logging functions](./using-slf4d.md#logging-functions) without specifying a Logger.

## Logging Functions

SLF4D defines the following 3 types of logging functions:
1. **Basic message logs** - Write a log message string, at a specified log level. You can optionally include an Exception.
2. **Exception logs** - Write a log message at a specified log level, from an Exception that was thrown.
3. **Formatted logs** - Write a formatted log message at a specified log level, using a series of format arguments. This ultimately gets formatted by `std.format : format`.

These are illustrated below:

```d
// 1.
log(Levels.DEBUG, "This is a basic log message.");
log(Levels.TRACE, "Another basic message", new Exception("With exception"));
// 2.
log(Levels.ERROR, new Exception("An exception log message."));
// 3.
logF!"This is a formatted log message: %d"(Levels.INFO, 42);
```

Because SLF4D defines a set of [standard logging levels](ddoc-slf4d.level.Levels), it also includes a variant of each of the above functions, for each logging level. The snippet below shows some of these functions, but for a complete list, check the [slf4d.log_functions](ddoc-slf4d.log_functions) module.

```d
info("This is an info message.");
traceF!"Calling function with args: %s"(args);
debug_("This is a debug message.");
try {
    doSomethingRisky();
} catch (Exception e) {
    error(e);
}
```

> Note: Because `debug` is a D language keyword, instead of writing `debug("msg");`, you should write `log.debug_("msg");`.
