//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <agent_dart/agent_dart_plugin.h>
#include <agent_dart_auth/agent_dart_auth_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AgentDartPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AgentDartPlugin"));
  AgentDartAuthPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AgentDartAuthPlugin"));
}
