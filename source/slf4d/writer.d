/**
 * This module defines the `SerializingLogHandler`, `LogWriter` interface, and
 * associated components for writing serialized log messages to external
 * systems.
 */
module slf4d.writer;

import slf4d;

/**
 * A component that serializes a log message into a string representation.
 * Note that a serializer may be called from many threads at once; you should
 * ensure it is thread-safe, or synchronize as needed.
 */
interface LogSerializer {
    string serialize(immutable LogMessage msg);
}

/**
 * A log serializer that formats messages in the same way that SLF4D's default
 * provider does, which is <module> <level> <timestamp> <message>, roughly.
 */
class DefaultStringLogSerializer : LogSerializer {
    private immutable bool terminalColors;

    public this(bool terminalColors = false) {
        this.terminalColors = terminalColors;
    }

    string serialize(immutable LogMessage msg) {
        import slf4d.default_provider.formatters : formatLogMessage;
        return formatLogMessage(msg, this.terminalColors);
    }
}

/**
 * A log serializer that formats messages in a JSON string, containing all data
 * in the original log message struct.
 */
class JsonLogSerializer : LogSerializer {
    string serialize(immutable LogMessage msg) {
        import std.json;
        import slf4d.default_provider.formatters;
        JSONValue obj = JSONValue(string[string].init);
        obj.object["level"] = JSONValue(string[string].init);
        obj.object["level"].object["value"] = JSONValue(msg.level.value);
        obj.object["level"].object["name"] = JSONValue(msg.level.name);
        obj.object["message"] = JSONValue(msg.message);
        obj.object["timestamp"] = JSONValue(formatTimestamp(msg.timestamp, false));
        obj.object["loggerName"] = JSONValue(msg.loggerName);
        if (msg.exception.isNull) {
            obj.object["exception"] = JSONValue(null);
        } else {
            import slf4d.logger : ExceptionInfo;
            ExceptionInfo info = msg.exception.get();
            obj.object["exception"] = JSONValue(string[string].init);
            obj.object["exception"].object["message"] = JSONValue(info.message);
            obj.object["exception"].object["sourceFileName"] = JSONValue(info.sourceFileName);
            obj.object["exception"].object["sourceLineNumber"] = JSONValue(info.sourceLineNumber);
            obj.object["exception"].object["exceptionClassName"] = JSONValue(info.exceptionClassName);
            if (info.stackTrace.isNull()) {
                obj.object["exception"].object["stackTrace"] = JSONValue(null);
            } else {
                obj.object["exception"].object["stackTrace"] = JSONValue(info.stackTrace.get());
            }
        }
        obj.object["sourceContext"] = JSONValue(string[string].init);
        obj.object["sourceContext"].object["moduleName"] = JSONValue(msg.sourceContext.moduleName);
        obj.object["sourceContext"].object["functionName"] = JSONValue(msg.sourceContext.functionName);
        obj.object["sourceContext"].object["fileName"] = JSONValue(msg.sourceContext.fileName);
        obj.object["sourceContext"].object["lineNumber"] = JSONValue(msg.sourceContext.lineNumber);
        return obj.toString();
    }
}

/**
 * A log writer is a component that writes a serialized log message string to
 * some output resource, like a file or network device. Note that because this
 * write method may be called from many threads, it should be thread-safe, or
 * appropriately synchronized.
 */
interface LogWriter {
    void write(string message);
}

/**
 * A log writer that always writes to the same file.
 */
class SingleFileLogWriter : LogWriter {
    import std.stdio;
    private File file;

    public this(File file) {
        this.file = file;
    }

    void write(string message) {
        synchronized(this) {
            this.file.writeln(message);
            this.file.flush();
        }
    }
}

/**
 * A log writer that writes log messages to files in a directory, switching to
 * a new file when the current one reaches a set size (defaults to 2GB).
 */
class RotatingFileLogWriter : LogWriter {
    import std.stdio;
    import std.file;
    import std.path;
    import std.string;
    import std.algorithm;

    private File currentFile;
    private string logDir;
    private string logFilePrefix;
    private immutable ulong maxLogFileSize;

