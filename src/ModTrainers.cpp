#include "Log.h"

void Addmod_trainersCommands();

void Addmod_trainersScripts()
{
    LOG_INFO("server.loading", "mod_trainers: Loading scripts.");
    Addmod_trainersCommands();
}
