/**
 * Defines several common default log writers.
 */
module slf4d.default_provider.writers;

import slf4d;
import slf4d.writer;

/**
 * Writes logs to the standard output stream. If the log message's severity is
 * ERROR or higher, it's written to stderr, otherwise to stdout.
 */
class StdoutLogWriter : LogWriter {
    void write(immutable LogMessage msg, string serializedMessage) shared {
        import std.stdio : writeln, stdout, stderr;
        if (msg.level.value >= Levels.ERROR.value) {
            stderr.writeln(serializedMessage);
            stderr.flush();
        } else {
            stdout.writeln(serializedMessage);
            stdout.flush();
        }
    }
}

/**
 * A log writer that always writes to the same file.
 */
shared class SingleFileLogWriter : LogWriter {
    import std.stdio;
    private File file;

    public this(File file) {
        this.file = cast(shared(File)) file;
    }

    void write(immutable LogMessage _, string serializedMessage) {
        synchronized(this) {
            auto unsharedFile = cast(File*) &this.file;
            unsharedFile.writeln(serializedMessage);
            unsharedFile.flush();
        }
    }
}

/**
 * A log writer that writes log messages to files in a directory, switching to
 * a new file when the current one reaches a set size (defaults to 2GB).
 */
shared class RotatingFileLogWriter : LogWriter {
    import std.stdio;
    import std.file;
    import std.path;
    import std.string;
    import std.algorithm;
    import slf4d.default_provider.serializers;

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

    void write(immutable LogMessage _, string serializedMessage) {
        synchronized(this) {
            auto unsharedFile = cast(File*) &this.currentFile;
            // Check if we need to close this file and open a new one.
            if (getSize(unsharedFile.name) > this.maxLogFileSize) {
                unsharedFile.close();
                *unsharedFile = File(getNextFileName(), "a");
            }
            unsharedFile.writeln(serializedMessage);
            unsharedFile.flush();
        }
    }

    /**
     * Generates a log file name.
     * Returns: A log file name.
     */
    private string getNextFileName() {
        import std.datetime;
        SysTime now = Clock.currTime();
        string filename = this.logFilePrefix ~ "_" ~ formatTimestampISO8601(now) ~ ".log";
        return buildPath(this.logDir, filename);
    }

    /** 
     * Helper method for initially selecting the file that should be written to.
     */
    private void initFile() {
        auto unsharedFile = cast(File*) &this.currentFile;
        // If the log dir doesn't exist yet, make it and start a new file.
        if (!exists(this.logDir)) {
            mkdirRecurse(this.logDir);
            *unsharedFile = File(getNextFileName(), "a");
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
                *unsharedFile = File(potentialFilesToContinue[0].name, "a");
            } else {
                *unsharedFile = File(getNextFileName(), "a");
            }
        }
    }
}
