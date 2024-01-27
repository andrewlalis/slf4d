# Configuring SLF4D

In SLF4D, all log messages generated throughout your application are handled by a [LoggingProvider](ddoc-slf4d.provider.LoggingProvider). The LoggingProvider is responsible for providing a [LoggerFactory](ddoc-slf4d.factory.LoggerFactory) that creates the [Logger](ddoc-slf4d.logger.Logger) components you use when you call a log function.

By default, SLF4D is initialized with its own built-in [DefaultProvider](ddoc-slf4d.default_provider.provider.DefaultProvider) that forwards all log messages to stdout or stderr. However, you can configure a different provider by calling [configureLoggingProvider](ddoc-slf4d.configureLoggingProvider) and passing in the provider you want to use.

Here's an example where we configure SLF4D to use the DefaultProvider, but we turn off console colors and set the root logging level to TRACE:

```d
import slf4d;
import slf4d.default_provider;

void main() {
    auto provider = new DefaultProvider(false, Levels.TRACE);
    configureLoggingProvider(provider);

    info("Application started!");
}
```

> ⚠️ **`configureLoggingProvider` should only be called once on application startup!** Calling this function at any other point in your program can lead to undefined behavior. Library developers should _never_ call this function, besides in unit tests.
