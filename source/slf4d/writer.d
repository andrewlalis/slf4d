/**
 * This module defines the `LogSerializer` and `LogWriter` interfaces, and
 * associated components for writing serialized log messages to external
 * systems.
 */
module slf4d.writer;

import slf4d.logger : LogMessage;

/**
 * A component that serializes a log message into a string representation.
 * Note that a serializer may be called from many threads at once; you should
 * ensure it is thread-safe, or synchronize as needed.
 */
interface LogSerializer {
    string serialize(immutable LogMessage msg) shared;
}

/**
 * A log writer is a component that writes a serialized log message string to
 * some output resource, like a file or network device. Note that because this
 * write method may be called from many threads, it must be thread-safe.
 */
interface LogWriter {
    /**
     * Writes a serialized log message to some output resource.
     * Params:
     *   msg = The original log message that was serialized, for reference.
     *   serializedMessage = The serialized representation of the log message.
     */
    void write(immutable LogMessage msg, string serializedMessage) shared;
}
