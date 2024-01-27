# The Default Provider

While SLF4D is designed in a decoupled way so you can plug in any logging provider you want, most often it'll just be convenient to use SLF4D's [Default Provider](ddoc-slf4d.default_provider). This logging provider is usually *good enough* for most simple use cases.

## Usage

```d
module my_app;

import slf4d;
import slf4d.default_provider;

void main() {
    auto provider = new DefaultProvider(
        true,         // Enable colored output using ANSI color codes.
        Levels.DEBUG, // Only log messages that are DEBUG or higher (so no TRACE).
        "log-files"   // Also write log messages to files in the "log-files" dir.
    );
    // Only show errors from loggers whose name matches "^std" regex.
    provider.getLoggerFactory().setModuleLevel("^std", Levels.ERROR);
    // Only show warnings or higher from loggers whose name starts with "requests".
    provider.getLoggerFactory().setModuleLevelPrefix("requests", Levels.WARN);
    configureLoggingProvider(provider); // Tell SLF4D to use our provider.

    info("Starting my app!");
    // Do some stuff here...
}
```
