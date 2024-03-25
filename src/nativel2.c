#include "nativel2.h"
#include "../gol2/build/gol2.h"

FFI_PLUGIN_EXPORT char* startDaemon(const char* jsonArgs) {
  GoString input;
  char* output;

  input.p = jsonArgs;
  input.n = strlen(jsonArgs);

  output = StartDaemon(input);
  return output;
}

FFI_PLUGIN_EXPORT char* stopDaemon() {
  char* output;

  output = StopDaemon();
  return output;
}

FFI_PLUGIN_EXPORT char* daemonState() {
  char* output;

  output = DaemonState();
  return output;
}

FFI_PLUGIN_EXPORT char* daemonVersion() {
  char* output;

  output = DaemonVersion();
  return output;
}

FFI_PLUGIN_EXPORT char* sign(const char* jsonArgs) {
  GoString input;
  char* output;

  input.p = jsonArgs;
  input.n = strlen(jsonArgs);

  output = Sign(input);
  return output;
}