    /**
     * Constructs a new rotating log file strategy.
     * Params:
     *   logDir = The directory to store log files in. It will be created,
     *            recursively, if it doesn't exist.
     *   logFilePrefix = The prefix for all log files generated.
     *   maxLogFileSize = The maximum size, in bytes, of log files. Defaults to
     *                    2GB.
     */
    public this(string logDir, string logFilePrefix = "log", ulong maxLogFileSize = 2_000_000_000) {
        this.logDir = logDir;
        this.logFilePrefix = logFilePrefix;
        this.maxLogFileSize = maxLogFileSize;
        this.initFile();
    }

    void write(string message) {
        synchronized(this) {
            // Check if we need to close this file and open a new one.
            if (getSize(this.currentFile.name) > this.maxLogFileSize) {
                this.currentFile.close();
                this.currentFile = File(getNextFileName(), "a");
            }
            this.currentFile.writeln(message);
            this.currentFile.flush();
        }
    }

    /**
     * Generates a log file name.
     * Returns: A log file name.
     */
    private string getNextFileName() {
        import std.datetime;
        SysTime now = Clock.currTime();
        string filename = format!"%s_%04d-%02d-%02dT%02d-%02d-%02d.log"(
            this.logFilePrefix,
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
            now.second
        );
        return buildPath(this.logDir, filename);
    }

    /** 
     * Helper method for initially selecting the file that should be written to.
     */
    private void initFile() {
        // If the log dir doesn't exist yet, make it and start a new file.
        if (!exists(this.logDir)) {
            mkdirRecurse(this.logDir);
            this.currentFile = File(getNextFileName(), "a");
        } else {// Otherwise, search for the best file to continue from.
            DirEntry[] potentialFilesToContinue;
            foreach (DirEntry entry; dirEntries(this.logDir, SpanMode.shallow, false)) {
                if (
                    entry.size() < this.maxLogFileSize &&
                    startsWith(baseName(entry.name), this.logFilePrefix)
                ) {
                    potentialFilesToContinue ~= entry;
                }
            }
            sort!((e1, e2) => e1.timeLastModified > e2.timeLastModified)(potentialFilesToContinue);
            if (potentialFilesToContinue.length > 0) {
                this.currentFile = File(potentialFilesToContinue[0].name, "a");
            } else {
                this.currentFile = File(getNextFileName(), "a");
            }
        }
    }
}

/**
 * Writes logs to the standard output stream.
 */
class StdoutLogWriter : LogWriter {
    void write(string message) {
        import std.stdio : writeln;
        writeln(message);
    }
}

/**
 * A log handler that serializes incoming messages, and uses a `LogWriter` to
 * write them to some output resource, like a standard output stream, file, or
 * network device. Most SLF4D providers will probably end up using some sort of
 * serializing handler at the end of the day.
 */
class SerializingLogHandler : LogHandler {
    private shared LogSerializer serializer;
    private shared LogWriter writer;

    public shared this(LogSerializer serializer, LogWriter writer) {
        this.serializer = cast(shared(LogSerializer)) serializer;
        this.writer = cast(shared(LogWriter)) writer;
    }

    shared void handle(immutable LogMessage msg) {
        import std.stdio;
        try {
            // We need to cast away this serializer's `shared` attribute to call serialize.
            string rawMessage = (cast(LogSerializer) this.serializer).serialize(msg);
            try {
                (cast(LogWriter) this.writer).write(rawMessage);
            } catch (Exception e) {
                stderr.writefln!"Failed to write log message: %s"(e.msg);
            }
        } catch (Exception e) {
            stderr.writefln!"Failed to serialize log message: %s"(e.msg);
        }
    }
}

unittest {
    import std.file;
    if (exists("test-logs")) {
        rmdirRecurse("test-logs");
    }
    import slf4d;
    import slf4d.default_provider.factory;
    auto handler = new shared SerializingLogHandler(
        new DefaultStringLogSerializer(),
        new RotatingFileLogWriter("test-logs")
    );
    Logger logger = Logger(handler);
    logger.info("test");
    for (int i = 0; i < 1_000; i++) {
        logger.warn("This is a really long warning message that will clog up the files.");
    }
}
