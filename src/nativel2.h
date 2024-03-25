#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

FFI_PLUGIN_EXPORT char* startDaemon(const char* jsonArgs);
FFI_PLUGIN_EXPORT char* stopDaemon();
FFI_PLUGIN_EXPORT char* daemonState();
FFI_PLUGIN_EXPORT char* daemonVersion();
FFI_PLUGIN_EXPORT char* sign(const char* jsonArgs);
