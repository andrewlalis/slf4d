module other;

import app : loggerFactory;

void doStuff() {
    auto log = loggerFactory.getLogger();
    log.infoBuilder().msg("Hello").log();
}